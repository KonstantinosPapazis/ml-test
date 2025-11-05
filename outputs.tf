output "notebook_instance_name" {
  description = "Name of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.this.name
}

output "notebook_instance_arn" {
  description = "ARN of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.this.arn
}

output "notebook_instance_url" {
  description = "URL of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.this.url
}

output "notebook_instance_id" {
  description = "ID of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.this.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role used by the notebook instance"
  value       = local.iam_role_arn
}

output "iam_role_name" {
  description = "Name of the IAM role used by the notebook instance"
  value       = var.create_iam_role ? aws_iam_role.sagemaker_notebook[0].name : null
}

output "security_group_id" {
  description = "ID of the security group created for the notebook instance"
  value       = var.create_security_group ? aws_security_group.sagemaker_notebook[0].id : null
}

output "security_group_arn" {
  description = "ARN of the security group created for the notebook instance"
  value       = var.create_security_group ? aws_security_group.sagemaker_notebook[0].arn : null
}

output "security_group_name" {
  description = "Name of the security group created for the notebook instance"
  value       = var.create_security_group ? aws_security_group.sagemaker_notebook[0].name : null
}

output "all_security_group_ids" {
  description = "All security group IDs attached to the notebook instance"
  value       = local.security_group_ids
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for the notebook instance"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.notebook[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for the notebook instance"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.notebook[0].arn : null
}

output "lifecycle_config_name" {
  description = "Name of the lifecycle configuration"
  value       = var.create_lifecycle_config ? aws_sagemaker_notebook_instance_lifecycle_configuration.this[0].name : var.lifecycle_config_name
}

output "lifecycle_config_arn" {
  description = "ARN of the lifecycle configuration"
  value       = var.create_lifecycle_config ? aws_sagemaker_notebook_instance_lifecycle_configuration.this[0].arn : null
}

output "network_interface_id" {
  description = "Network interface ID of the notebook instance"
  value       = aws_sagemaker_notebook_instance.this.network_interface_id
}

