output "eks_cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = module.eks.cluster_id
}

output "eks_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = module.eks.cluster_version
}

output "eks_node_group_id" {
  description = "EKS node group id"
  value       = module.eks.node_group_id
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC Provider for GitHub Actions"
  value       = module.eks.oidc_provider_arn
}

output "rds_user_db_endpoint" {
  description = "RDS user database endpoint"
  value       = module.rds.user_db_endpoint
}

output "rds_order_db_endpoint" {
  description = "RDS order database endpoint"
  value       = module.rds.order_db_endpoint
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}
