# Jenkins on EKS - Implementation Steps

## Complete Step-by-Step Guide for Production Deployment

### Phase 1: Pre-Deployment Validation (5 minutes)

#### 1.1 Verify Prerequisites
```bash
# Check Terraform version
terraform version
# Expected: >= 1.0

# Check AWS CLI
aws --version
# Expected: aws-cli/2.x or higher

# Check kubectl
kubectl version --client
# Expected: v1.25 or higher

# Check AWS credentials
aws sts get-caller-identity
# Should return your account info
```

#### 1.2 Verify AWS Permissions
```bash
# Test key permissions
aws ec2 describe-vpcs
aws eks list-clusters
aws iam get-user

# If any fail, ensure IAM permissions are configured
```

#### 1.3 Clone Repository
```bash
cd /workspace/terraform
ls -la jenkins/
# Should see all terraform files
```

---

### Phase 2: Configuration & Planning (10 minutes)

#### 2.1 Update Configuration
```bash
cd jenkins/

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
# IMPORTANT: Change jenkins_admin_password!
nano terraform.tfvars
```

Example `terraform.tfvars`:
```hcl
aws_region      = "us-east-1"
cluster_name    = "jenkins-eks-cluster"
cluster_version = "1.29"

# ⚠️ IMPORTANT: Change these!
jenkins_admin_user     = "admin"
jenkins_admin_password = "ChangeMe123!@#SecurePassword"

environment = "production"

tags = {
  Project     = "Jenkins"
  Environment = "production"
  ManagedBy   = "Terraform"
}
```

#### 2.2 Initialize Terraform
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Initialize
./scripts/init.sh

# Output should show:
# ✓ Prerequisites check passed
# ✓ Terraform initialization complete
```

#### 2.3 Review Plan
```bash
# Generate and save plan
terraform plan -out=tfplan

# Review output (will show ~150+ resources to create):
# - VPC components
# - EKS cluster
# - Node groups
# - Add-ons
# - Jenkins Helm release
```

---

### Phase 3: Infrastructure Deployment (25-35 minutes)

#### 3.1 Apply Configuration
```bash
# Apply the plan
terraform apply tfplan

# Deployment begins - watch output for:
# - VPC creation (2-3 min)
# - EKS control plane (10-15 min) ← longest step
# - Node groups (5-10 min)
# - Add-ons (2-3 min)
# - Jenkins deployment (3-5 min)
```

**Progress Indicators**:
```
module.eks_infrastructure.module.vpc.aws_vpc.this[0]: Creating...
✓ vpc created
module.eks_infrastructure.module.eks.aws_eks_cluster.this[0]: Creating...
✓ eks cluster created (takes 10-15 minutes)
module.eks_infrastructure.module.eks.aws_eks_node_group.this["jenkins_controller"]: Creating...
module.eks_infrastructure.module.eks.aws_eks_node_group.this["jenkins_agents"]: Creating...
✓ node groups created
module.jenkins_deployment.kubernetes_namespace.jenkins: Creating...
module.jenkins_deployment.helm_release.jenkins: Creating...
✓ jenkins deployed via helm
```

#### 3.2 Monitor Deployment
In another terminal:
```bash
# Watch cluster creation
watch kubectl get nodes

# Wait for nodes to be Ready
# Expected output:
# NAME                          STATUS   ROLES    ...
# ip-10-0-1-xx.ec2.internal     Ready    <none>
# ip-10-0-2-xx.ec2.internal     Ready    <none>
```

---

### Phase 4: Post-Deployment Setup (10 minutes)

#### 4.1 Configure kubectl
```bash
./scripts/configure-kubectl.sh jenkins-eks-cluster us-east-1

# Verify connection
kubectl cluster-info
kubectl get nodes
```

#### 4.2 Wait for Jenkins Pod Readiness
```bash
# Watch Jenkins pods
kubectl get pods -n jenkins -w

# Wait for:
# NAME                   READY   STATUS    ...
# jenkins-0              1/1     Running
# jenkins-agent-0        1/1     Running
# jenkins-agent-1        1/1     Running
# jenkins-agent-2        1/1     Running
```

#### 4.3 Get Jenkins Access Details
```bash
./scripts/get-jenkins-access.sh

# Output shows:
# - Jenkins service LoadBalancer endpoint
# - How to get admin password
# - Jenkins log access commands

# In another terminal, monitor LoadBalancer IP:
kubectl get svc -n jenkins jenkins -w

# Wait for EXTERNAL-IP to appear (may take 2-5 minutes)
# Example output:
# NAME      TYPE           CLUSTER-IP    EXTERNAL-IP        PORT(S)
# jenkins   LoadBalancer   10.100.1.1    a1b2c3d4-5e6f.elb.us-east-1.amazonaws.com
```

#### 4.4 Access Jenkins UI
```bash
# Open in browser:
# http://<EXTERNAL-IP>:8080

# Login with credentials:
# Username: admin
# Password: <from terraform.tfvars>
```

---

### Phase 5: Initial Configuration (15 minutes)

#### 5.1 Install Additional Plugins
1. Open Jenkins UI
2. Navigate to **Manage Jenkins** → **Manage Plugins**
3. Go to **Available** tab
4. Search and install:
   - Docker Pipeline
   - GitHub Integration
   - Google Storage Plugin
   - Backup Plugin
   - Configuration as Code (should be pre-installed)

#### 5.2 Configure Kubernetes Cloud
1. **Manage Jenkins** → **Configure System**
2. Find **Cloud** section
3. Add **Kubernetes** cloud:
   ```
   Kubernetes URL: https://kubernetes.default
   Kubernetes Namespace: jenkins
   Jenkins URL: http://jenkins:8080
   ```
4. Click **Test Connection** → Should succeed

#### 5.3 Create Test Pipeline
```groovy
pipeline {
    agent {
        kubernetes {
            label 'kubernetes'
            yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  serviceAccountName: jenkins
                  containers:
                  - name: docker
                    image: docker:latest
                    command:
                    - cat
                    tty: true
                  - name: kubectl
                    image: bitnami/kubectl:latest
                    command:
                    - cat
                    tty: true
            '''
        }
    }
    stages {
        stage('Build') {
            steps {
                echo 'Building on Kubernetes agent...'
                sh 'kubectl get nodes'
            }
        }
    }
}
```

---

### Phase 6: Scaling & Optimization (As Needed)

#### 6.1 Scale Jenkins Replicas
```bash
# Scale to 3 controllers for higher availability
terraform apply -var="jenkins_replica_count=3" -auto-approve

# Monitor rolling update
kubectl get pods -n jenkins -w
```

#### 6.2 Scale Agent Replicas
```bash
# Increase agent capacity
terraform apply -var="jenkins_agent_replicas=5" -auto-approve
```

#### 6.3 Configure Auto-scaling
```bash
# Create HPA for Jenkins agents
kubectl autoscale deployment jenkins-agents \
  -n jenkins \
  --min=2 \
  --max=10 \
  --cpu-percent=70
```

---

### Phase 7: Monitoring & Backup (Ongoing)

#### 7.1 Setup Monitoring
```bash
# Check cluster health daily
./scripts/monitor.sh

# Or individual checks:
kubectl get nodes
kubectl get pods -n jenkins
kubectl top nodes
kubectl top pods -n jenkins
```

#### 7.2 Setup Automated Backups
```bash
# Create backup
./scripts/backup-jenkins.sh

# Setup cron job for daily backups
# Edit crontab:
crontab -e

# Add line:
# 0 2 * * * cd /path/to/jenkins && ./scripts/backup-jenkins.sh
```

#### 7.3 Verify Backups
```bash
# Check backup files
ls -lh jenkins-backups/

# Example output:
# -rw-r--r-- 1 user group 2.3G Feb 25 02:01 jenkins-backup-20260225_020100.tar.gz
```

---

### Phase 8: Production Hardening

#### 8.1 Enable HTTPS
```bash
# Create TLS certificate in AWS ACM
aws acm request-certificate \
  --domain-name jenkins.example.com \
  --validation-method DNS

# Edit terraform.tfvars to add ingress settings
terraform apply -var="enable_jenkins_ingress=true" \
               -var="jenkins_ingress_hostname=jenkins.example.com"
```

#### 8.2 Configure Authentication
In Jenkins:
1. **Manage Jenkins** → **Configure Global Security**
2. Select **LDAP** or **GitHub OAuth**
3. Configure your identity provider

#### 8.3 Setup Email Notifications
In Jenkins:
1. **Manage Jenkins** → **Configure System**
2. Find **Email Notification**
3. Configure SMTP:
   ```
   SMTP Server: smtp.gmail.com
   SMTP Port: 587
   Use TLS: ✓
   Reply-To: jenkins@example.com
   ```

#### 8.4 Enable Jenkins Security
1. **Manage Jenkins** → **Configure Global Security**
2. **Authorize Project**: Install & configure
3. **Matrix Authorization**: Setup roles
4. **CSRF Protection**: Enable (default)
5. **Agent → Master**: Configure access control

---

### Phase 9: Disaster Recovery Test

#### 9.1 Test Backup Restore
```bash
# Simulate data loss
kubectl exec -it jenkins-0 -n jenkins -- rm /var/jenkins_home/config.xml

# Verify Jenkins detects issue (should show errors in logs)
kubectl logs jenkins-0 -n jenkins

# Restore from backup (manual process for testing)
```

#### 9.2 Test Node Failure
```bash
# Cordon a node (mark as unschedulable)
kubectl cordon <node-name>

# Verify pods reschedule to other nodes
kubectl get pods -n jenkins -o wide

# Uncordon node
kubectl uncordon <node-name>
```

#### 9.3 Test Cluster Failover
```bash
# Verify multi-AZ deployment
kubectl get nodes -L topology.kubernetes.io/zone

# Should show nodes distributed across multiple AZs
```

---

### Phase 10: Cleanup (If Needed)

#### 10.1 Destroy Infrastructure
```bash
# ⚠️ WARNING: This deletes everything!

# Backup Jenkins data first
./scripts/backup-jenkins.sh

# Destroy resources
./scripts/destroy.sh

# Or manually:
terraform destroy
```

#### 10.2 Verify Cleanup
```bash
# Verify all AWS resources deleted
aws eks list-clusters
aws ec2 describe-vpcs --query 'Vpcs[?Tags[?Key==`Name`]]'
aws elb describe-load-balancers
```

---

## Troubleshooting by Phase

### During Infrastructure Deployment

**Issue**: `terraform plan` shows errors
- ✅ Verify AWS credentials: `aws sts get-caller-identity`
- ✅ Check IAM permissions
- ✅ Verify region is set

**Issue**: EKS cluster creation fails
- ✅ Check AWS service limits (EC2, VPC)
- ✅ Verify AZ availability
- ✅ Check CloudFormation events in AWS console

**Issue**: Node groups not joining
- ✅ Check security groups
- ✅ Verify IAM node role
- ✅ Check CloudWatch logs: `/aws/eks/jenkins-eks-cluster/cluster`

### After Deployment

**Issue**: Jenkins pod not starting
```bash
kubectl describe pod jenkins-0 -n jenkins
kubectl logs jenkins-0 -n jenkins
```
- ✅ PVC not provisioned? Check storage class
- ✅ Resource limits too low? Increase memory/CPU
- ✅ Port conflict? Check service bindings

**Issue**: Cannot access Jenkins LoadBalancer
```bash
kubectl get svc -n jenkins jenkins
kubectl describe svc jenkins -n jenkins
```
- ✅ Waiting for IP? AWS takes 2-5 minutes
- ✅ Security group allows port 8080? Check AWS console
- ✅ LoadBalancer not ready? Check events: `kubectl get events -n jenkins`

**Issue**: High memory usage
```bash
kubectl top pods -n jenkins
```
- ✅ Increase jenkins_memory_limit in terraform.tfvars
- ✅ Configure Jenkins max memory: edit JVM_OPTS
- ✅ Reduce number of executors

---

## Performance Metrics to Monitor

| Metric | Target | Action |
|--------|--------|--------|
| Node CPU | < 70% | Scale up nodes |
| Node Memory | < 80% | Increase instance size |
| Jenkins Pod Memory | < 80% | Increase memory limit |
| Pod Startup Time | < 5 min | Check logs, increase resources |
| Build Success Rate | > 95% | Review failed builds |
| Backup Success | 100% | Test restore procedure |

---

## Success Criteria Checklist

- [ ] All nodes in Ready state
- [ ] All Jenkins pods Running
- [ ] Jenkins accessible via LoadBalancer IP
- [ ] Can login with admin credentials
- [ ] Test pipeline executes successfully
- [ ] Cluster Autoscaler working
- [ ] Metrics Server collecting data
- [ ] Backups created successfully
- [ ] Multi-AZ deployment verified
- [ ] Disaster recovery tested

---

**Once all steps are complete, your Jenkins on EKS infrastructure is ready for production use!**
