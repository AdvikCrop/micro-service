aws_region         = "us-east-1"
environment        = "prod"
project_name       = "microservices"
container_registry = "023644376175.dkr.ecr.us-east-1.amazonaws.com/prod"

vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]

db_instance_class    = "db.t3.small"
db_allocated_storage = 100
db_secret_arn        = "arn:aws:secretsmanager:us-east-1:023644376175:secret:microservices-db-credentials-prod-1M1V42"

container_port   = 8000
desired_count    = 3
container_cpu    = 1024
container_memory = 2048

user_service_image  = "023644376175.dkr.ecr.us-east-1.amazonaws.com/prod:user-service"
order_service_image = "023644376175.dkr.ecr.us-east-1.amazonaws.com/prod:order-service"
kubernetes_version  = "1.28"
eks_desired_size    = 3
eks_min_size        = 2
eks_max_size        = 10
eks_instance_types  = ["t3.large"]
