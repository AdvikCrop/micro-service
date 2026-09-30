variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "enable_nat_per_az" {
  description = "Enable NAT gateway per AZ for HA (prod) vs single NAT (dev)"
  type        = bool
  default     = false
}

variable "enable_enhanced_security" {
  description = "Enable enhanced security groups for prod"
  type        = bool
  default     = false
}
