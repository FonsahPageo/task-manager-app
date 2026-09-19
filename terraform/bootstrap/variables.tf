variable "aws_region" {
  description = "AWS region for the Terraform state bucket."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Short name used as a prefix for the state bucket."
  type        = string
  default     = "taskmanager"
}
