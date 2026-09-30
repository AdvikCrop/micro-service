aws_region         = "us-east-1"
project_name       = "microservices"
container_registry = "023644376175.dkr.ecr.us-east-1.amazonaws.com/dev"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

db_instance_class    = "db.t3.micro"
db_allocated_storage = 20

container_port   = 8000
desired_count    = 1
container_cpu    = 256
container_memory = 512
