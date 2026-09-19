variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Short name used as a prefix for all resources."
  type        = string
  default     = "taskmanager"
}

variable "environment" {
  description = "Environment name (for example prod or staging)."
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type for the application host."
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair to use for the host. Leave empty to have Terraform generate one and write it to <project>-<environment>.pem."
  type        = string
  default     = ""
}

variable "allowed_ssh_cidrs" {
  description = "CIDRs allowed to SSH to the host (port 22). Empty by default so SSH is closed; set the Jenkins agent's public IP, e.g. [\"203.0.113.10/32\"]. With an empty list, use SSM Session Manager instead."
  type        = list(string)
  default     = []
}

variable "allowed_http_cidr" {
  description = "CIDR allowed to reach the app on ports 80 and 8080."
  type        = string
  default     = "0.0.0.0/0"
}

variable "create_rds" {
  description = "Create an RDS MySQL instance instead of using the bundled MySQL container."
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Application database name."
  type        = string
  default     = "taskmanager"
}

variable "db_username" {
  description = "Master username for RDS MySQL."
  type        = string
  default     = "taskmanager"
}

variable "db_password" {
  description = "Master password for RDS MySQL. Pass via TF_VAR_db_password or a gitignored tfvars file."
  type        = string
  sensitive   = true
}

variable "rds_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB."
  type        = number
  default     = 20
}
