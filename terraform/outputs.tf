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
  value       = aws_db_instance.user_db.endpoint
  sensitive   = true
}

output "order_db_endpoint" {
  description = "Order database endpoint"
  value       = aws_db_instance.order_db.endpoint
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "user_service_task_definition" {
  description = "User service task definition"
  value       = aws_ecs_task_definition.user_service.arn
}

output "order_service_task_definition" {
  description = "Order service task definition"
  value       = aws_ecs_task_definition.order_service.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.name
}
