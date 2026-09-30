output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "user_service_task_definition_arn" {
  value = aws_ecs_task_definition.user_service.arn
}

output "order_service_task_definition_arn" {
  value = aws_ecs_task_definition.order_service.arn
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.ecs.name
}
