module "eks_infrastructure" {
  source = "./terraform/eks"

  aws_region      = var.aws_region
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  environment     = var.environment
  
  enable_cluster_autoscaler = true
  enable_metrics_server     = true
  enable_ebs_csi            = true
  enable_efs_csi            = true

  tags = var.tags
}

module "jenkins_deployment" {
  source = "./terraform/jenkins"

  cluster_name = module.eks_infrastructure.cluster_name

  jenkins_admin_user     = var.jenkins_admin_user
  jenkins_admin_password = var.jenkins_admin_password
  
  jenkins_replica_count = 2
  jenkins_cpu_request   = "500m"
  jenkins_cpu_limit     = "2000m"
  jenkins_memory_request = "1Gi"
  jenkins_memory_limit   = "4Gi"
  jenkins_storage_size   = "100Gi"
  
  jenkins_agent_replicas = 3
  
  enable_jenkins_ingress = false
  enable_jenkins_backup  = true

  tags = var.tags
}
