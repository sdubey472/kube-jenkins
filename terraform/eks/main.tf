terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure if using remote state
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "jenkins-eks/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs              = data.aws_availability_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = false
  one_nat_gateway_per_az = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Kubernetes tags for subnet discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  tags = var.tags
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.private_subnets, module.vpc.public_subnets)

  # Enable IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Cluster security group configuration
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_security_group_id   = aws_security_group.node_security_group.id
    }
  }

  # Node security group configuration
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # Managed node groups
  eks_managed_node_groups = {
    jenkins_controller = {
      name            = "jenkins-controller"
      description     = "Jenkins controller node group"
      use_name_prefix = true
      
      instance_types       = ["t3.xlarge"]
      capacity_type        = "ON_DEMAND"
      disk_size            = 100
      
      min_size     = 2
      max_size     = 4
      desired_size = 2

      taints = [
        {
          key    = "jenkins-controller"
          value  = "true"
          effect = "NoSchedule"
        }
      ]

      labels = {
        Environment = var.environment
        NodeGroup   = "jenkins-controller"
      }

      update_config = {
        max_unavailable_percentage = 50
      }

      # Enable IMDSv2
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
      }

      tags = {
        NodeGroup = "jenkins-controller"
      }
    }

    jenkins_agents = {
      name            = "jenkins-agents"
      description     = "Jenkins agent node group for workloads"
      use_name_prefix = true

      instance_types = ["m5.xlarge", "m5.2xlarge"]
      capacity_type  = "SPOT"
      disk_size      = 100

      min_size     = 1
      max_size     = 20
      desired_size = 3

      labels = {
        Environment = var.environment
        NodeGroup   = "jenkins-agents"
      }

      update_config = {
        max_unavailable_percentage = 50
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
      }

      tags = {
        NodeGroup = "jenkins-agents"
      }
    }
  }

  # Enable cluster logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = var.tags
}

# Node security group (referenced in cluster config)
resource "aws_security_group" "node_security_group" {
  name_prefix = "${var.cluster_name}-node-"
  description = "Security group for EKS nodes"
  vpc_id      = module.vpc.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-node-sg"
    }
  )
}

# Outputs
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}
