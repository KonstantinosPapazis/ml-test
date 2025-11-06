output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = var.create_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}

output "sagemaker_api_endpoint_id" {
  description = "ID of the SageMaker API VPC endpoint"
  value       = var.create_sagemaker_api_endpoint ? aws_vpc_endpoint.sagemaker_api[0].id : null
}

output "sagemaker_runtime_endpoint_id" {
  description = "ID of the SageMaker Runtime VPC endpoint"
  value       = var.create_sagemaker_runtime_endpoint ? aws_vpc_endpoint.sagemaker_runtime[0].id : null
}

output "ec2_endpoint_id" {
  description = "ID of the EC2 VPC endpoint"
  value       = var.create_ec2_endpoint ? aws_vpc_endpoint.ec2[0].id : null
}

output "logs_endpoint_id" {
  description = "ID of the CloudWatch Logs VPC endpoint"
  value       = var.create_logs_endpoint ? aws_vpc_endpoint.logs[0].id : null
}

output "ecr_api_endpoint_id" {
  description = "ID of the ECR API VPC endpoint"
  value       = var.create_ecr_endpoints ? aws_vpc_endpoint.ecr_api[0].id : null
}

output "ecr_dkr_endpoint_id" {
  description = "ID of the ECR DKR VPC endpoint"
  value       = var.create_ecr_endpoints ? aws_vpc_endpoint.ecr_dkr[0].id : null
}

