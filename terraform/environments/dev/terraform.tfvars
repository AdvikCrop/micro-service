aws_region         = "us-east-1"
environment        = "dev"
project_name       = "microservices"
container_registry = "023644376175.dkr.ecr.us-east-1.amazonaws.com/dev"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
db_secret_arn        = "arn:aws:secretsmanager:us-east-1:023644376175:secret:microservices-db-credentials-dev-OBZIPW"

container_port   = 8000
desired_count    = 1
container_cpu    = 256
container_memory = 512

user_service_image  = "023644376175.dkr.ecr.us-east-1.amazonaws.com/dev:user-service"
order_service_image = "023644376175.dkr.ecr.us-east-1.amazonaws.com/dev:order-service"
kubernetes_version  = "1.36"
eks_desired_size    = 1
eks_min_size        = 1
eks_max_size        = 2
