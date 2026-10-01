variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "user_service_image" {
  description = "User service Docker image"
  type        = string
}

variable "order_service_image" {
  description = "Order service Docker image"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "ecs_tasks_security_group_id" {
  description = "ECS tasks security group ID"
  type        = string
}

variable "user_db_endpoint" {
  description = "User database endpoint"
  type        = string
  sensitive   = true
}

variable "order_db_endpoint" {
  description = "Order database endpoint"
  type        = string
  sensitive   = true
}

variable "db_secret_arn" {
  description = "Database credentials secret ARN"
  type        = string
  sensitive   = true
}

variable "user_service_target_group_arn" {
  description = "User service target group ARN"
  type        = string
}

variable "order_service_target_group_arn" {
  description = "Order service target group ARN"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
}

variable "container_cpu" {
  description = "Container CPU units"
  type        = number
}

variable "container_memory" {
  description = "Container memory in MB"
  type        = number
}
