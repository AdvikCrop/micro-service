#!/bin/bash

set -e

ENVIRONMENT="${1:-dev}"
TF_DIR="terraform/environments/${ENVIRONMENT}"

if [ ! -d "$TF_DIR" ]; then
    echo "✗ Environment directory not found: $TF_DIR"
    exit 1
fi

echo "Deploying to ${ENVIRONMENT} environment..."

cd "$TF_DIR"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init \
    -backend-config="bucket=microservices-state-${ENVIRONMENT}" \
    -backend-config="key=terraform.tfstate" \
    -backend-config="region=us-east-1" \
    -backend-config="dynamodb_table=microservices-locks"

# Validate configuration
echo "Validating Terraform configuration..."
terraform validate

# Plan deployment
echo "Planning deployment..."
terraform plan -out=tfplan

# Ask for confirmation
read -p "Do you want to apply these changes? (yes/no) " -n 3 -r
echo
if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Applying changes..."
    terraform apply tfplan
    echo "✓ Deployment complete!"
    echo ""
    echo "Outputs:"
    terraform output
else
    echo "Deployment cancelled"
fi

cd - > /dev/null
