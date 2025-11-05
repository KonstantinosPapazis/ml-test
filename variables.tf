variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name to be used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

# SageMaker Notebook Instance Configuration
variable "notebook_name" {
  description = "Name of the SageMaker notebook instance"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type for the notebook instance"
  type        = string
  default     = "ml.t3.medium"
}

variable "volume_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 5
  validation {
    condition     = var.volume_size >= 5 && var.volume_size <= 16384
    error_message = "Volume size must be between 5 GB and 16384 GB."
  }
}

variable "platform_identifier" {
  description = "Platform identifier for the notebook instance (notebook-al2-v2, notebook-al1-v1, etc.)"
  type        = string
  default     = "notebook-al2-v2"
}

variable "root_access" {
  description = "Whether root access is enabled for notebook instance users"
  type        = string
  default     = "Disabled"
  validation {
    condition     = contains(["Enabled", "Disabled"], var.root_access)
    error_message = "Root access must be either 'Enabled' or 'Disabled'."
  }
}

variable "direct_internet_access" {
  description = "Whether direct internet access is enabled (Enabled or Disabled)"
  type        = string
  default     = "Disabled"
  validation {
    condition     = contains(["Enabled", "Disabled"], var.direct_internet_access)
    error_message = "Direct internet access must be either 'Enabled' or 'Disabled'."
  }
}

# Network Configuration
variable "vpc_id" {
  description = "VPC ID where the notebook instance will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the notebook instance (should be private subnet)"
  type        = string
}

variable "additional_security_group_ids" {
  description = "Additional security group IDs to attach to the notebook instance"
  type        = list(string)
  default     = []
}

# Security Group Configuration
variable "create_security_group" {
  description = "Whether to create a new security group for the notebook instance"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name for the security group (if creating new one)"
  type        = string
  default     = null
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the notebook instance"
  type        = list(string)
  default     = []
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block for internal communication"
  type        = string
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to access the notebook instance"
  type        = list(string)
  default     = []
}

# VPC Endpoint Configuration (for private subnet access)
variable "enable_s3_vpc_endpoint" {
  description = "Whether to allow traffic to S3 VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_sagemaker_api_vpc_endpoint" {
  description = "Whether to allow traffic to SageMaker API VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_sagemaker_runtime_vpc_endpoint" {
  description = "Whether to allow traffic to SageMaker Runtime VPC endpoint"
  type        = bool
  default     = true
}

# IAM Configuration
variable "create_iam_role" {
  description = "Whether to create a new IAM role for the notebook instance"
  type        = bool
  default     = true
}

variable "iam_role_arn" {
  description = "ARN of existing IAM role to use (if not creating new one)"
  type        = string
  default     = null
}

variable "iam_role_name" {
  description = "Name for the IAM role (if creating new one)"
  type        = string
  default     = null
}

variable "iam_role_path" {
  description = "Path for the IAM role"
  type        = string
  default     = "/"
}

variable "iam_role_permissions_boundary" {
  description = "ARN of the permissions boundary policy to attach to the IAM role"
  type        = string
  default     = null
}

variable "additional_iam_policies" {
  description = "Additional IAM policy ARNs to attach to the notebook role"
  type        = list(string)
  default     = []
}

variable "s3_bucket_arns" {
  description = "S3 bucket ARNs that the notebook instance needs access to"
  type        = list(string)
  default     = []
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting the notebook instance storage volume"
  type        = string
  default     = null
}

# Lifecycle Configuration
variable "lifecycle_config_name" {
  description = "Name of the lifecycle configuration to attach"
  type        = string
  default     = null
}

variable "create_lifecycle_config" {
  description = "Whether to create a lifecycle configuration"
  type        = bool
  default     = false
}

variable "lifecycle_config_on_create" {
  description = "Base64-encoded shell script to run on notebook instance creation"
  type        = string
  default     = null
}

variable "lifecycle_config_on_start" {
  description = "Base64-encoded shell script to run on notebook instance start"
  type        = string
  default     = null
}

# Code Repository
variable "default_code_repository" {
  description = "The Git repository to associate with the notebook instance as its default code repository"
  type        = string
  default     = null
}

variable "additional_code_repositories" {
  description = "An array of up to three Git repositories to associate with the notebook instance"
  type        = list(string)
  default     = []
}

# Monitoring and Logging
variable "enable_cloudwatch_logs" {
  description = "Whether to enable CloudWatch logs for the notebook instance"
  type        = bool
  default     = true
}

variable "cloudwatch_logs_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

# Tags
variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "notebook_tags" {
  description = "Additional tags for the notebook instance"
  type        = map(string)
  default     = {}
}

variable "security_group_tags" {
  description = "Additional tags for the security group"
  type        = map(string)
  default     = {}
}

variable "iam_role_tags" {
  description = "Additional tags for the IAM role"
  type        = map(string)
  default     = {}
}

# Advanced Configuration
variable "instance_metadata_service_configuration" {
  description = "Configuration for Instance Metadata Service"
  type = object({
    minimum_instance_metadata_service_version = string
  })
  default = {
    minimum_instance_metadata_service_version = "2"
  }
}

