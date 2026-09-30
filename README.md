# Microservices Project

A production-ready microservices architecture with two independent services (User & Order) running on AWS ECS Fargate with PostgreSQL databases, complete with CI/CD pipeline, IaC via Terraform, and comprehensive testing.

## 📋 Project Structure

```
microservices-project/
├── services/
│   ├── user-service/          # User management microservice
│   │   ├── app/
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   └── order-service/         # Order management microservice
│       ├── app/
│       ├── tests/
│       ├── Dockerfile
│       └── requirements.txt
├── terraform/                 # Infrastructure as Code
│   ├── modules/               # Reusable Terraform modules
│   │   ├── networking/        # VPC, Subnets, Security Groups
│   │   ├── rds/               # PostgreSQL Databases
│   │   └── ecs/               # ECS Cluster & Services
│   └── environments/          # Environment-specific configs
│       ├── dev/
│       └── prod/
├── docker-compose.yml         # Local development setup
├── .gitlab-ci.yml             # CI/CD Pipeline
├── scripts/                   # Helper scripts
└── README.md
```

## 🏗️ Architecture

### Microservices
- **User Service**: Manages users (CRUD operations)
  - FastAPI framework
  - PostgreSQL database
  - Health check: `/health/`
  - Readiness check: `/health/ready`

- **Order Service**: Manages orders
  - FastAPI framework
  - PostgreSQL database
  - Order status management
  - Health check: `/health/`
  - Readiness check: `/health/ready`

### Infrastructure
- **AWS ECS Fargate**: Container orchestration (serverless)
- **Application Load Balancer**: Traffic distribution
- **RDS PostgreSQL**: Two separate databases (users & orders)
- **VPC**: Network isolation with public/private subnets
- **AWS Secrets Manager**: Credentials management
- **CloudWatch**: Logging & monitoring

### CI/CD Pipeline
GitLab CI with stages:
1. **Validate**: Linting & Terraform validation
2. **Test**: Unit tests with coverage reporting
3. **Build**: Docker image creation & registry push
4. **Security Scan**: Trivy container scanning & SAST
5. **Deploy Dev**: Manual deployment to dev
6. **Deploy Prod**: Manual deployment to prod (main branch only)

## 🚀 Quick Start

### Local Development Setup

#### Prerequisites
- Docker & Docker Compose
- Python 3.11+
- Git

#### 1. Clone & Setup
```bash
# Setup environment
bash scripts/setup.sh

# Edit .env with your configuration
# (Already created by setup.sh)
```

#### 2. Start Services
```bash
docker-compose up -d
```

This starts:
- User Service on `http://localhost:8001`
- Order Service on `http://localhost:8002`
- PostgreSQL database for users on port 5432
- PostgreSQL database for orders on port 5433

#### 3. Verify Services
```bash
# Check health
curl http://localhost:8001/health/
curl http://localhost:8002/health/

# Check readiness
curl http://localhost:8001/health/ready
curl http://localhost:8002/health/ready
```

#### 4. Test Endpoints

**Create a user:**
```bash
curl -X POST http://localhost:8001/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "name": "John Doe"}'
```

**Get user:**
```bash
curl http://localhost:8001/api/v1/users/1
```

**List users:**
```bash
curl http://localhost:8001/api/v1/users
```

**Create an order:**
```bash
curl -X POST http://localhost:8002/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "product_name": "Laptop",
    "quantity": 1,
    "price": 999.99
  }'
```

### Docker Commands

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f user-service
docker-compose logs -f order-service

# Stop services
docker-compose down

# Remove volumes (reset databases)
docker-compose down -v

# Rebuild images
docker-compose build --no-cache

# Run tests
docker-compose exec user-service pytest tests/
docker-compose exec order-service pytest tests/
```

## 🧪 Testing

### Run Tests Locally
```bash
cd services/user-service
pip install -r requirements.txt
pytest tests/ -v --cov=app

cd ../order-service
pytest tests/ -v --cov=app
```

### Run Tests in Docker
```bash
docker-compose exec user-service pytest tests/ -v
docker-compose exec order-service pytest tests/ -v
```

## 🔄 GitLab CI/CD Pipeline

### Pipeline Stages

1. **Validate**
   - Linting with flake8
   - Code formatting check with black
   - Terraform validation

2. **Test**
   - Unit tests for both services
   - Coverage reporting (Cobertura)

3. **Build**
   - Docker image build
   - Push to GitLab Container Registry
   - Tag with commit SHA and latest

4. **Security Scan**
   - Trivy container vulnerability scanning
   - SAST with Bandit (Python security linting)

5. **Deploy Dev**
   - Manual deployment to development
   - Triggered on `develop` branch

6. **Deploy Prod**
   - Manual deployment to production
   - Triggered on `main` branch only

### GitLab CI Variables Required
Set these in GitLab project settings:

```
CI_REGISTRY_USER        = Your GitLab username
CI_REGISTRY_PASSWORD    = Your GitLab token (read_registry, write_registry)
DEPLOY_WEBHOOK_DEV      = Deployment webhook URL for dev
DEPLOY_WEBHOOK_PROD     = Deployment webhook URL for prod
```

## ☁️ AWS Deployment with Terraform

### Prerequisites
- AWS Account
- AWS CLI configured
- Terraform 1.0+
- S3 bucket for state (create manually)
- DynamoDB table for state locking (create manually)

### State Management Setup

**Create S3 bucket:**
```bash
aws s3api create-bucket \
  --bucket microservices-state-dev \
  --region us-east-1

aws s3api create-bucket \
  --bucket microservices-state-prod \
  --region us-east-1
```

**Create DynamoDB table:**
```bash
aws dynamodb create-table \
  --table-name microservices-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### Deployment Steps

#### 1. Set Credentials (Non-Hardcoded)
```bash
# Use AWS CLI authentication
export AWS_PROFILE=your-profile
# OR
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
```

#### 2. Deploy to Dev
```bash
# Create secrets for database credentials
echo "postgres-user" | aws secretsmanager create-secret \
  --name microservices-db-username-dev \
  --secret-string file://- \
  --region us-east-1

echo "your-secure-password" | aws secretsmanager create-secret \
  --name microservices-db-password-dev \
  --secret-string file://- \
  --region us-east-1

# Deploy
cd terraform/environments/dev

terraform init \
  -backend-config="bucket=microservices-state-dev" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=microservices-locks"

terraform plan -var-file=terraform.tfvars \
  -var='user_service_image=registry.gitlab.com/your-namespace/user-service:latest' \
  -var='order_service_image=registry.gitlab.com/your-namespace/order-service:latest' \
  -var='container_registry=registry.gitlab.com' \
  -var='db_username=postgres' \
  -var='db_password=your-secure-password'

terraform apply
```

#### 3. Deploy to Prod
```bash
# Create prod secrets
echo "postgres-user" | aws secretsmanager create-secret \
  --name microservices-db-username-prod \
  --secret-string file://- \
  --region us-east-1

# Deploy
cd terraform/environments/prod

terraform init \
  -backend-config="bucket=microservices-state-prod" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=microservices-locks"

terraform plan -var-file=terraform.tfvars \
  -var='user_service_image=registry.gitlab.com/your-namespace/user-service:latest' \
  -var='order_service_image=registry.gitlab.com/your-namespace/order-service:latest' \
  -var='container_registry=registry.gitlab.com' \
  -var='db_username=postgres' \
  -var='db_password=your-secure-password'

terraform apply
```

#### 4. Use Deployment Script
```bash
bash scripts/deploy.sh dev
bash scripts/deploy.sh prod
```

### Terraform Outputs
After deployment, get outputs:
```bash
cd terraform/environments/dev
terraform output load_balancer_dns     # ALB endpoint
terraform output user_service_url      # User service URL
terraform output order_service_url     # Order service URL
```

## 📊 Monitoring & Logs

### CloudWatch Logs
```bash
# View logs
aws logs tail /ecs/microservices-dev --follow

# View specific service logs
aws logs tail /ecs/microservices-dev --follow --log-stream-name-pattern user-service
```

### ECS Console
1. Go to AWS ECS Console
2. Select cluster: `microservices-cluster-dev`
3. View running tasks, logs, and metrics

## 🔒 Security Considerations

### ✅ Implemented
- No hardcoded credentials in code
- AWS Secrets Manager for sensitive data
- Database encryption at rest
- VPC with public/private subnets
- Security groups with minimal permissions
- Container scanning with Trivy
- SAST with Bandit
- HTTPS-ready (ALB configured for port 80, upgrade to 443 in production)

### 🔧 Recommended Enhancements
- Enable HTTPS (ALB + ACM certificate)
- API authentication & authorization
- Rate limiting
- Request logging & audit trails
- Database backup & disaster recovery
- Horizontal pod autoscaling (HPA)
- Service-to-service encryption (mTLS)

## 📝 API Documentation

### User Service

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/users` | Create user |
| GET | `/api/v1/users` | List all users |
| GET | `/api/v1/users/{id}` | Get user by ID |
| GET | `/health/` | Health check |
| GET | `/health/ready` | Readiness check |

### Order Service

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/orders` | Create order |
| GET | `/api/v1/orders` | List all orders |
| GET | `/api/v1/orders/{id}` | Get order by ID |
| GET | `/api/v1/orders/user/{user_id}` | List user's orders |
| PATCH | `/api/v1/orders/{id}/status` | Update order status |
| GET | `/health/` | Health check |
| GET | `/health/ready` | Readiness check |

## 🛠️ Development

### Add a New Service
1. Create service directory: `services/new-service/`
2. Copy structure from existing service
3. Update `docker-compose.yml`
4. Update `.gitlab-ci.yml` (add test & build jobs)
5. Create Terraform module in `terraform/modules/`
6. Add to `terraform/environments/*/main.tf`

### Update Dependencies
```bash
# User service
cd services/user-service
pip install -r requirements.txt --upgrade

# Order service
cd services/order-service
pip install -r requirements.txt --upgrade
```

### Database Migrations
Currently using SQLAlchemy ORM. For migrations, integrate Alembic:
```bash
alembic init alembic
alembic revision --autogenerate -m "message"
alembic upgrade head
```

## 🐛 Troubleshooting

### Services won't start
```bash
# Check logs
docker-compose logs user-service
docker-compose logs order-service

# Ensure ports aren't in use
lsof -i :8001
lsof -i :8002
lsof -i :5432
lsof -i :5433
```

### Database connection errors
```bash
# Check if DB is healthy
docker-compose ps

# Exec into DB container
docker-compose exec user-db psql -U postgres -d users_db
```

### Terraform errors
```bash
# Validate config
terraform validate

# Format code
terraform fmt -recursive

# Check state
terraform state list
terraform state show aws_ecs_cluster.main
```

## 📚 Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [AWS ECS Fargate Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_types.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)

## 📄 License

MIT License

## 👥 Support

For issues or questions, open a GitLab issue or contact the development team.
