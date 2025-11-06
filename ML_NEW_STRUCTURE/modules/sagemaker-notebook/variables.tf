variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "notebook_name" {
  description = "Name of the notebook instance (if null, auto-generated)"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type for the notebook"
  type        = string
  default     = "ml.t3.medium"
}

variable "volume_size" {
  description = "Size of the EBS volume in GB (min: 5, max: 16384)"
  type        = number
  default     = 5

  validation {
    condition     = var.volume_size >= 5 && var.volume_size <= 16384
    error_message = "Volume size must be between 5 GB and 16384 GB."
  }
}

variable "platform_identifier" {
  description = "Platform identifier (notebook-al2-v2, notebook-al1-v1, etc.)"
  type        = string
  default     = "notebook-al2-v2"
}

variable "root_access" {
  description = "Whether root access is enabled (Enabled or Disabled)"
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
variable "subnet_id" {
  description = "Subnet ID for the notebook instance"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

# IAM Configuration
variable "iam_role_arn" {
  description = "ARN of the IAM role for the notebook"
  type        = string
}

# Encryption
variable "kms_key_id" {
  description = "KMS key ID for encrypting the EBS volume"
  type        = string
  default     = null
}

# Lifecycle Configuration
variable "create_lifecycle_config" {
  description = "Whether to create a lifecycle configuration"
  type        = bool
  default     = false
}

variable "lifecycle_config_name" {
  description = "Name of existing lifecycle configuration to attach"
  type        = string
  default     = null
}

variable "lifecycle_config_on_create" {
  description = "Base64-encoded shell script to run on notebook creation"
  type        = string
  default     = null
}

variable "lifecycle_config_on_start" {
  description = "Base64-encoded shell script to run on notebook start"
  type        = string
  default     = null
}

# Code Repository
variable "default_code_repository" {
  description = "Default Git repository for the notebook"
  type        = string
  default     = null
}

variable "additional_code_repositories" {
  description = "Additional Git repositories (max 3)"
  type        = list(string)
  default     = []
}

# Monitoring
variable "enable_cloudwatch_logs" {
  description = "Whether to enable CloudWatch logs"
  type        = bool
  default     = true
}

variable "cloudwatch_logs_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

# Instance Metadata
variable "instance_metadata_service_version" {
  description = "Minimum instance metadata service version (1 or 2)"
  type        = string
  default     = "2"
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

