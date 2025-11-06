variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "notebook_name" {
  description = "Notebook instance name"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "ml.t3.medium"
}

variable "volume_size" {
  description = "EBS volume size in GB"
  type        = number
  default     = 10
}

variable "root_access" {
  description = "Root access (Enabled or Disabled)"
  type        = string
  default     = "Enabled"
}

variable "direct_internet_access" {
  description = "Direct internet access (Enabled or Disabled)"
  type        = string
  default     = "Disabled"
}

variable "platform_identifier" {
  description = "Platform identifier"
  type        = string
  default     = "notebook-al2-v2"
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
}

variable "iam_role_arn" {
  description = "IAM role ARN (from shared-infra/iam)"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
}

variable "create_lifecycle_config" {
  description = "Create lifecycle configuration"
  type        = bool
  default     = false
}

variable "lifecycle_config_on_create" {
  description = "Lifecycle config on create"
  type        = string
  default     = null
}

variable "lifecycle_config_on_start" {
  description = "Lifecycle config on start"
  type        = string
  default     = null
}

variable "default_code_repository" {
  description = "Default code repository"
  type        = string
  default     = null
}

variable "additional_code_repositories" {
  description = "Additional code repositories"
  type        = list(string)
  default     = []
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs"
  type        = bool
  default     = true
}

variable "cloudwatch_logs_retention_days" {
  description = "CloudWatch logs retention days"
  type        = number
  default     = 30
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

