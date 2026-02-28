# Jenkins on EKS with Terraform - Project Index

## 📋 Project Overview

A complete, production-ready Terraform configuration for deploying highly scalable and resilient Jenkins on AWS EKS. This solution includes multi-AZ infrastructure, auto-scaling, monitoring, and disaster recovery capabilities.

**Key Features:**
- ✅ Multi-AZ deployment for high availability
- ✅ Auto-scaling for both nodes and pods
- ✅ Multiple Jenkins controller replicas
- ✅ Kubernetes-native agent provisioning
- ✅ Persistent storage with EBS/EFS
- ✅ Comprehensive monitoring and logging
- ✅ RBAC and security best practices
- ✅ Cost optimized with SPOT instances

---

## 📁 File Structure & Documentation

### 📖 Main Documentation

| File | Purpose | Read Time |
|------|---------|-----------|
| [README.md](README.md) | Quick reference and architecture overview | 10 min |
| [SETUP_SUMMARY.md](SETUP_SUMMARY.md) | High-level summary of components and features | 15 min |
| [IMPLEMENTATION_STEPS.md](IMPLEMENTATION_STEPS.md) | **START HERE** - Complete step-by-step deployment guide | 20 min |
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Detailed guide with troubleshooting and scaling | 30 min |
| [INDEX.md](INDEX.md) | This file - project navigation and file reference | 5 min |

### 🔧 Terraform Configuration Files

#### Root Level
```
terraform/
├── main.tf                   # Root module composition
├── variables.tf              # Root variables
├── terraform.tf              # Root provider configuration
└── terraform.tfvars.example  # Example values to customize
```

#### EKS Infrastructure (`terraform/eks/`)
```
terraform/eks/
├── main.tf            # VPC, EKS cluster, node groups
├── variables.tf       # EKS-specific variables
├── addons.tf          # Kubernetes add-ons (CSI, DNS, CNI)
└── monitoring.tf      # Metrics Server, Cluster Autoscaler
```

**Key Resources:**
- AWS VPC with public/private subnets across 3 AZs
- EKS control plane with logging enabled
- Two managed node groups:
  - Controller: 2-4 On-Demand t3.xlarge nodes
  - Agents: 1-20 SPOT m5.xlarge/2xlarge nodes
- Security groups and IAM roles
- EBS and EFS CSI drivers

#### Jenkins Deployment (`terraform/jenkins/`)
```
terraform/jenkins/
├── main.tf           # Jenkins Helm deployment
├── variables.tf      # Jenkins-specific variables
└── casc.yaml         # Jenkins Configuration as Code
```

**Key Resources:**
- Kubernetes namespace and service accounts
- RBAC roles and bindings
- Storage classes for Jenkins data
- Helm release for Jenkins
- Pod security context
- Resource limits and affinity rules

### 🛠️ Helper Scripts (`scripts/`)

```
scripts/
├── init.sh                  # Initialize Terraform
├── configure-kubectl.sh     # Configure kubectl access
├── get-jenkins-access.sh    # Get Jenkins URL and credentials
├── monitor.sh              # Monitor cluster and Jenkins health
├── backup-jenkins.sh       # Backup Jenkins data
└── destroy.sh              # Destroy infrastructure (WARNING!)
```

**Usage Examples:**
```bash
# Initialize project
./scripts/init.sh

# Setup kubectl
./scripts/configure-kubectl.sh jenkins-eks-cluster us-east-1

# Get Jenkins access info
./scripts/get-jenkins-access.sh

# Monitor health
./scripts/monitor.sh

# Backup data
./scripts/backup-jenkins.sh

# Destroy infrastructure
./scripts/destroy.sh
```

---

## 🚀 Quick Start Guide

### 1️⃣ Prerequisites (5 min)
```bash
# Verify prerequisites
terraform version          # >= 1.0
aws --version             # >= 2.x
kubectl version --client  # >= 1.25
aws sts get-caller-identity  # Verify AWS access
```

### 2️⃣ Configuration (5 min)
```bash
cd jenkins/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
nano terraform.tfvars
```

### 3️⃣ Deploy (25-35 min)
```bash
./scripts/init.sh      # Initialize
terraform plan         # Review
terraform apply        # Deploy
```

### 4️⃣ Access (5 min)
```bash
./scripts/configure-kubectl.sh
./scripts/get-jenkins-access.sh
# Jenkins will be available at: http://<EXTERNAL-IP>:8080
```

---

## 📊 Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                       AWS Region (us-east-1)                     │
├─────────────────────┬──────────────────┬─────────────────────────┤
│      AZ-1           │      AZ-2        │       AZ-3              │
├─────────────────────┼──────────────────┼─────────────────────────┤
│  Public Subnet      │  Public Subnet   │  Public Subnet          │
│  - NAT Gateway      │  - NAT Gateway   │  - NAT Gateway          │
│  - NLB (Jenkins)    │  - NLB (Jenkins) │  - NLB (Jenkins)        │
├─────────────────────┼──────────────────┼─────────────────────────┤
│  Private Subnet     │  Private Subnet  │  Private Subnet         │
│  - Jenkins Control  │  - Jenkins       │  - Jenkins              │
│    (t3.xlarge)      │    Agents        │    Agents               │
│  - Jenkins Agents   │    (m5 SPOT)     │    (m5 SPOT)            │
│    (m5 SPOT)        │                  │                         │
└─────────────────────┴──────────────────┴─────────────────────────┘
```

### Key Components

| Component | Purpose | Details |
|-----------|---------|---------|
| **VPC** | Network isolation | 10.0.0.0/16, Multi-AZ |
| **EKS Cluster** | Container orchestration | Kubernetes 1.29 |
| **Controller Nodes** | Jenkins controller | On-Demand, 2-4 nodes, t3.xlarge |
| **Agent Nodes** | Build agents | SPOT, 1-20 nodes, m5.xlarge |
| **EBS Storage** | Jenkins home | 100Gi persistent volume |
| **Cluster Autoscaler** | Node auto-scaling | Dynamic based on demand |
| **Metrics Server** | Resource metrics | Enables HPA |

---

## 🎯 Step-by-Step Deployment

### Phase 1: Pre-Deployment (5 min)
1. Verify AWS credentials
2. Check Terraform installation
3. Review variables

**See:** [IMPLEMENTATION_STEPS.md - Phase 1](IMPLEMENTATION_STEPS.md#phase-1-pre-deployment-validation-5-minutes)

### Phase 2: Configuration (10 min)
1. Copy and edit terraform.tfvars
2. Run init script
3. Review terraform plan

**See:** [IMPLEMENTATION_STEPS.md - Phase 2](IMPLEMENTATION_STEPS.md#phase-2-configuration--planning-10-minutes)

### Phase 3: Infrastructure Deployment (25-35 min)
1. Apply Terraform configuration
2. Monitor creation progress
3. Wait for completion

**See:** [IMPLEMENTATION_STEPS.md - Phase 3](IMPLEMENTATION_STEPS.md#phase-3-infrastructure-deployment-25-35-minutes)

### Phase 4: Post-Deployment (10 min)
1. Configure kubectl
2. Wait for Jenkins pod readiness
3. Get access details

**See:** [IMPLEMENTATION_STEPS.md - Phase 4](IMPLEMENTATION_STEPS.md#phase-4-post-deployment-setup-10-minutes)

### Phase 5: Initial Configuration (15 min)
1. Access Jenkins UI
2. Install plugins
3. Configure Kubernetes cloud

**See:** [IMPLEMENTATION_STEPS.md - Phase 5](IMPLEMENTATION_STEPS.md#phase-5-initial-configuration-15-minutes)

### Phase 6+: Scaling, Monitoring, Backup
- Scale components as needed
- Configure monitoring and alerting
- Setup automated backups
- Test disaster recovery

**See:** [IMPLEMENTATION_STEPS.md - Phases 6-10](IMPLEMENTATION_STEPS.md)

---

## 📈 Customization Reference

### Common Modifications

#### Change AWS Region
```hcl
# In terraform.tfvars
aws_region = "eu-west-1"  # Change from default us-east-1
```

#### Adjust Node Counts
```hcl
# In terraform/eks/main.tf
controller = {
  desired_size = 3    # Increase controllers
  max_size     = 6
}

agents = {
  desired_size = 5    # Increase agents
  max_size     = 20
}
```

#### Scale Jenkins Resources
```bash
terraform apply \
  -var="jenkins_cpu_request=250m" \
  -var="jenkins_cpu_limit=1000m" \
  -var="jenkins_memory_request=512Mi" \
  -var="jenkins_memory_limit=2Gi"
```

#### Enable Ingress with HTTPS
```hcl
enable_jenkins_ingress = true
jenkins_ingress_hostname = "jenkins.example.com"
```

### Configuration Variables

**Core Infrastructure:**
- `aws_region`: AWS region (default: us-east-1)
- `cluster_name`: EKS cluster name (default: jenkins-eks-cluster)
- `cluster_version`: Kubernetes version (default: 1.29)
- `vpc_cidr`: VPC CIDR block (default: 10.0.0.0/16)

**Jenkins Settings:**
- `jenkins_admin_user`: Admin username
- `jenkins_admin_password`: Admin password (⚠️ CHANGE THIS!)
- `jenkins_replica_count`: Controller replicas (default: 2)
- `jenkins_agent_replicas`: Agent replicas (default: 3)
- `jenkins_storage_size`: Jenkins home size (default: 100Gi)
- `jenkins_cpu_request/limit`: CPU allocation
- `jenkins_memory_request/limit`: Memory allocation

**Features:**
- `enable_cluster_autoscaler`: Enable auto-scaling (default: true)
- `enable_metrics_server`: Enable HPA metrics (default: true)
- `enable_ebs_csi`: Enable EBS storage (default: true)
- `enable_efs_csi`: Enable EFS storage (default: true)

---

## 🔍 Monitoring & Operations

### Health Checks
```bash
# Check cluster status
kubectl get nodes
kubectl get pods -n jenkins

# Monitor resource usage
kubectl top nodes
kubectl top pods -n jenkins

# View events
kubectl get events -n jenkins
```

### Logging
```bash
# Jenkins controller logs
kubectl logs -f deployment/jenkins -n jenkins

# System logs
kubectl logs -n kube-system -l k8s-app=aws-node

# CloudWatch logs
aws logs tail /aws/eks/jenkins-eks-cluster --follow
```

### Backup & Recovery
```bash
# Backup Jenkins
./scripts/backup-jenkins.sh

# List backups
ls -lh jenkins-backups/

# Monitor backup job
watch kubectl get pods -n jenkins
```

---

## 🛡️ Security Features

✅ **Pod Security**
- Non-root containers
- Resource limits prevent DOS
- Security contexts configured

✅ **Network Security**
- VPC isolation
- Security groups restrict traffic
- RBAC enforces permissions

✅ **IAM Security**
- IRSA for pod-to-AWS authentication
- Minimal IAM policies
- Service accounts configured

✅ **Data Security**
- EBS volumes encrypted by default
- Persistent volume backups
- Secret management

---

## 💰 Cost Optimization

| Feature | Savings | Details |
|---------|---------|---------|
| SPOT Instances | ~70% | Agents use SPOT for cost savings |
| Auto-Scaling | ~30% | Nodes scale down during low usage |
| On-Demand Control | ~0% | Critical control plane on On-Demand |
| Efficient Resource Limits | ~20% | Prevents over-provisioning |
| **Total Potential Savings** | **~40-50%** | Compared to fixed sizing |

---

## 🆘 Troubleshooting

### Common Issues

| Issue | Solution | More Info |
|-------|----------|-----------|
| Nodes not Ready | Check security groups, IAM roles | [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#troubleshooting-common-issues) |
| Jenkins pod CrashLooping | Increase memory, check PVC | [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#jenkins-pod-crashlooping) |
| Cannot access LoadBalancer | Wait 2-5 min, check security group | [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#cannot-access-loadbalancer) |
| High memory usage | Increase limits, tune JVM | [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#high-memory-usage) |

---

## 📋 Pre-Deployment Checklist

Before running `terraform apply`:

- [ ] AWS credentials configured (`aws sts get-caller-identity` works)
- [ ] Terraform installed (v1.0+)
- [ ] kubectl installed (v1.25+)
- [ ] terraform.tfvars updated with your values
- [ ] `jenkins_admin_password` changed to secure value
- [ ] AWS region accessible and has capacity
- [ ] Service limits checked (EC2, VPC, EKS)

---

## ✅ Post-Deployment Verification

After deployment completes:

- [ ] All nodes in Ready state
- [ ] All Jenkins pods Running
- [ ] Jenkins accessible via LoadBalancer
- [ ] Can login with admin credentials
- [ ] Test pipeline executes successfully
- [ ] Cluster autoscaler operational
- [ ] Metrics server collecting data
- [ ] Backups created successfully
- [ ] Multi-AZ deployment verified

---

## 📚 Additional Resources

### Documentation
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

### Helm Chart
- [Jenkins Helm Chart](https://charts.jenkins.io/)
- [Chart GitHub Repository](https://github.com/jenkinsci/helm-charts)

### AWS Services
- [EKS Documentation](https://docs.aws.amazon.com/eks/)
- [EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/)
- [EBS Documentation](https://docs.aws.amazon.com/ebs/)

---

## 🔄 Maintenance Schedule

| Frequency | Task | Duration |
|-----------|------|----------|
| Daily | Monitor cluster health, check pod status | 5 min |
| Weekly | Review Jenkins logs, check backups | 15 min |
| Monthly | Update plugins, review resource usage | 30 min |
| Quarterly | Test disaster recovery, update Kubernetes | 2-4 hours |
| Annually | Security audit, capacity planning | 1-2 days |

---

## 📞 Support & Escalation

### Issue Resolution Steps
1. Check logs: `kubectl logs -f <pod> -n jenkins`
2. Check events: `kubectl get events -n jenkins`
3. Review troubleshooting guide: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#troubleshooting-common-issues)
4. Check AWS CloudWatch logs
5. Review Terraform state: `terraform show`

### Escalation Path
1. Internal team review of logs
2. AWS Support ticket (if AWS-related)
3. Jenkins community forums
4. Terraform registry issues

---

## 📝 Project Status

- ✅ **Version**: 1.0
- ✅ **Status**: Production-Ready
- ✅ **Last Updated**: February 25, 2026
- ✅ **Tested**: Multi-AZ, Auto-scaling, Disaster Recovery
- ✅ **Documentation**: Complete

---

## 🎓 Learning Path

### For New Users:
1. Read: [README.md](README.md) (10 min)
2. Review: [SETUP_SUMMARY.md](SETUP_SUMMARY.md) (15 min)
3. Follow: [IMPLEMENTATION_STEPS.md](IMPLEMENTATION_STEPS.md) (30 min)

### For Operators:
1. Reference: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
2. Scripts: [scripts/](scripts/)
3. Monitoring: [DEPLOYMENT_GUIDE.md - Monitoring](DEPLOYMENT_GUIDE.md#monitoring--maintenance)

### For DevOps Engineers:
1. Architecture: [README.md - Architecture](README.md#architecture-overview)
2. Terraform: [terraform/eks/](terraform/eks/) and [terraform/jenkins/](terraform/jenkins/)
3. Customization: [README.md - Scaling](README.md#scaling-jenkins)

---

## 💡 Tips & Tricks

### Faster Deployment
```bash
# Use auto-approve to skip confirmation
terraform apply -auto-approve

# Use saved plan for consistency
terraform plan -out=tfplan && terraform apply tfplan
```

### Easier Troubleshooting
```bash
# Set up aliases
alias kgj='kubectl get pods -n jenkins'
alias klj='kubectl logs -f -n jenkins'
alias kg='kubectl get'

# Watch resources in real-time
watch -n 1 'kubectl get pods -n jenkins'
```

### Safer Operations
```bash
# Always backup before making changes
./scripts/backup-jenkins.sh

# Use target to apply specific resources
terraform apply -target=module.jenkins_deployment

# Destroy with protection
terraform destroy -auto-approve  # Use carefully!
```

---

**Ready to deploy? Start with [IMPLEMENTATION_STEPS.md](IMPLEMENTATION_STEPS.md)! 🚀**
