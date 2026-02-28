terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

# Root module outputs
output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_security_group_id" {
  description = "EKS node security group ID"
  value       = module.eks.node_security_group_id
}

output "jenkins_namespace" {
  description = "Kubernetes namespace for Jenkins"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

output "jenkins_service_type" {
  description = "Jenkins service type"
  value       = "LoadBalancer"
}

output "how_to_access_jenkins" {
  description = "Instructions to access Jenkins"
  value = <<-EOT
    1. Get the Jenkins service LoadBalancer endpoint:
       kubectl get svc -n jenkins jenkins -w
    
    2. Once the LoadBalancer IP/hostname appears:
       Jenkins URL: http://<EXTERNAL-IP>:8080
    
    3. Get default admin password:
       kubectl exec -it jenkins-0 -n jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
    
    4. Or use the configured admin username/password from terraform variables
  EOT
}
