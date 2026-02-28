variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "jenkins_namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "jenkins_admin_user" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "jenkins_admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
}

variable "jenkins_replica_count" {
  description = "Number of Jenkins controller replicas"
  type        = number
  default     = 2
}

variable "jenkins_cpu_request" {
  description = "Jenkins CPU request"
  type        = string
  default     = "500m"
}

variable "jenkins_cpu_limit" {
  description = "Jenkins CPU limit"
  type        = string
  default     = "2000m"
}

variable "jenkins_memory_request" {
  description = "Jenkins memory request"
  type        = string
  default     = "1Gi"
}

variable "jenkins_memory_limit" {
  description = "Jenkins memory limit"
  type        = string
  default     = "4Gi"
}

variable "jenkins_storage_class" {
  description = "Storage class for Jenkins persistent volume"
  type        = string
  default     = "ebs"
}

variable "jenkins_storage_size" {
  description = "Size of Jenkins persistent volume"
  type        = string
  default     = "100Gi"
}

variable "jenkins_jvm_opts" {
  description = "JVM options for Jenkins"
  type        = string
  default     = "-XX:+UseG1GC -XX:MaxGCPauseMillis=33 -XX:InitiatingHeapOccupancyPercent=35"
}

variable "jenkins_num_executors" {
  description = "Number of Jenkins executors on controller"
  type        = number
  default     = 0
}

variable "enable_jenkins_ingress" {
  description = "Enable ingress for Jenkins"
  type        = bool
  default     = true
}

variable "jenkins_ingress_hostname" {
  description = "Hostname for Jenkins ingress"
  type        = string
  default     = ""
}

variable "enable_jenkins_backup" {
  description = "Enable automated Jenkins backup"
  type        = bool
  default     = true
}

variable "jenkins_agent_replicas" {
  description = "Number of Jenkins agent replicas"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default = {
    Application = "Jenkins"
  }
}
