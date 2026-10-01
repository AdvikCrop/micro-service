output "load_balancer_dns" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "user_service_url" {
  description = "User service endpoint"
  value       = "http://${aws_lb.main.dns_name}/user-service"
}

output "order_service_url" {
  description = "Order service endpoint"
  value       = "http://${aws_lb.main.dns_name}/order-service"
}

output "user_db_endpoint" {
  description = "User database endpoint"
  value       = module.rds.user_db_endpoint
  sensitive   = true
}

output "order_db_endpoint" {
  description = "Order database endpoint"
  value       = module.rds.order_db_endpoint
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.ecs_cluster_name
}

output "user_service_task_definition" {
  description = "User service task definition"
  value       = module.ecs.user_service_task_definition_arn
}

output "order_service_task_definition" {
  description = "Order service task definition"
  value       = module.ecs.order_service_task_definition_arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group"
  value       = module.ecs.cloudwatch_log_group_name
}

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}
