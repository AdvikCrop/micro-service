# Variables passthrough - actual definitions are in ../variables.tf
# This file exists to suppress warnings when running terraform from this directory

variable "aws_region" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "container_registry" {
  type = string
}

variable "user_service_image" {
  type = string
}

variable "order_service_image" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "db_instance_class" {
  type = string
}

variable "db_allocated_storage" {
  type = number
}

variable "db_secret_arn" {
  type = string
}

variable "container_port" {
  type = number
}

variable "desired_count" {
  type = number
}

variable "container_cpu" {
  type = number
}

variable "container_memory" {
  type = number
}

variable "kubernetes_version" {
  type = string
}

variable "eks_desired_size" {
  type = number
}

variable "eks_min_size" {
  type = number
}

variable "eks_max_size" {
  type = number
}

variable "eks_instance_types" {
  type = list(string)
}
