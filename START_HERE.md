# 🚀 Jenkins on EKS - Start Here!

## Welcome to Your Jenkins Deployment

This is a complete, production-ready Terraform configuration for deploying Jenkins on AWS EKS with high scalability and resilience.

### ⏱️ Time Estimate
- **Setup**: 5 minutes
- **Deployment**: 25-35 minutes  
- **Post-config**: 10 minutes
- **Total**: ~50 minutes

---

## 🎯 What You'll Get

✅ **Highly Available Jenkins**
- Multi-AZ deployment across 3 availability zones
- Multiple Jenkins controller replicas
- Automatic failover and recovery

✅ **Scalable Infrastructure**
- Automatic node scaling (1-20 agents)
- Kubernetes-native Jenkins agents
- Load balancer for traffic distribution

✅ **Enterprise Features**
- Persistent storage with EBS
- Comprehensive logging and monitoring
- RBAC and security best practices
- Automated backups

✅ **Cost Optimized**
- SPOT instances for 70% savings
- Auto-scaling reduces idle resources
- Right-sized resource limits

---

## 📚 Documentation Guide

### For Quick Start
👉 **Start with [IMPLEMENTATION_STEPS.md](IMPLEMENTATION_STEPS.md)**
- Step-by-step deployment instructions
- Complete from start to finish
- Includes troubleshooting

### For Understanding Architecture  
📖 **Read [README.md](README.md)**
- Architecture overview
- Component descriptions
- Quick reference guide

### For Complete Details
📋 **Reference [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)**
- Detailed deployment procedures
- Scaling instructions
- Monitoring and maintenance

### For File Navigation
🗂️ **Use [INDEX.md](INDEX.md)**
- Complete file reference
- Quick lookup table
- Navigation guide

---

## ⚡ Quick Start (5 minutes)

```bash
# 1. Configure
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Change jenkins_admin_password!

# 2. Deploy
./scripts/init.sh
terraform plan
terraform apply

# 3. Access
./scripts/configure-kubectl.sh
./scripts/get-jenkins-access.sh

# Jenkins URL will be: http://<EXTERNAL-IP>:8080
```

---

## 🔍 What's Happening

### Architecture
```
AWS Region (Multi-AZ)
├── VPC with Public/Private Subnets
├── EKS Cluster (Control Plane)
├── Controller Node Group (On-Demand)
│   └── Jenkins Controller Pods (2+ replicas)
├── Agent Node Group (SPOT)
│   └── Jenkins Agent Pods (3+ replicas)
└── Storage (EBS + EFS)
```

### Deployment Steps
1. **Infrastructure** (VPC, EKS, Node Groups) - 15-20 min
2. **Add-ons** (CSI Drivers, Networking) - 2-3 min
3. **Jenkins** (Kubernetes resources, Helm chart) - 3-5 min

---

## 📋 Before You Start

Check that you have:

- [x] AWS Account with credentials configured
  ```bash
  aws sts get-caller-identity
  ```

- [x] Terraform installed (v1.0+)
  ```bash
  terraform version
  ```

- [x] AWS CLI installed (v2.x)
  ```bash
  aws --version
  ```

- [x] kubectl installed (v1.25+)
  ```bash
  kubectl version --client
  ```

---

## 🚨 Important Configuration

**⚠️ REQUIRED - Change the admin password:**

Edit `terraform.tfvars`:
```hcl
jenkins_admin_password = "ChangeMe123!@#" → "YourStrongPassword!@#"
```

**Optional customizations:**
- AWS region (default: us-east-1)
- Cluster name (default: jenkins-eks-cluster)
- Number of replicas/agents
- Instance types and sizes

---

## �� Next Steps (Choose One)

### Option 1: Guided Deployment 🎓
1. Open [IMPLEMENTATION_STEPS.md](IMPLEMENTATION_STEPS.md)
2. Follow Phase 1 through Phase 10
3. ~50 minutes total

### Option 2: Quick Deployment 🏃
```bash
./scripts/init.sh
terraform plan
terraform apply
```

### Option 3: Learn Architecture First 📚
1. Read [README.md](README.md)
2. Review [SETUP_SUMMARY.md](SETUP_SUMMARY.md)
3. Then proceed with deployment

---

## 💡 Tips

**Get help anytime:**
```bash
# View all documentation
ls -la *.md

# Check available scripts
ls -la scripts/

# Review Terraform files
ls -la terraform/*/

# Get cluster status
kubectl get nodes
kubectl get pods -n jenkins
```

**Monitor deployment:**
```bash
# In another terminal:
watch kubectl get pods -n jenkins
```

**Access Jenkins:**
```bash
# Once deployed:
./scripts/get-jenkins-access.sh
```

---

## 🆘 Common Issues

| Problem | Solution |
|---------|----------|
| Terraform init fails | Check AWS credentials: `aws sts get-caller-identity` |
| Nodes not joining | Wait 5-10 min, check security groups |
| Jenkins pod pending | Check PVC status: `kubectl get pvc -n jenkins` |
| Can't access Jenkins | Wait 2-5 min for LoadBalancer IP |

**See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed troubleshooting**

---

## 📞 Getting Help

1. **Check logs:**
   ```bash
   kubectl logs -f deployment/jenkins -n jenkins
   ```

2. **Check events:**
   ```bash
   kubectl get events -n jenkins
   ```

3. **Review guide:**
   - [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Troubleshooting section
   - [IMPLEMENTATION_STEPS.md](IMPLEMENTATION_STEPS.md) - Troubleshooting by phase

4. **Check AWS:**
   - CloudWatch Logs: `/aws/eks/jenkins-eks-cluster/cluster`
   - EC2 Console for node status
   - ELB Console for load balancer status

---

## ✅ Success Checklist

When you see this, you're done:

- [x] Terraform apply completes successfully
- [x] All nodes show "Ready" status
- [x] Jenkins pod is "Running"
- [x] Can access Jenkins at http://<EXTERNAL-IP>:8080
- [x] Can login with admin credentials
- [x] Test pipeline executes successfully

---

## 🎓 Learning Resources

- **Jenkins**: https://www.jenkins.io/doc/
- **Kubernetes**: https://kubernetes.io/docs/
- **AWS EKS**: https://docs.aws.amazon.com/eks/
- **Terraform**: https://www.terraform.io/docs/

---

## 📝 File Quick Reference

```
📁 jenkins/
├── 🚀 START_HERE.md                    ← You are here!
├── 📖 README.md                        ← Architecture overview
├── 📋 INDEX.md                         ← File navigation
├── 🎓 IMPLEMENTATION_STEPS.md          ← Follow this for deployment
├── 📚 DEPLOYMENT_GUIDE.md              ← Detailed reference
├── 📊 SETUP_SUMMARY.md                 ← Feature summary
│
├── 🔧 main.tf                          ← Root configuration
├── 🔧 variables.tf                     ← Root variables
├── 🔧 terraform.tf                     ← Root provider setup
├── 📝 terraform.tfvars.example         ← Example configuration
│
├── 📂 terraform/eks/                   ← EKS infrastructure
│   ├── main.tf                         ← VPC, EKS, node groups
│   ├── variables.tf                    ← Variables
│   ├── addons.tf                       ← CSI drivers, networking
│   └── monitoring.tf                   ← Autoscaler, metrics
│
├── 📂 terraform/jenkins/               ← Jenkins deployment
│   ├── main.tf                         ← Kubernetes & Helm
│   ├── variables.tf                    ← Variables
│   └── casc.yaml                       ← Jenkins configuration
│
└── 📂 scripts/                         ← Helper scripts
    ├── init.sh                         ← Initialize Terraform
    ├── configure-kubectl.sh            ← Setup kubectl
    ├── get-jenkins-access.sh           ← Get Jenkins URL
    ├── monitor.sh                      ← Monitor health
    ├── backup-jenkins.sh               ← Backup data
    └── destroy.sh                      ← Cleanup (dangerous!)
```

---

## 🎯 Your Mission

1. ✅ Customize `terraform.tfvars`
2. ✅ Run `./scripts/init.sh`
3. ✅ Run `terraform apply`
4. ✅ Run `./scripts/get-jenkins-access.sh`
5. ✅ Open Jenkins in browser
6. ✅ Start building!

---

**Ready? Open [IMPLEMENTATION_STEPS.md](IMPLEMENTATION_STEPS.md) and follow Phase 1! 🚀**

---

*Deployed: February 25, 2026 | Status: Production-Ready | Version: 1.0*
