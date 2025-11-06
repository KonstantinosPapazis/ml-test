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

output "network_interface_id" {
  description = "Network interface ID of the notebook instance"
  value       = aws_sagemaker_notebook_instance.this.network_interface_id
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.notebook[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.notebook[0].arn : null
}

