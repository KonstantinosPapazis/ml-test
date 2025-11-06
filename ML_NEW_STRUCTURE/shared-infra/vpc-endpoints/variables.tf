variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID where VPC endpoints will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for interface endpoints (use multiple for HA)"
  type        = list(string)
}

variable "route_table_ids" {
  description = "List of route table IDs for S3 gateway endpoint"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for interface endpoints"
  type        = list(string)
}

variable "create_s3_endpoint" {
  description = "Whether to create S3 gateway endpoint"
  type        = bool
  default     = true
}

variable "create_sagemaker_api_endpoint" {
  description = "Whether to create SageMaker API endpoint"
  type        = bool
  default     = true
}

variable "create_sagemaker_runtime_endpoint" {
  description = "Whether to create SageMaker Runtime endpoint"
  type        = bool
  default     = true
}

variable "create_ec2_endpoint" {
  description = "Whether to create EC2 endpoint"
  type        = bool
  default     = true
}

variable "create_logs_endpoint" {
  description = "Whether to create CloudWatch Logs endpoint"
  type        = bool
  default     = false
}

variable "create_ecr_endpoints" {
  description = "Whether to create ECR endpoints (API and DKR)"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

