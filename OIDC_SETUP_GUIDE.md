# AWS OIDC Provider Setup Guide

Complete step-by-step guide to set up OIDC (OpenID Connect) for GitHub Actions authentication with AWS.

**Your Bucket:** `advik-crop`

---

## What is OIDC?

OIDC allows GitHub Actions to authenticate with AWS **without using long-lived access keys**. Instead:
- GitHub creates a temporary JWT token
- AWS validates the token
- GitHub Actions gets temporary credentials
- Credentials auto-expire after 1 hour

**Benefits:**
- ✅ No AWS access keys stored in GitHub
- ✅ More secure
- ✅ Automatic credential rotation
- ✅ Better audit trail

---

## Prerequisites

Before starting, you need:
1. AWS CLI installed on your machine
2. AWS account with admin access
3. GitHub repository URL
4. Your AWS Account ID

**Get your AWS Account ID:**
```bash
aws sts get-caller-identity

# Output will show:
# {
#     "UserId": "AIDAI...",
#     "Account": "123456789012",     <-- THIS IS YOUR ACCOUNT ID
#     "Arn": "arn:aws:iam::123456789012:root"
# }
```

Save your Account ID: `______________`

---

## Step 1: Create OIDC Provider in AWS

This registers GitHub as a trusted identity provider with AWS.

### **Command:**
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --region us-east-1
```

### **What it does:**
- Creates trust relationship between GitHub and AWS
- Allows GitHub to request temporary credentials
- Registers GitHub's certificate thumbprint

### **Expected output:**
```json
{
    "OpenIDConnectProviderArn": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
}
```

### **Save this ARN:** `______________`
(You'll need it in the next step)

---

## Step 2: Create Trust Policy JSON File

Create a file called `trust-policy.json` with the following content:

```bash
cat > trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/YOUR_REPO:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF
```

### **Replace these values:**
1. `YOUR_ACCOUNT_ID` - Your 12-digit AWS Account ID
2. `YOUR_GITHUB_ORG` - Your GitHub organization/username
3. `YOUR_REPO` - Your repository name

### **Example (for your case):**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:sushildeep/micro-service:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF
```

**Note:** Replace `sushildeep/micro-service` with your actual GitHub org/repo path

---

## Step 3: Create IAM Role

### **Command:**
```bash
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file://trust-policy.json \
  --region us-east-1
```

### **Expected output:**
```json
{
    "Role": {
        "RoleName": "GitHubActionsRole",
        "Arn": "arn:aws:iam::123456789012:role/GitHubActionsRole",
        ...
    }
}
```

### **Save this ARN:** `arn:aws:iam::123456789012:role/GitHubActionsRole`
(This is your `AWS_ROLE_TO_ASSUME` secret for GitHub)

---

## Step 4: Create and Attach IAM Policy

### **Step 4a: Create Policy File**

```bash
cat > github-actions-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3StateAccess",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetBucketVersioning",
        "s3:ListBucketVersions"
      ],
      "Resource": [
        "arn:aws:s3:::advik-crop-terraform-state-*",
        "arn:aws:s3:::advik-crop-terraform-state-*/*"
      ]
    },
    {
      "Sid": "DynamoDBLocking",
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:*:table/advik-crop-terraform-locks"
    },
    {
      "Sid": "ECRAccess",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:CreateRepository",
        "ecr:DescribeRepositories"
      ],
      "Resource": "arn:aws:ecr:us-east-1:*:repository/*"
    },
    {
      "Sid": "EKSAccess",
      "Effect": "Allow",
      "Action": [
        "eks:DescribeClusters",
        "eks:ListClusters",
        "eks:DescribeNodegroup",
        "eks:ListNodegroups"
      ],
      "Resource": "arn:aws:eks:us-east-1:*:cluster/*"
    },
    {
      "Sid": "TerraformFullAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "rds:*",
        "iam:*",
        "s3:*",
        "cloudformation:*",
        "logs:*",
        "sns:*",
        "sqs:*",
        "kms:*",
        "autoscaling:*",
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
```

### **Step 4b: Attach Policy to Role**

```bash
aws iam put-role-policy \
  --role-name GitHubActionsRole \
  --policy-name GitHubActionsPolicy \
  --policy-document file://github-actions-policy.json
```

### **Verify it was attached:**
```bash
aws iam get-role-policy \
  --role-name GitHubActionsRole \
  --policy-name GitHubActionsPolicy
```

---

## Step 5: Create S3 Buckets for Terraform State

### **Create Dev Bucket:**
```bash
aws s3api create-bucket \
  --bucket advik-crop-terraform-state-dev \
  --region us-east-1 \
  --acl private

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket advik-crop-terraform-state-dev \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket advik-crop-terraform-state-dev \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket advik-crop-terraform-state-dev \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

### **Create Prod Bucket:**
```bash
aws s3api create-bucket \
  --bucket advik-crop-terraform-state-prod \
  --region us-east-1 \
  --acl private

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket advik-crop-terraform-state-prod \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket advik-crop-terraform-state-prod \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket advik-crop-terraform-state-prod \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

### **Verify buckets were created:**
```bash
aws s3 ls

# Should show:
# 2024-09-30 12:00:00 advik-crop-terraform-state-dev
# 2024-09-30 12:00:00 advik-crop-terraform-state-prod
```

---

## Step 6: Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
  --table-name advik-crop-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### **Verify table was created:**
```bash
aws dynamodb describe-table \
  --table-name advik-crop-terraform-locks
```

---

## Step 7: Add GitHub Secrets

Now add these secrets to your GitHub repository:

**Location:** GitHub → Settings → Secrets and variables → Actions → New repository secret

### **Secret 1: AWS_ACCOUNT_ID**
- **Name:** `AWS_ACCOUNT_ID`
- **Value:** Your 12-digit AWS Account ID (e.g., `123456789012`)
- **Click:** Add secret

### **Secret 2: AWS_ROLE_TO_ASSUME**
- **Name:** `AWS_ROLE_TO_ASSUME`
- **Value:** `arn:aws:iam::123456789012:role/GitHubActionsRole` (replace with YOUR account ID)
- **Click:** Add secret

### **Secret 3: TERRAFORM_STATE_BUCKET**
- **Name:** `TERRAFORM_STATE_BUCKET`
- **Value:** `advik-crop-terraform-state-prod`
- **Click:** Add secret

### **Secret 4: TERRAFORM_LOCK_TABLE**
- **Name:** `TERRAFORM_LOCK_TABLE`
- **Value:** `advik-crop-terraform-locks`
- **Click:** Add secret

### **Screenshot Guide:**
```
GitHub Dashboard
↓
Repository Settings
↓
Secrets and variables
↓
Actions
↓
New repository secret (green button)
↓
Enter Name and Value
↓
Add secret
```

---

## Step 8: Verify OIDC Setup

### **Check OIDC Provider:**
```bash
aws iam list-open-id-connect-providers

# Should show:
# {
#     "OpenIDConnectProviderList": [
#         {
#             "Arn": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
#         }
#     ]
# }
```

### **Check IAM Role:**
```bash
aws iam get-role --role-name GitHubActionsRole

# Should show role details with ARN
```

### **Check Role Policy:**
```bash
aws iam get-role-policy \
  --role-name GitHubActionsRole \
  --policy-name GitHubActionsPolicy

# Should show policy JSON
```

### **Check S3 Buckets:**
```bash
aws s3 ls | grep advik-crop

# Should show:
# 2024-09-30 12:00:00 advik-crop-terraform-state-dev
# 2024-09-30 12:00:00 advik-crop-terraform-state-prod
```

### **Check DynamoDB Table:**
```bash
aws dynamodb describe-table \
  --table-name advik-crop-terraform-locks

# Should show table description
```

---

## Step 9: Test OIDC Authentication

### **Create Test Workflow File:**

Create `.github/workflows/test-oidc.yml`:

```yaml
name: Test OIDC Setup

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
          aws-region: us-east-1

      - name: Test S3 Access
        run: |
          echo "Testing S3 bucket access..."
          aws s3 ls advik-crop-terraform-state-dev
          echo "✅ S3 access successful!"

      - name: Test DynamoDB Access
        run: |
          echo "Testing DynamoDB access..."
          aws dynamodb describe-table --table-name advik-crop-terraform-locks
          echo "✅ DynamoDB access successful!"

      - name: Get AWS Account ID
        run: |
          aws sts get-caller-identity
```

### **Run the test:**
1. Push the workflow file to GitHub
2. Go to GitHub → Actions → Test OIDC Setup
3. Click "Run workflow"
4. Check if it succeeds

**If it succeeds:** ✅ OIDC is properly configured!
**If it fails:** Check the error logs and troubleshooting section below.

---

## Troubleshooting

### **Error: "User: arn:aws:iam::... is not authorized"**

**Cause:** Policy not attached or incorrect

**Solution:**
```bash
# Re-attach the policy
aws iam put-role-policy \
  --role-name GitHubActionsRole \
  --policy-name GitHubActionsPolicy \
  --policy-document file://github-actions-policy.json
```

---

### **Error: "InvalidParameterException: Invalid token"**

**Cause:** Trust policy doesn't match your repository

**Solution:**
1. Verify `repo:YOUR_GITHUB_ORG/YOUR_REPO` in trust-policy.json matches your actual repo
2. Update the trust policy:
```bash
aws iam update-assume-role-policy \
  --role-name GitHubActionsRole \
  --policy-document file://trust-policy.json
```

---

### **Error: "NoSuchBucket"**

**Cause:** S3 bucket name incorrect or not created

**Solution:**
```bash
# Check bucket names
aws s3 ls

# Create if missing
aws s3api create-bucket \
  --bucket advik-crop-terraform-state-dev \
  --region us-east-1
```

---

### **Error: "ResourceNotFoundException: Requested resource not found"** (DynamoDB)

**Cause:** DynamoDB table doesn't exist

**Solution:**
```bash
# Create the table
aws dynamodb create-table \
  --table-name advik-crop-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

---

### **Error: "AccessDenied" on S3**

**Cause:** Trust policy or role not properly set up

**Solution:**
```bash
# Check trust policy
aws iam get-role --role-name GitHubActionsRole

# Verify it has the OIDC provider in Principal
# Should show: "Federated": "arn:aws:iam::...:oidc-provider/token.actions.githubusercontent.com"
```

---

## Complete Setup Summary

| Step | Component | Status | Notes |
|------|-----------|--------|-------|
| 1 | OIDC Provider | ✅ | Created in AWS IAM |
| 2 | Trust Policy | ✅ | Created in trust-policy.json |
| 3 | IAM Role | ✅ | GitHubActionsRole created |
| 4 | IAM Policy | ✅ | Attached to role |
| 5 | S3 Buckets | ✅ | advik-crop-terraform-state-dev/prod |
| 6 | DynamoDB | ✅ | advik-crop-terraform-locks |
| 7 | GitHub Secrets | ✅ | 4 secrets added |
| 8 | Verification | ✅ | All components verified |
| 9 | Test Workflow | ✅ | OIDC tested successfully |

---

## Quick Reference - Your Configuration

**For your setup with bucket "advik-crop":**

```
AWS Account ID: 123456789012 (Replace with your actual ID)
OIDC Provider: token.actions.githubusercontent.com
IAM Role: GitHubActionsRole
IAM Role ARN: arn:aws:iam::123456789012:role/GitHubActionsRole

S3 Buckets:
  - Dev: advik-crop-terraform-state-dev
  - Prod: advik-crop-terraform-state-prod

DynamoDB Table: advik-crop-terraform-locks

GitHub Secrets:
  - AWS_ACCOUNT_ID: 123456789012
  - AWS_ROLE_TO_ASSUME: arn:aws:iam::123456789012:role/GitHubActionsRole
  - TERRAFORM_STATE_BUCKET: advik-crop-terraform-state-prod
  - TERRAFORM_LOCK_TABLE: advik-crop-terraform-locks
```

---

## Next Steps

1. ✅ Complete all setup steps above
2. ✅ Run test workflow to verify
3. ✅ Update your Terraform backend config with bucket names
4. ✅ Add the 4 GitHub secrets
5. ✅ Run your orchestrate.yml pipeline

---

**Support:**
If you encounter issues, check the Troubleshooting section or run verification commands above.

Good luck! 🚀
