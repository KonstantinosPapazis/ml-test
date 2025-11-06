variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

variable "notebook_sg_name" {
  description = "Name for the notebook security group"
  type        = string
  default     = "sagemaker-notebooks-sg"
}

variable "vpc_endpoint_sg_name" {
  description = "Name for the VPC endpoint security group"
  type        = string
  default     = "sagemaker-vpc-endpoints-sg"
}

variable "create_vpc_endpoint_sg" {
  description = "Whether to create security group for VPC endpoints"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

