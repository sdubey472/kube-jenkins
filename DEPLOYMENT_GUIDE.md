# Jenkins on EKS - Complete Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Architecture](#architecture)
3. [Deployment Steps](#deployment-steps)
4. [Post-Deployment Configuration](#post-deployment-configuration)
5. [Scaling & Optimization](#scaling--optimization)
6. [Monitoring & Maintenance](#monitoring--maintenance)

## Prerequisites

### Required Tools
- **Terraform**: v1.0 or higher
- **AWS CLI**: v2.x configured with credentials
- **kubectl**: v1.25 or higher
- **Helm**: v3.x (optional, used by Terraform)

### AWS Permissions Required
The IAM user/role must have permissions for:
- EC2 (VPC, Security Groups, Instances)
- EKS (Cluster management)
- IAM (OIDC, Roles, Policies)
- CloudWatch (Logging)
- Load Balancing
- Auto Scaling

### AWS Account Setup
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Set default region
export AWS_REGION=us-east-1
```

## Architecture

### Multi-AZ Setup
```
┌─────────────────────────────────────────────────────────┐
│                        AWS Region                        │
├──────────────────┬──────────────────┬──────────────────┤
│   AZ-1           │   AZ-2           │   AZ-3           │
├──────────────────┼──────────────────┼──────────────────┤
│  Public Subnet   │  Public Subnet   │  Public Subnet   │
│  NAT Gateway     │  NAT Gateway     │  NAT Gateway     │
│  ─────────────   │  ─────────────   │  ─────────────   │
│ Private Subnet   │ Private Subnet   │ Private Subnet   │
│  EKS Nodes       │  EKS Nodes       │  EKS Nodes       │
│  (Controller)    │  (Agents)        │  (Agents)        │
└──────────────────┴──────────────────┴──────────────────┘
```

### Jenkins Deployment Model
```
┌────────────────────────────────────┐
│     EKS Cluster                    │
├────────────────────────────────────┤
│  Controller Node Group              │
│  ┌──────────────────────────────┐  │
│  │  Jenkins Controller Pod      │  │
│  │  - Running: 2 replicas      │  │
│  │  - Storage: 100Gi EBS       │  │
│  │  - Resources: 500m-2000m    │  │
│  └──────────────────────────────┘  │
├────────────────────────────────────┤
│  Agent Node Group (SPOT)            │
│  ┌──────────────────────────────┐  │
│  │  Jenkins Agent Pods          │  │
│  │  - Running: 3+ replicas      │  │
│  │  - Ephemeral storage         │  │
│  │  - Auto-scales 0-20 nodes    │  │
│  └──────────────────────────────┘  │
└────────────────────────────────────┘
```

## Deployment Steps

### Step 1: Clone and Setup Repository

```bash
# Navigate to your workspace
cd /path/to/jenkins-terraform

# Make scripts executable
chmod +x scripts/*.sh

# Copy example values
cp terraform.tfvars.example terraform.tfvars
```

### Step 2: Configure Variables

Edit `terraform.tfvars`:

```hcl
aws_region      = "us-east-1"           # Change to your region
cluster_name    = "jenkins-eks-cluster"
cluster_version = "1.29"

# Jenkins credentials - CHANGE THESE!
jenkins_admin_user     = "admin"
jenkins_admin_password = "YourStrongPassword123!@#"

environment = "production"

tags = {
  Project     = "Jenkins"
  Environment = "production"
  ManagedBy   = "Terraform"
  CostCenter  = "Engineering"
}
```

### Step 3: Initialize Terraform

```bash
# Initialize Terraform working directory
./scripts/init.sh

# This will:
# - Check prerequisites
# - Create terraform.tfvars
# - Run terraform init
```

### Step 4: Plan Deployment

```bash
# Review what will be created
terraform plan -out=tfplan

# Expected outputs:
# - VPC with subnets and NAT gateways
# - EKS cluster and node groups
# - Add-ons (EBS CSI, EFS CSI, etc.)
# - Jenkins namespace and deployment
# - Helm release for Jenkins
```

### Step 5: Apply Configuration

```bash
# Apply the plan
terraform apply tfplan

# This process typically takes 20-30 minutes:
# - VPC creation: 2-3 minutes
# - EKS cluster: 10-15 minutes
# - Node groups: 5-10 minutes
# - Add-ons: 2-3 minutes
# - Jenkins deployment: 3-5 minutes
```

### Step 6: Configure kubectl

```bash
# Configure kubectl to access the cluster
./scripts/configure-kubectl.sh jenkins-eks-cluster us-east-1

# Verify connection
kubectl get nodes
```

### Step 7: Wait for Jenkins to be Ready

```bash
# Monitor pod status
kubectl get pods -n jenkins -w

# Wait until all Jenkins pods are Running and Ready
# Jenkins controller: 1/1 Ready
# Jenkins agents: Should see agent pod definitions
```

## Post-Deployment Configuration

### 1. Access Jenkins

```bash
# Get Jenkins service information
./scripts/get-jenkins-access.sh

# Wait for LoadBalancer IP/hostname (can take 2-5 minutes)
# Once available, access via browser: http://<EXTERNAL-IP>:8080
```

### 2. Initial Jenkins Setup

```bash
# Get initial admin password (if needed)
kubectl exec -it jenkins-0 -n jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword

# Or use the password from terraform.tfvars
# Username: admin
# Password: <jenkins_admin_password from variables>
```

### 3. Install Recommended Plugins

In Jenkins UI:
1. Go to **Manage Jenkins** → **Manage Plugins**
2. Install:
   - Kubernetes Cloud
   - Docker
   - GitHub/GitLab integration
   - Pipeline plugins
   - Monitoring plugins

### 4. Configure Kubernetes Cloud

1. **Manage Jenkins** → **Configure System**
2. Find **Kubernetes** section
3. Configure:
   - Kubernetes URL: `https://kubernetes.default`
   - Kubernetes Namespace: `jenkins`
   - Credentials: Use in-cluster RBAC

### 5. Setup Jenkins Backup

```bash
# Create daily backup
# Add cron job or use script:
./scripts/backup-jenkins.sh
```

## Scaling & Optimization

### Horizontal Scaling

#### Scale Jenkins Controller Replicas
```bash
terraform apply -var="jenkins_replica_count=3" -auto-approve
```

**Note**: For true high availability with multiple replicas, configure shared storage and session management.

#### Scale Jenkins Agents
```bash
terraform apply -var="jenkins_agent_replicas=5" -auto-approve
```

#### Scale Node Groups

Edit `terraform/eks/main.tf`:

```hcl
controller = {
  desired_size = 3    # Increase replicas
  max_size     = 6
}

agents = {
  desired_size = 5    # More agents
  max_size     = 20   # Max for SPOT
}
```

### Resource Optimization

#### Adjust Jenkins Limits
```bash
terraform apply \
  -var="jenkins_cpu_request=250m" \
  -var="jenkins_cpu_limit=1000m" \
  -var="jenkins_memory_request=512Mi" \
  -var="jenkins_memory_limit=2Gi"
```

#### Optimize Storage
- Monitor PVC usage: `kubectl get pvc -n jenkins`
- Resize if needed: Edit PVC and increase `storage` field

### Cost Optimization

1. **Use SPOT Instances**: Agent node group uses SPOT (already configured)
2. **Enable Auto-scaling**: Cluster Autoscaler scales down unused nodes
3. **Set Pod Disruption Budgets**: Protect critical pods
4. **Configure HPA**: Auto-scale based on metrics

## Monitoring & Maintenance

### Monitor Cluster Health

```bash
# Check node status
kubectl get nodes -o wide

# Monitor pod status
./scripts/monitor.sh

# View real-time metrics
kubectl top nodes
kubectl top pods -n jenkins
```

### View Logs

```bash
# Jenkins controller logs
kubectl logs -f deployment/jenkins -n jenkins

# Jenkins agent logs
kubectl logs -f <agent-pod-name> -n jenkins

# System logs
kubectl logs -f deployment/cluster-autoscaler -n kube-system

# View all events
kubectl get events -n jenkins -w
```

### Metrics and Monitoring

```bash
# Port-forward to Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n jenkins

# Access Jenkins metrics
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
# Visit: http://localhost:8080/prometheus/
```

### Backup Maintenance

```bash
# Backup Jenkins data
./scripts/backup-jenkins.sh

# Verify backup
ls -lh jenkins-backups/

# Schedule regular backups (using cron)
# 0 2 * * * cd /path/to/jenkins && ./scripts/backup-jenkins.sh
```

### Update Procedures

#### Update Jenkins Version
```bash
# Update Jenkins version in Helm values
terraform apply -var="jenkins_version=2.387.3"
```

#### Update Kubernetes Version
```bash
# Update EKS cluster version (one minor version at a time)
terraform apply -var="cluster_version=1.30"

# Monitor control plane update (5-15 minutes)
# Then update node groups
```

#### Apply Node Group Updates
```bash
# Updates nodes with rolling update strategy
# (50% max unavailability configured)
terraform apply
```

### Troubleshooting Common Issues

#### Jenkins Pod CrashLooping

```bash
# Check pod logs
kubectl logs jenkins-0 -n jenkins

# Check resource availability
kubectl describe pod jenkins-0 -n jenkins

# Check PVC status
kubectl get pvc -n jenkins -o wide

# Possible solutions:
# 1. Increase memory/CPU limits
# 2. Expand PVC size
# 3. Delete pod to restart: kubectl delete pod jenkins-0 -n jenkins
```

#### Nodes not joining cluster

```bash
# Check node logs
kubectl logs -n kube-system -l k8s-app=aws-node

# Check node status
kubectl describe node <node-name>

# Check security groups and network configuration
aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupId,GroupName]'
```

#### High latency or connectivity issues

```bash
# Check CNI plugin
kubectl get daemonset -n kube-system

# Check DNS
kubectl exec -it <pod> -n jenkins -- nslookup kubernetes.default

# Test pod-to-pod communication
kubectl exec -it <pod1> -n jenkins -- ping <pod2-ip>
```

### Regular Maintenance Checklist

- [ ] Daily: Check cluster health and pod status
- [ ] Weekly: Review Jenkins backup success
- [ ] Weekly: Check resource utilization
- [ ] Monthly: Review and rotate secrets/credentials
- [ ] Monthly: Update dependencies and plugins
- [ ] Quarterly: Review and optimize costs
- [ ] Quarterly: Test disaster recovery procedures

## Cleanup

### Remove Jenkins Only (Keep EKS)

```bash
# Delete Helm release
helm uninstall jenkins -n jenkins

# Delete namespace
kubectl delete namespace jenkins
```

### Remove Everything

```bash
# Destroy all Terraform resources
./scripts/destroy.sh

# Or manually:
terraform destroy
```

## Next Steps

1. **Configure CI/CD Pipelines**
   - Create Jenkinsfiles in repositories
   - Setup GitHub/GitLab webhooks
   - Configure automated builds

2. **Setup Monitoring**
   - Install Prometheus stack
   - Configure alerts
   - Setup log aggregation

3. **Implement Security**
   - Configure LDAP/OAuth authentication
   - Setup Jenkins credentials management
   - Implement pod security policies

4. **Optimize Performance**
   - Configure distributed builds
   - Optimize build pipelines
   - Monitor and tune resource allocation

## Support & Documentation

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
