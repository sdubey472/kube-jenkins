terraform {
  required_version = ">= 1.0"
  
  required_providers {
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

# Create namespace for Jenkins
resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.jenkins_namespace
    labels = {
      name = var.jenkins_namespace
    }
  }
}

# Create service account for Jenkins
resource "kubernetes_service_account" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
}

# Create cluster role for Jenkins
resource "kubernetes_cluster_role" "jenkins" {
  metadata {
    name = "jenkins"
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/exec"]
    verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/log"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get", "list", "watch"]
  }
}

# Create cluster role binding for Jenkins
resource "kubernetes_cluster_role_binding" "jenkins" {
  metadata {
    name = "jenkins"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.jenkins.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.jenkins.metadata[0].name
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
}

# Create storage class for Jenkins
resource "kubernetes_storage_class" "jenkins_ebs" {
  metadata {
    name = "jenkins-ebs"
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true

  parameters = {
    type            = "gp3"
    iops            = "3000"
    throughput      = "125"
    deleteOnTermination = "true"
  }

  volume_binding_mode = "WaitForFirstConsumer"
}

# Install Jenkins using Helm
resource "helm_release" "jenkins" {
  name             = "jenkins"
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  namespace        = kubernetes_namespace.jenkins.metadata[0].name
  version          = "5.3.2" # Update to latest stable version as needed
  create_namespace = false

  values = [
    yamlencode({
      jenkins = {
        controller = {
          serviceAccount = {
            name = kubernetes_service_account.jenkins.metadata[0].name
          }

          admin = {
            username = var.jenkins_admin_user
            password = var.jenkins_admin_password
          }

          replicas = var.jenkins_replica_count

          # Jenkins configuration
          installPlugins = [
            "kubernetes:latest",
            "workflow-job:latest",
            "workflow-aggregator:latest",
            "pipeline-model-definition:latest",
            "git:latest",
            "github:latest",
            "docker-plugin:latest",
            "docker-workflow:latest",
            "aws-codecommit-trigger:latest",
            "aws-codecommit-credential-provider:latest",
            "log-parser:latest",
            "junit:latest",
            "metrics:latest",
            "performance:latest",
            "timestamper:latest",
            "ansicolor:latest"
          ]

          # JVM options for better performance
          JCasC = {
            enabled = true
            configScripts = {
              basic : file("${path.module}/casc.yaml")
            }
          }

          # Resource requests and limits
          resources = {
            requests = {
              cpu    = var.jenkins_cpu_request
              memory = var.jenkins_memory_request
            }
            limits = {
              cpu    = var.jenkins_cpu_limit
              memory = var.jenkins_memory_limit
            }
          }

          # Affinity rules for high availability
          affinity = {
            podAntiAffinity = {
              preferredDuringSchedulingIgnoredDuringExecution = [
                {
                  weight = 100
                  podAffinityTerm = {
                    labelSelector = {
                      matchExpressions = [
                        {
                          key      = "app.kubernetes.io/name"
                          operator = "In"
                          values   = ["jenkins"]
                        }
                      ]
                    }
                    topologyKey = "kubernetes.io/hostname"
                  }
                }
              ]
            }
            nodeAffinity = {
              requiredDuringSchedulingIgnoredDuringExecution = {
                nodeSelectorTerms = [
                  {
                    matchExpressions = [
                      {
                        key      = "NodeGroup"
                        operator = "In"
                        values   = ["jenkins-controller"]
                      }
                    ]
                  }
                ]
              }
            }
          }

          # Tolerations for controller node taint
          tolerations = [
            {
              key      = "jenkins-controller"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
          ]

          # Health probes
          healthProbes = true

          # LivenessProbe
          livenessProbe = {
            httpGet = {
              path = "/login"
              port = 8080
            }
            initialDelaySeconds = 300
            periodSeconds       = 10
            timeoutSeconds      = 5
            failureThreshold    = 5
          }

          # ReadinessProbe
          readinessProbe = {
            httpGet = {
              path = "/login"
              port = 8080
            }
            initialDelaySeconds = 60
            periodSeconds       = 10
            timeoutSeconds      = 5
            failureThreshold    = 3
          }

          # Persistence
          persistence = {
            enabled      = true
            size         = var.jenkins_storage_size
            storageClass = kubernetes_storage_class.jenkins_ebs.metadata[0].name
            labels = {
              "app.kubernetes.io/name"       = "jenkins"
              "app.kubernetes.io/component" = "jenkins-controller"
            }
            selector = {
              "app.kubernetes.io/name"       = "jenkins"
              "app.kubernetes.io/component" = "jenkins-controller"
            }
          }

          # Security context
          securityContext = {
            runAsUser    = 1000
            runAsGroup   = 1000
            fsGroup      = 1000
            runAsNonRoot = true
          }

          # Pod security context
          podSecurityContext = {
            fsGroup = 1000
          }

          # Host aliases
          hostAliases = []

          # Service type
          serviceType = "LoadBalancer"

          # Service annotations
          serviceAnnotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
          }
        }

        agent = {
          enabled = true
          replicas = var.jenkins_agent_replicas

          resources = {
            requests = {
              cpu    = "100m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "2Gi"
            }
          }

          # Node affinity for agents
          affinity = {
            nodeAffinity = {
              preferredDuringSchedulingIgnoredDuringExecution = [
                {
                  weight = 100
                  preference = {
                    matchExpressions = [
                      {
                        key      = "NodeGroup"
                        operator = "In"
                        values   = ["jenkins-agents"]
                      }
                    ]
                  }
                }
              ]
            }
          }

          # Pod anti-affinity for high availability
          podAntiAffinity = "preferred"
        }
      }

      # Controller service settings
      controller = {
        podAnnotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path"   = "/prometheus/"
          "prometheus.io/port"   = "8080"
        }
      }

      # Rbac configuration
      rbac = {
        create = true
      }

      # Service account configuration
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.jenkins.metadata[0].name
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.jenkins,
    kubernetes_service_account.jenkins,
    kubernetes_cluster_role.jenkins,
    kubernetes_cluster_role_binding.jenkins,
    kubernetes_storage_class.jenkins_ebs
  ]
}

# Output Jenkins service endpoint
output "jenkins_service" {
  description = "Jenkins service information"
  value = {
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    service   = "jenkins"
  }
}
