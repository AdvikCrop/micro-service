locals {
  environment = "prod"
}

module "networking" {
  source = "../../modules/networking"

  project_name              = var.project_name
  environment               = local.environment
  vpc_cidr                  = var.vpc_cidr
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_subnet_cidrs      = var.private_subnet_cidrs
  availability_zones        = var.availability_zones
  enable_nat_per_az         = true
  enable_enhanced_security  = true
}

module "rds" {
  source = "../../modules/rds"

  project_name          = var.project_name
  environment           = local.environment
  private_subnet_ids    = module.networking.private_subnet_ids
  rds_security_group_id = module.networking.rds_security_group_id
  db_instance_class     = var.db_instance_class
  db_allocated_storage  = var.db_allocated_storage
  db_username           = var.db_username
  db_password           = var.db_password
}

resource "aws_secretsmanager_secret" "db_username" {
  name                    = "${var.project_name}-db-username-${local.environment}"
  recovery_window_in_days = 30

  tags = {
    Name = "${var.project_name}-db-username"
  }
}

resource "aws_secretsmanager_secret_version" "db_username" {
  secret_id     = aws_secretsmanager_secret.db_username.id
  secret_string = var.db_username
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project_name}-db-password-${local.environment}"
  recovery_window_in_days = 30

  tags = {
    Name = "${var.project_name}-db-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb-${local.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.networking.alb_security_group_id]
  subnets            = module.networking.public_subnet_ids

  enable_deletion_protection = true

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "user_service" {
  name        = "${var.project_name}-user-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = module.networking.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/health/"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-user-tg"
  }
}

resource "aws_lb_target_group" "order_service" {
  name        = "${var.project_name}-order-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = module.networking.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/health/"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-order-tg"
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user_service.arn
  }
}

resource "aws_lb_listener_rule" "user_service" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user_service.arn
  }

  condition {
    path_pattern {
      values = ["/user-service/*"]
    }
  }
}

resource "aws_lb_listener_rule" "order_service" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.order_service.arn
  }

  condition {
    path_pattern {
      values = ["/order-service/*"]
    }
  }
}

module "ecs" {
  source = "../../modules/ecs"

  project_name                   = var.project_name
  environment                    = local.environment
  aws_region                     = var.aws_region
  user_service_image             = var.user_service_image
  order_service_image            = var.order_service_image
  private_subnet_ids             = module.networking.private_subnet_ids
  ecs_tasks_security_group_id    = module.networking.ecs_tasks_security_group_id
  user_db_endpoint               = module.rds.user_db_endpoint
  order_db_endpoint              = module.rds.order_db_endpoint
  db_username_secret_arn         = aws_secretsmanager_secret.db_username.arn
  db_password_secret_arn         = aws_secretsmanager_secret.db_password.arn
  user_service_target_group_arn  = aws_lb_target_group.user_service.arn
  order_service_target_group_arn = aws_lb_target_group.order_service.arn
  container_port                 = var.container_port
  desired_count                  = var.desired_count
  container_cpu                  = var.container_cpu
  container_memory               = var.container_memory
}

module "eks" {
  source = "../../modules/eks"

  project_name       = var.project_name
  environment        = local.environment
  vpc_id             = module.networking.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids
  kubernetes_version = var.kubernetes_version
  desired_size       = var.eks_desired_size
  min_size           = var.eks_min_size
  max_size           = var.eks_max_size
  instance_types     = var.eks_instance_types
  log_retention_days = 30
}
