# GitHub Actions Workflows

## 🎯 Architecture Summary

**Active Workflows:** 2 (DRY principle)
**Architecture Type:** Single source of truth for CI/CD logic
**Status:** Consolidated and optimized

---

## Active Workflows

### 1. **orchestrate.yml** ⭐ PRIMARY
**Name:** Complete CI/CD Orchestration

**Trigger:** Workflow dispatch (manual trigger required)

**Purpose:** Master pipeline for all CI/CD operations - single source of truth

**Stages:**
1. Validate (Terraform + Python linting)
2. Test (Unit tests with database services)
3. **Terraform Plan** (Comprehensive planning)
4. **Terraform Drift Detection** (Infrastructure drift check)
5. Build Docker Images (Multi-service, ECR push)
6. Security Scanning (Trivy + Bandit)
7. Deploy Infrastructure (Optional, manual approval)
8. Deploy Application (Optional, manual approval)

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
- `helm_timeout`: Helm deployment timeout (default: 10m)
- `wait_for_rollout`: Wait for Kubernetes rollout (default: true)

**When to Use:**
- ✅ All infrastructure changes
- ✅ All application deployments
- ✅ Terraform updates
- ✅ Complete end-to-end deployments
- ✅ Manual validation and testing

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
- Schedule: Every 12 hours (cron: `0 */12 * * *`)
- Manual: Workflow dispatch

**Purpose:** Monitor infrastructure drift outside deployment window

**Detects:**
- Manual changes to AWS resources
- Configuration drift from Terraform state
- Unintended infrastructure modifications

**When Used:**
- ✅ Automatically every 12 hours
- ✅ Manual trigger for immediate drift check
- ✅ Detect changes made outside Terraform

**Safety Features:**
- Read-only operations (terraform refresh + plan)
- No terraform apply
- Logs uploaded as artifacts
- Reports drift status clearly

---

## 🗑️ Removed Workflows

The following workflows have been **consolidated into `orchestrate.yml`**:

- ❌ `build-image.yml` - Consolidated into orchestrate.yml (stage 5)
- ❌ `deploy-app.yml` - Consolidated into orchestrate.yml (stage 6)
- ❌ `deploy-infra.yml` - Consolidated into orchestrate.yml (stage 5)

**Reason for Consolidation:**
- Eliminate duplication
- Single source of truth
- Unified configuration
- Easier maintenance
- Clearer visibility into full pipeline

---

## 🏗️ Composite Actions

All heavy lifting is done via reusable composite actions:

### 1. `.github/actions/build-and-push-image/`
**Purpose:** Build Docker image and push to ECR

**Inputs:**
- `aws-account-id` (required)
- `aws-region` (default: us-east-1)
- `service-name` (required)
- `dockerfile-path` (required)
- `image-tag` (required)
- `aws-role-to-assume` (required)
- `environment-tag` (default: latest)

**Outputs:**
- `image-uri` - Full ECR image URI
- `image-digest` - Image digest

---

### 2. `.github/actions/deploy-application/`
**Purpose:** Deploy microservices to EKS using Helm

**Inputs:**
- `aws-account-id` (required)
- `aws-region` (default: us-east-1)
- `cluster-name` (required)
- `environment` (required - dev/prod)
- `helm-chart-path` (default: ./helm)
- `helm-release-name` (default: microservices-app)
- `helm-namespace` (default: default)
- `helm-values-file` (required)
- `user-service-image-tag` (required)
- `order-service-image-tag` (required)
- `aws-role-to-assume` (required)
- `helm-timeout` (default: 10m)
- `wait-for-rollout` (default: true)

**Outputs:**
- `deployment-status` - Deployment result
- `helm-release-version` - Release revision

---

### 3. `.github/actions/deploy-infrastructure/`
**Purpose:** Initialize, plan, and apply Terraform infrastructure

**Inputs:**
- `aws-account-id` (required)
- `aws-region` (default: us-east-1)
- `terraform-version` (default: 1.5.0)
- `environment` (required - dev/prod)
- `terraform-dir` (default: terraform/environments)
- `tfvars-file` (required)
- `aws-role-to-assume` (required)
- `state-bucket` (required)
- `state-key` (required)
- `action` (default: plan - can be apply)

**Outputs:**
- `plan-exists` - Whether changes detected
- `apply-summary` - Apply results summary

---

## 🚀 How to Trigger Workflows

### Via GitHub UI (Recommended)

1. Go to **Actions** tab
2. Select **"Complete CI/CD Orchestration"** or **"Scheduled Terraform Drift Detection"**
3. Click **"Run workflow"**
4. Fill in parameters
5. Click **"Run workflow"**

### Via GitHub CLI

```bash
# Complete orchestration (build + test + plan + deploy)
gh workflow run orchestrate.yml \
  -f terraform_plan=true \
  -f deploy_infrastructure=true \
  -f infra_action=apply \
  -f deploy_application=true

# Just validation (no deployment)
gh workflow run orchestrate.yml \
  -f terraform_plan=true \
  -f deploy_infrastructure=false \
  -f deploy_application=false

# Terraform plan only (dev)
gh workflow run orchestrate.yml \
  -f terraform_plan=true \
  -f deploy_infrastructure=false \
  -f deploy_application=false \
  -f build_images=false \
  -f run_tests=false

# Manual drift detection
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
- Create PR on GitHub
- Review changes

### Step 3: Merge to Main
- Approval given
- Code merged to main

### Step 4: Deploy (Manual)
- Go to Actions → "Complete CI/CD Orchestration"
- Click "Run workflow"
- Configure options:
  - `terraform_plan=true` (plan infrastructure changes)
  - `build_images=true` (build services)
  - `deploy_infrastructure=true` (deploy infra)
  - `infra_action=apply` (actually apply, not just plan)
  - `deploy_application=true` (deploy services)
- Click "Run workflow"
- Monitor pipeline progress

### Step 5: Approve Environment
- Wait for deployment job to reach approval gate
- Review artifacts (Terraform plan)
- Click "Approve" when ready
- Infrastructure deployed
- Application deployed
- Smoke tests run
- Deployment complete

---

## 🔄 Scheduled Drift Detection

**Automatic:** Runs every 12 hours automatically

**Manual:** Can trigger anytime from Actions tab

**What It Checks:**
- Compares actual AWS resources to Terraform state
- Detects manual changes
- Reports drift status

**What It Does NOT Do:**
- Apply changes
- Modify infrastructure
- Override Terraform

---

## ⚙️ Workflow Parameters Reference

| Parameter | Options | Default | Use Case |
|-----------|---------|---------|----------|
| `terraform_plan` | true / false | true | Include Terraform plan stage |
| `deploy_infrastructure` | true / false | false | Deploy infrastructure changes |
| `infra_action` | plan / apply | plan | plan=dry-run, apply=execute |
| `infra_environment` | dev / prod | dev | Target environment |
| `build_services` | all / user-service / order-service | all | Which services to build |
| `build_images` | true / false | true | Build Docker images |
| `deploy_application` | true / false | false | Deploy applications |
| `app_environment` | dev / prod | dev | Target app environment |
| `run_tests` | true / false | true | Run unit tests |
| `run_security_scan` | true / false | true | Run security scanning (Trivy + Bandit) |
| `helm_timeout` | 5m / 10m / 15m / 20m | 10m | Helm deployment timeout |
| `wait_for_rollout` | true / false | true | Wait for Kubernetes rollout to complete |

---

## 🔒 Safety Features

### Manual Control
- ❌ NO automatic deployments on push
- ✅ Explicit workflow dispatch required
- ✅ All changes require manual trigger

### Terraform Plan Review
```
Trigger orchestrate.yml
  ↓
Terraform plan generated
  ↓
Upload plan artifact
  ↓
Must approve (for apply action)
```

### Infrastructure Drift Detection
```
Scheduled: Every 12 hours
  ↓
Refresh state and detect drift
  ↓
Upload drift log
  ↓
Alert if drift detected
```

### Environment Approvals
```
Manual approval required for:
- Dev environment deployments (optional)
- Prod environment deployments (required)
```

### Read-Only PR Validation
- ❌ Workflows do NOT auto-trigger on pull_request
- ✅ Manual dispatch only
- ✅ No production credential exposure to forks

---

## 📊 Workflow Status and Outputs

### Terraform Plan Output
- Resource additions, modifications, deletions
- Plan file uploaded as artifact
- Available for 7 days

### Security Scan Output
- Trivy vulnerability scan (SARIF format)
- Bandit SAST results (JSON format)
- Uploaded to GitHub Security tab

### Deployment Output
- Helm release version
- Pod status
- Service endpoints
- Ingress information

### Drift Detection Output
- Drift status (NO_DRIFT / DRIFT_DETECTED)
- Drift log uploaded as artifact
- Available for 30 days

---

## ⚠️ Important Notes

### No Automatic Deployments
- ❌ Push to main does NOT auto-deploy
- ✅ Workflow dispatch must be triggered manually
- ✅ Approval gates protect production

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
- ✅ All changes audited

### State Management
- Terraform state stored in S3 with encryption
- DynamoDB table for state locking
- Credentials managed via AWS OIDC
- No long-lived secrets stored

---

## 🆘 Troubleshooting

### Workflow not triggering
- Check Actions tab is enabled
- Verify workflow file YAML syntax
- Ensure correct branch (main/develop)

### Action not found error
- Verify action path exists: `.github/actions/{action-name}/action.yml`
- Ensure `uses:` reference matches directory name
- Check for trailing slash in `uses:` path

### Terraform plan shows unexpected changes
- Check if Terraform state is current
- Run `terraform refresh` locally to sync
- Verify backend configuration matches

### Drift detection keeps alerting
- Investigate AWS changes
- Update Terraform config to match actual state OR
- Run `terraform apply` to sync

### Approval not showing
- Check environment protection rule is configured
- Verify required reviewers are set
- Check branch protection rules

---

## 📚 Architecture Decisions

### Why Single orchestrate.yml Workflow?

1. **Single Source of Truth** - All CI/CD logic in one place
2. **Clear Dependencies** - Job ordering explicit
3. **Unified Visibility** - See full pipeline at a glance
4. **Easier Maintenance** - Changes in one location
5. **Parameter Control** - Choose what runs via inputs

### Why Keep Separate Drift Workflow?

1. **Different Trigger** - Scheduled vs. manual
2. **Independent Operation** - Not part of deployment cycle
3. **Separate Responsibility** - Monitoring vs. deployment
4. **Clear Intent** - Purpose obvious from name

### Why Consolidate Three Workflows?

1. **Eliminated Duplication** - Build, app deploy, infra deploy logic was replicated
2. **Unified Parameters** - Single control point for all options
3. **Clear Sequencing** - Job dependencies explicit
4. **Reduced Maintenance** - Fix once, applies everywhere

---

## 🔄 Migration from Old Workflows

### Old Way (5 workflows)
- `build-image.yml` - Auto-build on push
- `deploy-app.yml` - Auto-deploy after build
- `deploy-infra.yml` - Manual infrastructure deploy
- `orchestrate.yml` - Manual complete pipeline
- `terraform-scheduled-drift.yml` - Scheduled drift

**Problems:**
- ❌ Duplication (orchestrate contained all logic)
- ❌ Auto-deployment contradicted manual-only policy
- ❌ Drift detection in two places
- ❌ Complex to maintain

### New Way (2 workflows)
- `orchestrate.yml` - Single master pipeline (manual)
- `terraform-scheduled-drift.yml` - Scheduled drift (automated)

**Benefits:**
- ✅ No duplication
- ✅ Clear intent
- ✅ Single source of truth
- ✅ Easier maintenance

---

**Last Updated:** 2026-09-30

**Key Principle:** Single source of truth for CI/CD logic. All deployments are manual and require explicit authorization. Scheduled drift detection runs independently.
