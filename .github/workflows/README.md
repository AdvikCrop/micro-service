# GitHub Actions Workflows

## 🎯 Single Source of Truth

**All deployments use:** `orchestrate.yml` (Manual workflow dispatch)

**Automated:** None. All deployments require explicit trigger.

---

## Active Workflows

### 1. **orchestrate.yml** ⭐ PRIMARY
**Name:** Complete CI/CD Orchestration

**Trigger:** Workflow dispatch (manual trigger required)

**Purpose:** Master pipeline for all CI/CD operations

**Stages:**
1. Validate (Terraform + Python linting)
2. Test (Unit tests)
3. **Terraform Plan** (Comprehensive planning)
4. **Terraform Drift Detection** (Infrastructure drift check)
5. Build Docker Images (Multi-service)
6. Security Scanning (Trivy + Bandit)
7. Deploy Infrastructure (Manual approval)
8. Deploy Application (Manual approval)

**Parameters:**
- `terraform_plan`: Enable/disable Terraform planning (default: true)
- `deploy_infrastructure`: Deploy infra changes (default: false)
- `infra_action`: plan or apply (default: plan)
- `infra_environment`: dev or prod (default: dev)
- `build_services`: all, user-service, order-service (default: all)
- `deploy_application`: Deploy apps (default: false)
- `app_environment`: dev or prod (default: dev)
- `run_tests`: Run unit tests (default: true)
- `run_security_scan`: Run security scans (default: true)

**When to Use:**
- ✅ All infrastructure changes
- ✅ All application deployments
- ✅ Terraform updates
- ✅ Complete end-to-end deployments

**Example Trigger:**
```bash
gh workflow run orchestrate.yml \
  -f terraform_plan=true \
  -f deploy_infrastructure=true \
  -f infra_action=apply \
  -f infra_environment=prod \
  -f deploy_application=true
```

---

### 2. **terraform-scheduled-drift.yml**
**Name:** Scheduled Terraform Drift Detection

**Trigger:** 
- Schedule: Every 6 hours (cron: `0 */6 * * *`)
- Manual: Workflow dispatch

**Purpose:** Monitor infrastructure drift outside deployment window

**Detects:**
- Manual changes to AWS resources
- Configuration drift from Terraform state
- Unintended infrastructure modifications

**When Used:**
- ✅ Automatically every 6 hours
- ✅ Manual trigger for immediate drift check
- ✅ Detect changes made outside Terraform

---

### 3. **build-image.yml** (Standalone)
**Name:** Build Docker Images

**Trigger:** Push to main

**Purpose:** Build Docker images for microservices

**Note:** This is standalone and is called by `orchestrate.yml`. You typically don't trigger this directly unless you need to build images without full pipeline.

---

### 4. **deploy-app.yml** (Standalone)
**Name:** Deploy Application

**Trigger:** Push to main

**Purpose:** Deploy application to EKS

**Note:** This is standalone. It's orchestrated by `orchestrate.yml`. Trigger directly only if needed for app-only deployment.

---

### 5. **deploy-infra.yml** (Legacy)
**Name:** Deploy Infrastructure

**Trigger:** Workflow dispatch only

**Purpose:** Deprecated - use `orchestrate.yml` instead

**Why Deprecated:**
- Replaced by comprehensive `orchestrate.yml`
- Less visibility into plan before apply
- No drift detection
- Use `orchestrate.yml` for all infrastructure deployments

---

## 🚀 How to Trigger Workflows

### Via GitHub UI (Recommended)

1. Go to **Actions** tab
2. Select workflow from left sidebar
3. Click **"Run workflow"**
4. Fill in parameters
5. Click **"Run workflow"**

### Via GitHub CLI

```bash
# Complete orchestration
gh workflow run orchestrate.yml \
  -f terraform_plan=true \
  -f deploy_infrastructure=true

# Just Terraform plan
gh workflow run orchestrate.yml \
  -f terraform_plan=true \
  -f deploy_infrastructure=false

# Just drift detection
gh workflow run terraform-scheduled-drift.yml
```

---

## 📋 Typical Deployment Workflow

### Step 1: Prepare Changes
```bash
git checkout -b feature/my-change
# ... make changes ...
git commit -m "Add feature"
git push origin feature/my-change
```

### Step 2: Create Pull Request
- GitHub Actions automatically runs validation
- Terraform plan generated
- Drift detection runs
- Security scans run
- Review approval needed

### Step 3: Merge to Main
- Approval given
- Code merged to main

### Step 4: Deploy (Manual)
- Go to Actions → "Complete CI/CD Orchestration"
- Click "Run workflow"
- Configure options
- Click "Run workflow"
- Monitor pipeline progress

### Step 5: Approve Environment
- Wait for Terraform plan step
- Review artifacts
- Click "Approve" when ready
- Infrastructure deployed

---

## ⚙️ Workflow Parameters Guide

| Parameter | Options | Default | Use Case |
|-----------|---------|---------|----------|
| `terraform_plan` | true / false | true | Include Terraform plan stage |
| `deploy_infrastructure` | true / false | false | Deploy infrastructure changes |
| `infra_action` | plan / apply | plan | plan=dry-run, apply=execute |
| `infra_environment` | dev / prod | dev | Target environment |
| `build_services` | all / user-service / order-service | all | Which services to build |
| `deploy_application` | true / false | false | Deploy applications |
| `app_environment` | dev / prod | dev | Target app environment |
| `run_tests` | true / false | true | Run unit tests |
| `run_security_scan` | true / false | true | Run security scanning |

---

## 🔒 Safety Features

### Terraform Plan Review
```
Push code
  ↓
Terraform plan generated
  ↓
Developer reviews plan
  ↓
Must approve before apply
```

### Infrastructure Drift Detection
```
Every 6 hours (automatic)
  ↓
Compare Terraform config to AWS
  ↓
Detect any manual changes
  ↓
Alert on drift
```

### Environment Approvals
```
Manual approval required for:
- Dev environment deployments (optional)
- Prod environment deployments (required)
```

### Read-Only PR Validation
```
Pull Request triggers:
- ✅ Terraform validation
- ✅ Terraform plan (no apply)
- ✅ Drift detection
- ✅ Unit tests
- ✅ Security scan
- ❌ NO infrastructure changes
```

---

## ⚠️ Important Notes

### No Automatic Deployments
- ❌ Push to main does NOT auto-deploy
- ✅ Workflow dispatch must be triggered manually
- ✅ Approval gates required

### Terraform Changes Require Review
- ❌ No auto-apply
- ✅ Plan review required
- ✅ Manual approval required
- ✅ Drift detection before apply

### Production Deployments
- ❌ Cannot be auto-deployed
- ✅ Require explicit trigger
- ✅ Require environment approval
- ✅ Visible in Actions logs

---

## 🆘 Troubleshooting

### Workflow not showing in list
- Ensure file is in `.github/workflows/`
- Check file extension is `.yml` or `.yaml`
- Ensure YAML syntax is valid

### Plan always shows changes
- Check if Terraform state is correct
- Run `terraform refresh` locally
- Verify backend configuration

### Drift detection keeps alerting
- Investigate AWS changes
- Update Terraform config OR
- Run `terraform apply` to sync

### Approval not showing
- Check environment is configured
- Verify required reviewers set
- Check branch protection rules

---

## 📚 Additional Documentation

- `WORKFLOW_CONSOLIDATION.md` - Why we use single source of truth
- `TERRAFORM_DRIFT_IMPLEMENTATION.md` - Terraform + drift details
- `TERRAFORM_QUICK_START.md` - Quick reference guide
- `TERRAFORM_SETUP_GUIDE.md` - AWS setup instructions

---

**Last Updated:** 2026-09-29

**Key Principle:** Manual control over all deployments. No automatic changes to production.
