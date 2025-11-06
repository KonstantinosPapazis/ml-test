output "notebook_security_group_id" {
  description = "ID of the notebook security group"
  value       = aws_security_group.sagemaker_notebook.id
}

output "notebook_security_group_arn" {
  description = "ARN of the notebook security group"
  value       = aws_security_group.sagemaker_notebook.arn
}

output "vpc_endpoint_security_group_id" {
  description = "ID of the VPC endpoint security group"
  value       = var.create_vpc_endpoint_sg ? aws_security_group.vpc_endpoints[0].id : null
}

output "vpc_endpoint_security_group_arn" {
  description = "ARN of the VPC endpoint security group"
  value       = var.create_vpc_endpoint_sg ? aws_security_group.vpc_endpoints[0].arn : null
}

