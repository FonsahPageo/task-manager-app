output "state_bucket" {
  description = "S3 bucket that stores Terraform state."
  value       = aws_s3_bucket.state.bucket
}

output "state_region" {
  description = "Region of the state bucket."
  value       = var.aws_region
}

output "backend_config" {
  description = "Contents for terraform/backend.hcl in the main configuration."
  value = join("\n", [
    "bucket = \"${aws_s3_bucket.state.bucket}\"",
    "region = \"${var.aws_region}\"",
  ])
}
