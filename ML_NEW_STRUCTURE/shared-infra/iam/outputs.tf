output "iam_role_arn" {
  description = "ARN of the shared IAM role"
  value       = aws_iam_role.sagemaker_shared.arn
}

output "iam_role_name" {
  description = "Name of the shared IAM role"
  value       = aws_iam_role.sagemaker_shared.name
}

output "iam_role_id" {
  description = "ID of the shared IAM role"
  value       = aws_iam_role.sagemaker_shared.id
}

