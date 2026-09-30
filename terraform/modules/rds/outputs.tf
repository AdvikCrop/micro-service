output "user_db_endpoint" {
  value     = aws_db_instance.user_db.endpoint
  sensitive = true
}

output "order_db_endpoint" {
  value     = aws_db_instance.order_db.endpoint
  sensitive = true
}

output "user_db_name" {
  value = aws_db_instance.user_db.db_name
}

output "order_db_name" {
  value = aws_db_instance.order_db.db_name
}

output "user_db_username" {
  value     = aws_db_instance.user_db.username
  sensitive = true
}

output "order_db_username" {
  value     = aws_db_instance.order_db.username
  sensitive = true
}
