###  https://github.com/sdubey472/kube-jenkins

# Jenkins on EKS - Terraform Configuration

This repository contains a complete Terraform configuration for deploying Jenkins on AWS EKS with high scalability and resilience.

## Architecture Overview

### Components

1. **VPC**: 
   - Public subnets for NAT Gateways and load balancers
   - Private subnets for EKS nodes
   - Distributed across 3 availability zones

2. **EKS Cluster**:
   - Kubernetes 1.29 (configurable)
   - Control plane logging enabled
   - IRSA (IAM Roles for Service Accounts) enabled

3. **Node Groups**:
   - **Jenkins Controller**: On-Demand instances, taints configured, 2-4 nodes
   - **Jenkins Agents**: SPOT instances for cost optimization, 1-20 nodes

4. **Storage**:
   - EBS CSI Driver for persistent volumes
   - EFS CSI Driver for shared storage
   - Storage classes for Jenkins data persistence

5. **Jenkins Deployment**:
   - High availability with multiple replicas
   - Kubernetes Cloud plugin for agent orchestration
   - Resource limits and requests configured
   - Health probes and rolling updates
   - Service with LoadBalancer type

6. **Monitoring & Auto-scaling**:
   - Metrics Server for HPA
   - Cluster Autoscaler for node auto-scaling
   - Prometheus metrics scraping configured
   - CloudWatch logs integration

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- `kubectl` installed
- AWS Account with appropriate permissions

## Directory Structure

```
.
├── terraform/
│   ├── eks/              # EKS infrastructure
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── addons.tf
│   │   └── monitoring.tf
│   └── jenkins/          # Jenkins deployment
│       ├── main.tf
│       ├── variables.tf
│       └── casc.yaml     # Jenkins Configuration as Code
├── scripts/              # Helper scripts
│   ├── init.sh
│   ├── configure-kubectl.sh
│   ├── get-jenkins-access.sh
│   ├── monitor.sh
│   ├── backup-jenkins.sh
│   └── destroy.sh
├── main.tf              # Root module
├── variables.tf         # Root variables
├── terraform.tf         # Root terraform config
├── terraform.tfvars.example  # Example values
└── README.md
```

## Quick Start

### 1. Initialize Terraform

```bash
./scripts/init.sh
```

### 2. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Plan Deployment

```bash
terraform plan
```

### 4. Apply Configuration

```bash
terraform apply
```

### 5. Configure kubectl

```bash
./scripts/configure-kubectl.sh jenkins-eks-cluster us-east-1
```

### 6. Access Jenkins

```bash
./scripts/get-jenkins-access.sh
```

## Deployment Steps

### Step 1: VPC and EKS Infrastructure
- Creates VPC with public and private subnets
- Sets up NAT Gateways for high availability
- Deploys EKS control plane
- Creates managed node groups with proper configurations

### Step 2: Kubernetes Add-ons
- Installs EBS CSI Driver for persistent volumes
- Installs EFS CSI Driver for shared storage
- Configures CoreDNS, kube-proxy, VPC CNI
- Sets up IRSA for pod-level IAM permissions

### Step 3: Monitoring and Auto-scaling
- Deploys Metrics Server for HPA
- Configures Cluster Autoscaler
- Enables CloudWatch logging

### Step 4: Jenkins Deployment
- Creates Kubernetes namespace
- Sets up RBAC (Service Accounts, Roles, Bindings)
- Creates storage classes
- Deploys Jenkins using Helm chart
- Configures Jenkins with CasC (Configuration as Code)

## High Availability & Resilience Features

### 1. **Multi-AZ Deployment**
- Nodes distributed across 3 availability zones
- NAT Gateways in each AZ

### 2. **Pod Anti-Affinity**
- Jenkins controller pods spread across different nodes
- Agent pods prefer different nodes

### 3. **Node Affinity**
- Controller pods require controller node group
- Agents prefer agent node group

### 4. **Auto-scaling**
- Cluster Autoscaler adjusts node count based on demand
- HPA can scale pod replicas based on metrics

### 5. **Health Probes**
- Liveness probe to restart unhealthy containers
- Readiness probe to route traffic only to ready pods

### 6. **Persistent Storage**
- Jenkins data stored on EBS volumes
- Automatic failover with EBS snapshots

### 7. **Update Strategy**
- Rolling updates with 50% max unavailability
- Zero-downtime deployments

### 8. **Resource Management**
- CPU and memory requests/limits configured
- Prevents pod eviction and resource starvation

## Scaling Jenkins

### Scale Controller Replicas
```bash
terraform apply -var="jenkins_replica_count=3"
```

### Scale Agent Replicas
```bash
terraform apply -var="jenkins_agent_replicas=5"
```

### Scale Node Groups
Edit `terraform/eks/main.tf` in the managed node groups and adjust:
- `min_size`: Minimum nodes
- `max_size`: Maximum nodes
- `desired_size`: Current node count

## Monitoring

### Check Cluster Status
```bash
./scripts/monitor.sh
```

### View Jenkins Logs
```bash
kubectl logs -f deployment/jenkins -n jenkins
```

### Access Prometheus Metrics
```bash
kubectl port-forward -n jenkins svc/jenkins 8080:8080
# Open http://localhost:8080/prometheus/
```

## Backup & Disaster Recovery

### Backup Jenkins Data
```bash
./scripts/backup-jenkins.sh
```

### Restore from Backup
```bash
# Create a new EBS volume from snapshot
# Attach to a pod and extract backup
```

## Security Best Practices Implemented

1. **Pod Security Context**
   - Non-root user (uid: 1000)
   - Read-only filesystem where possible
   - No privileged containers

2. **Network Policies**
   - RBAC enforced
   - Service accounts with minimal permissions

3. **Encryption**
   - EBS volumes encrypted by default
   - AWS KMS encryption for data at rest

4. **Secret Management**
   - Sensitive data handled as Kubernetes secrets
   - Jenkins credentials stored securely

5. **IAM**
   - IRSA for pod-level permissions
   - Minimal IAM policies

## Cost Optimization

1. **SPOT Instances**
   - Agent node group uses SPOT instances (70% cost savings)
   - On-Demand for controller (critical workload)

2. **Auto-scaling**
   - Cluster scales down during low usage
   - Agents scale to 0 when not needed

3. **Resource Limits**
   - Prevents resource waste
   - Efficient resource utilization

## Troubleshooting

### Nodes not ready
```bash
kubectl get nodes
kubectl describe node <node-name>
kubectl logs -n kube-system -l k8s-app=aws-node
```

### Jenkins pod not starting
```bash
kubectl describe pod jenkins-0 -n jenkins
kubectl logs jenkins-0 -n jenkins
```

### Storage issues
```bash
kubectl get pvc -n jenkins
kubectl get pv
kubectl get storageclass
```

### Network connectivity
```bash
kubectl exec -it <pod> -n jenkins -- ping kubernetes.default
kubectl exec -it <pod> -n jenkins -- nslookup kubernetes.default
```

## Cleanup

Destroy all resources (this is destructive):

```bash
./scripts/destroy.sh
```

Or manually:
```bash
terraform destroy
```

## Additional Resources

- [Jenkins Helm Chart](https://charts.jenkins.io/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Support

For issues or questions:
1. Check CloudWatch logs
2. Verify AWS credentials and permissions
3. Review EKS cluster events
4. Check Kubernetes resource status

## License

This configuration is provided as-is for educational and production use.
# kube-jenkins
# kube-jenkins
