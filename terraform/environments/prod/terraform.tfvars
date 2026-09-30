aws_region         = "us-east-1"
project_name       = "microservices"
container_registry = "023644376175.dkr.ecr.us-east-1.amazonaws.com/dev"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]

db_instance_class    = "db.t3.small"
db_allocated_storage = 100

container_port   = 8000
desired_count    = 3
container_cpu    = 1024
container_memory = 2048
