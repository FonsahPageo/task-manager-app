output "ec2_public_ip" {
  description = "Elastic IP of the application host; use this as the Jenkins EC2_HOST parameter."
  value       = aws_eip.app.public_ip
}

output "ssh_command" {
  description = "SSH command for the application host (replace the key path when using an existing key pair)."
  value       = var.key_name != "" ? "ssh -i ${var.key_name}.pem ubuntu@${aws_eip.app.public_ip}" : "ssh -i ${local_file.host_private_key[0].filename} ubuntu@${aws_eip.app.public_ip}"
}

output "ecr_backend_url" {
  description = "ECR repository URL for the backend image."
  value       = aws_ecr_repository.app["backend"].repository_url
}

output "ecr_frontend_url" {
  description = "ECR repository URL for the frontend image."
  value       = aws_ecr_repository.app["frontend"].repository_url
}

output "jenkins_instance_profile_name" {
  description = "Instance profile to attach to the EC2 instance that runs Jenkins."
  value       = aws_iam_instance_profile.jenkins.name
}

output "jenkins_role_arn" {
  description = "IAM role ARN that allows pushing to ECR."
  value       = aws_iam_role.jenkins.arn
}

output "host_instance_profile_name" {
  description = "Instance profile attached to the application host."
  value       = aws_iam_instance_profile.host.name
}

output "database_url" {
  description = "Value for the Jenkins taskmanager-db-url credential."
  value       = var.create_rds ? "jdbc:mysql://${aws_db_instance.main[0].address}:3306/${var.db_name}?useSSL=true&serverTimezone=UTC" : "jdbc:mysql://db:3306/${var.db_name}?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"
}

output "rds_endpoint" {
  description = "RDS endpoint address when create_rds is enabled."
  value       = var.create_rds ? aws_db_instance.main[0].address : null
}

output "cloudfront_domain" {
  description = "HTTPS API endpoint; set VITE_API_BASE_URL to https://<this>/api when serving the frontend from Firebase Hosting."
  value       = aws_cloudfront_distribution.app.domain_name
}
