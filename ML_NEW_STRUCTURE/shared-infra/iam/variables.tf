variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "iam_role_name" {
  description = "Name for the shared IAM role"
  type        = string
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs to grant access to"
  type        = list(string)
}

variable "enable_git_access" {
  description = "Whether to enable Git/CodeCommit access"
  type        = bool
  default     = true
}

variable "enable_secrets_manager_access" {
  description = "Whether to enable Secrets Manager access"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for encryption (optional)"
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

