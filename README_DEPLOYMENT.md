# Complete CI/CD & Terraform Deployment Guide

**Last Updated:** 2026-09-29  
**Status:** Production Ready ✅

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Workflow Overview](#workflow-overview)
3. [How to Deploy](#how-to-deploy)
4. [Terraform & Drift Detection](#terraform--drift-detection)
5. [AWS Setup](#aws-setup)
6. [Pre-commit Hooks](#pre-commit-hooks)
7. [Troubleshooting](#troubleshooting)
8. [FAQ](#faq)

---

## 🚀 Quick Start

### For Developers

```bash
# 1. Make changes, commit, and push
git checkout -b feature/my-change
# ... make changes ...
git commit -m "Update infrastructure"
git push origin feature/my-change

# 2. Create PR and get approval
# GitHub Actions automatically runs validation

# 3. Merge to main
# After PR approval, code is merged

# 4. Trigger deployment (MANUAL)
# Go to Actions → "Complete CI/CD Orchestration"
# Click "Run workflow"
# Configure options
# Click "Run workflow"

# 5. Approve when prompted in GitHub
# Infrastructure deployed!
```

### For DevOps/SRE

```bash
# Trigger via CLI
gh workflow run orchestrate.yml \
  -f terraform_plan=true \
  -f deploy_infrastructure=true \
  -f infra_action=apply \
  -f infra_environment=prod \
  -f deploy_application=true

# Monitor the workflow
# Review plan artifacts
# Approve when ready
```

---

## 🔄 Workflow Overview

### Single Source of Truth: `orchestrate.yml`

**All deployments use one workflow** - No automatic deployments.

```
Developer writes code
    ↓
Create PR
    ↓
GitHub Actions validates (automatic)
  ✅ Terraform plan
  ✅ Drift detection
  ✅ Unit tests
  ✅ Security scan
    ↓
PR Approved & Merged to main
    ↓
Manual Trigger: orchestrate.yml
    ↓
Pipeline executes:
  STAGE 1: Validate & Test
  STAGE 2A: Terraform Plan (review artifacts)
  STAGE 2B: Terraform Drift Detection
  STAGE 3: Build Docker Images
  STAGE 4: Security Scanning
  STAGE 5: Deploy Infrastructure (manual approval)
  STAGE 6: Deploy Application (manual approval)
    ↓
✅ Infrastructure Updated
✅ Applications Deployed
```

### Why This Design?

| Feature | Benefit |
|---------|---------|
| **Manual trigger** | Full control over deployments |
| **Plan review** | Catch mistakes before apply |
| **Approval gates** | Prevent unintended changes |
| **Drift detection** | Detect manual AWS changes |
| **Audit trail** | Complete deployment history |

---

## 📦 How to Deploy

### Step 1: Prepare Changes

```bash
# Create feature branch
git checkout -b feature/update-eks-config

# Make changes (Terraform, applications, etc.)
# ...

# Commit and push
git add .
git commit -m "Update EKS cluster configuration"
git push origin feature/update-eks-config
```

### Step 2: Create Pull Request

GitHub Actions **automatically runs**:
- ✅ Terraform format check
- ✅ Terraform validation
- ✅ Unit tests
- ✅ Security scanning
- ✅ Terraform plan
- ✅ Drift detection

You can review all results in the PR.

### Step 3: Get Approval

- Code review required
- Plan review required
- PR approval needed

### Step 4: Merge to Main

Once approved:
```bash
# Click "Merge" in GitHub
# Code merged to main
```

### Step 5: Trigger Deployment

#### Option A: GitHub UI (Recommended)

1. Go to **Actions** tab
2. Click **"Complete CI/CD Orchestration"**
3. Click **"Run workflow"**
4. Configure parameters:

```
terraform_plan: true              # Enable Terraform plan + drift
deploy_infrastructure: true       # Deploy infrastructure changes
infra_action: apply              # or "plan" for dry-run
infra_environment: prod          # "dev" or "prod"
build_services: all              # all, user-service, order-service
deploy_application: true         # Deploy applications
app_environment: prod            # "dev" or "prod"
run_tests: true                  # Run unit tests
run_security_scan: true          # Run security scans
```

5. Click **"Run workflow"**

#### Option B: GitHub CLI

```bash
gh workflow run orchestrate.yml \
  -f terraform_plan=true \
  -f deploy_infrastructure=true \
  -f infra_action=apply \
  -f infra_environment=prod \
  -f build_services=all \
  -f deploy_application=true
```

### Step 6: Monitor & Approve

1. Watch pipeline progress in Actions tab
2. Terraform plan stage completes (review artifacts)
3. GitHub prompts for environment approval
4. Click "Approve" to continue
5. Infrastructure deployed automatically

### Step 7: Verify

```bash
# Check AWS console
# Verify resources updated correctly
# Monitor application health
# Confirm no unexpected changes
```

---

## 🏗️ Terraform & Drift Detection

### Terraform Structure

```
terraform/
├── provider.tf              # AWS provider + backend
├── variables.tf             # Input variables
├── outputs.tf               # Outputs
├── environments/
│   ├── dev/                 # Dev environment
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   └── prod/                # Prod environment
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
└── modules/                 # Reusable modules
    ├── networking/
    ├── rds/
    ├── ecs/
    └── eks/
```

### Terraform Validation (Local)

```bash
# Format check
cd terraform
terraform fmt -check -recursive

# Validate
cd environments/dev
terraform init -backend=false
terraform validate

# Same for prod
cd ../prod
terraform init -backend=false
terraform validate
```

### S3 Remote State

**Configuration:**
- Bucket: `microservices-terraform-state-{account-id}`
- Key: `microservices/{environment}/terraform.tfstate`
- Encryption: AES-256 ✅
- Versioning: Enabled ✅
- Public Access: Blocked ✅

**Backend Config** (automatic in CI/CD):
```bash
terraform init \
  -backend-config="bucket=$TERRAFORM_STATE_BUCKET" \
  -backend-config="key=microservices/{env}/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=$TERRAFORM_LOCK_TABLE"
```

### DynamoDB State Locking

Prevents concurrent Terraform modifications:
- Table: `microservices-terraform-locks`
- Partition Key: `LockID` (String)
- Prevents corruption from simultaneous runs

### Infrastructure Drift Detection

**What is drift?**

Terraform expects:
```hcl
instance_type = "t3.medium"
```

But AWS actually has:
```hcl
instance_type = "t3.large"  # Someone manually changed it!
```

**How we detect it:**

1. **Automatic (every 6 hours):**
   ```bash
   # Scheduled workflow runs
   terraform refresh         # Pull current AWS state
   terraform plan           # Compare to configuration
   # If changes → DRIFT DETECTED
   ```

2. **During deployment:**
   - Before applying changes, we detect drift
   - If found, reports it in logs
   - Developer can investigate and decide action

**Example output:**

```
⚠️ DRIFT DETECTED

Affected Resources:
- aws_security_group.app
- aws_instance.web

Action Required:
1. Update Terraform to match current infrastructure
2. Run terraform apply to remediate
3. Investigate why drift occurred
```

---

## 🔑 AWS Setup

### Prerequisites

You need:
- AWS Account
- AWS CLI installed
- GitHub repository access
- Terraform installed locally

### Step 1: Create S3 State Bucket

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="microservices-terraform-state-$ACCOUNT_ID"

# Create bucket
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,\
    BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "✅ S3 Bucket Created: $BUCKET_NAME"
```

### Step 2: Create DynamoDB Lock Table

```bash
aws dynamodb create-table \
  --table-name microservices-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

echo "✅ DynamoDB Table Created"
```

### Step 3: Create OIDC Provider

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list d28dcf2275eee6091a4fc0518e21e27ac969ce3f

echo "✅ OIDC Provider Created"
```

### Step 4: Create IAM Role

**Trust Policy** (GitHub OIDC):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:*"
        }
      }
    }
  ]
}
```

**Inline Policy** (Terraform permissions):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformReadOnly",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ecs:Describe*",
        "rds:Describe*",
        "s3:Get*",
        "s3:List*",
        "secretsmanager:Get*",
        "elasticloadbalancing:Describe*",
        "eks:Describe*",
        "eks:List*",
        "iam:Get*",
        "iam:List*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformState",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:ListBucketVersions"
      ],
      "Resource": [
        "arn:aws:s3:::microservices-terraform-state-*",
        "arn:aws:s3:::microservices-terraform-state-*/*"
      ]
    },
    {
      "Sid": "TerraformStateLocking",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:*:table/microservices-terraform-locks"
    }
  ]
}
```

### Step 5: Add GitHub Secrets

Go to **Settings → Secrets and variables → Actions**

Add these repository secrets:

```
AWS_ACCOUNT_ID              → Your AWS account number (12 digits)
AWS_ROLE_TO_ASSUME          → arn:aws:iam::ACCOUNT:role/terraform-role
TERRAFORM_STATE_BUCKET      → microservices-terraform-state-ACCOUNT_ID
TERRAFORM_LOCK_TABLE        → microservices-terraform-locks
```

### Verify Setup

```bash
# Test S3 access
aws s3 ls microservices-terraform-state-$ACCOUNT_ID/

# Test DynamoDB
aws dynamodb describe-table \
  --table-name microservices-terraform-locks \
  --query 'Table.TableStatus'
# Should return: ACTIVE

# Test IAM role
aws sts get-caller-identity
# Should work with OIDC credentials
```

---

## 🔍 Pre-commit Hooks

### Install Pre-commit

```bash
pip install pre-commit

cd /path/to/repository

pre-commit install
```

### What Gets Checked

Before each commit:

- ✅ Terraform formatting (`terraform fmt`)
- ✅ Terraform validation (`terraform validate`)
- ✅ Terraform linting (`tflint`)
- ✅ Secret detection (`gitleaks`)
- ✅ YAML validation
- ✅ JSON validation
- ✅ Shell script checks
- ✅ Trailing whitespace
- ✅ File ending fixes

### Run Manually

```bash
# Check all files
pre-commit run --all-files

# Check staged files only
pre-commit run

# Check specific file
pre-commit run --files path/to/file.tf
```

---

## 🆘 Troubleshooting

### Terraform Plan Shows Unexpected Changes

**Cause:** State out of sync with AWS

**Solution:**
```bash
cd terraform/environments/dev
terraform refresh -var-file=terraform.tfvars
terraform plan -var-file=terraform.tfvars
```

### Drift Detection Always Alerts

**Cause:** Manual AWS changes or stale state

**Solution:**
1. Review drift log in GitHub Actions
2. Update Terraform config to match AWS OR
3. Run `terraform apply` to remediate

### "State Lock" Error

**Cause:** Previous run didn't release lock

**Solution:**
```bash
# Remove stuck lock
aws dynamodb delete-item \
  --table-name microservices-terraform-locks \
  --key '{"LockID": {"S": "microservices/dev/terraform.tfstate"}}'
```

### OIDC Authentication Fails

**Cause:** IAM trust policy mismatch

**Solution:**
1. Check IAM role trust relationship
2. Verify subject claim matches: `repo:ORG/REPO:*`
3. Check OIDC provider exists in AWS

### Workflow Hangs on Approval

**Cause:** Environment not configured or no approvers

**Solution:**
```bash
# Configure environment
Settings → Environments → Create/Edit environment
  - Set required reviewers (optional)
  - Set deployment branches
```

### Pre-commit Hook Fails

**Cause:** Files not formatted or validation issues

**Solution:**
```bash
# Auto-fix formatting
terraform fmt -recursive

# Run pre-commit again
pre-commit run --all-files
```

---

## ❓ FAQ

### Q: Do I need to change my code?
**A:** No. Terraform and application code stays the same. Only deployment trigger changed.

### Q: Can I deploy from a feature branch?
**A:** No. Always merge to main first, then trigger workflow from main.

### Q: How long does deployment take?
**A:** 15-20 minutes including:
- Validation & tests: 5 min
- Terraform plan: 3 min
- Build: 5 min
- Security scan: 3 min
- Approval wait: Variable
- Deploy: 5 min

### Q: What if I need to deploy urgently?
**A:** Even urgent changes go through approval. This is intentional for safety. Process still takes 15-20 minutes.

### Q: Can I skip the approval?
**A:** No. Approval gates are mandatory for production safety.

### Q: Who can trigger deployments?
**A:** Anyone with push access to the repository.

### Q: Who can approve deployments?
**A:** Configured in GitHub environment settings. Default: repository maintainers.

### Q: What if the plan shows unexpected changes?
**A:** Don't approve! Investigate, update code, merge new PR, trigger again.

### Q: Can I deploy just one service?
**A:** Yes. Use `build_services=user-service` parameter in workflow.

### Q: How do I prevent production deployments?
**A:** GitHub environment approval requirements:
```
Settings → Environments → prod
  - Set required reviewers: 2
  - Restrict deployment branches: main only
```

### Q: Is there a rollback mechanism?
**A:** AWS resources can be destroyed via Terraform. Requires careful planning and manual execution.

### Q: What is infrastructure drift?
**A:** When AWS resources differ from Terraform configuration. Example: Someone manually changed a security group, but Terraform still expects the old config.

### Q: How is drift detected?
**A:** 
1. Automatic: Every 6 hours
2. During deployment: Before applying changes
3. Manual: Trigger `terraform-scheduled-drift` workflow

### Q: What if drift is detected?
**A:** Investigate and decide:
1. Update Terraform to match current infrastructure
2. Run terraform apply to remediate
3. Investigate why manual changes were made

### Q: Can I make manual AWS changes?
**A:** Technically yes, but drift detection will catch them. Not recommended - keep everything in Terraform.

### Q: What about the old deploy.yml workflow?
**A:** Archived as `deploy.yml.disabled`. Use `orchestrate.yml` instead. Old workflow was auto-deploying which is not production-safe.

### Q: Where are logs?
**A:** GitHub Actions tab → workflow run → step logs

### Q: Where are artifacts?
**A:** GitHub Actions tab → workflow run → Artifacts section
- Terraform plan binaries
- Plan logs
- Drift logs
- Security scan results

### Q: How do I test changes safely?
**A:** Deploy to dev first:
1. Trigger workflow with `infra_environment=dev`
2. Review results
3. Once verified, deploy to prod with `infra_environment=prod`

### Q: Can multiple people deploy simultaneously?
**A:** GitHub prevents concurrent runs in same environment via locks. Only one deployment proceeds at a time.

### Q: What if deployment fails?
**A:** Check logs in GitHub Actions:
1. Click failed step
2. Read error message
3. Fix issue
4. Trigger workflow again

### Q: Are there backups?
**A:** Yes:
- S3 state versioning: Keep all state file versions
- Terraform state backups: Available in S3 bucket

---

## 📞 Support

### For Questions About:

- **Workflow usage** → Read `.github/workflows/README.md`
- **Terraform details** → Check `terraform/` directory
- **Drift detection** → See "Terraform & Drift Detection" section above
- **AWS setup** → See "AWS Setup" section above
- **Deployment issues** → See "Troubleshooting" section above
- **General questions** → Check "FAQ" section above

### Getting Help

1. Check this README first (most questions answered here)
2. Check GitHub Actions logs (workflow failures)
3. Check AWS CloudTrail (infrastructure changes)
4. Ask in team Slack channel
5. Contact DevOps team

---

## 🔐 Security

### What's Protected

✅ **AWS Credentials**
- OIDC authentication only
- No hardcoded credentials
- Temporary credentials per run

✅ **Terraform State**
- S3 encryption enabled
- Versioning enabled
- Public access blocked
- Not exposed in artifacts

✅ **Secrets**
- GitHub Secrets used properly
- Masked in logs
- Gitleaks detects exposed secrets

✅ **Code**
- Pre-commit hooks scan for secrets
- No credentials in git history
- Code review required

### What You Must Not Do

❌ Don't hardcode AWS credentials
❌ Don't commit secrets to git
❌ Don't skip approval gates
❌ Don't make manual AWS changes without updating Terraform
❌ Don't share GitHub tokens or AWS credentials

---

## ✅ Production Ready

This setup is **production-grade**:

- ✅ Security: OIDC, least-privilege IAM, encrypted state
- ✅ Safety: Plan review, approval gates, drift detection
- ✅ Reliability: Remote state, locking, versioning
- ✅ Observability: Audit trail, drift alerts, logs
- ✅ Maintainability: Code structure, documentation

---

## 🎯 Key Principles

1. **Single Source of Truth**
   - One workflow: `orchestrate.yml`
   - All deployments follow same process

2. **Manual Control**
   - No automatic deployments
   - Every deployment is intentional

3. **Plan Review**
   - Changes visible before apply
   - Mistakes caught early

4. **Approval Gates**
   - Explicit approval required
   - Audit trail maintained

5. **Drift Detection**
   - Monitor for manual changes
   - Prevent configuration drift

6. **Security First**
   - No hardcoded credentials
   - Least-privilege access
   - Encrypted state storage

---

**Last Updated:** 2026-09-29
**Status:** Production Ready ✅
**Questions?** See FAQ section above
