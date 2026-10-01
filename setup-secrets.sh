#!/bin/bash

# Create AWS Secrets Manager secrets for database credentials

AWS_REGION="us-east-1"
SECRET_NAME_DEV="microservices-db-credentials-dev"
SECRET_NAME_PROD="microservices-db-credentials-prod"

# Default credentials (change these!)
DB_USERNAME="admin"
DB_PASSWORD="ChangeMe123!@#"

echo "Creating AWS Secrets Manager secrets..."

# Create Dev secret
echo "Creating $SECRET_NAME_DEV..."
aws secretsmanager create-secret \
  --name "$SECRET_NAME_DEV" \
  --description "Database credentials for dev environment" \
  --secret-string "{\"username\":\"$DB_USERNAME\",\"password\":\"$DB_PASSWORD\"}" \
  --region "$AWS_REGION" \
  2>/dev/null || echo "Dev secret already exists or error occurred"

# Create Prod secret
echo "Creating $SECRET_NAME_PROD..."
aws secretsmanager create-secret \
  --name "$SECRET_NAME_PROD" \
  --description "Database credentials for prod environment" \
  --secret-string "{\"username\":\"$DB_USERNAME\",\"password\":\"$DB_PASSWORD\"}" \
  --region "$AWS_REGION" \
  2>/dev/null || echo "Prod secret already exists or error occurred"

echo "✅ Secrets setup complete!"
echo ""
echo "⚠️  IMPORTANT: Update the passwords in AWS Secrets Manager!"
echo "Dev:  aws secretsmanager update-secret --secret-id $SECRET_NAME_DEV --secret-string '{\"username\":\"admin\",\"password\":\"YOUR_NEW_PASSWORD\"}'"
echo "Prod: aws secretsmanager update-secret --secret-id $SECRET_NAME_PROD --secret-string '{\"username\":\"admin\",\"password\":\"YOUR_NEW_PASSWORD\"}'"
