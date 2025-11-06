variable "datasets_bucket_name" {
  description = "Name for the datasets S3 bucket"
  type        = string
}

variable "models_bucket_name" {
  description = "Name for the models S3 bucket"
  type        = string
}

variable "enable_versioning" {
  description = "Whether to enable versioning for S3 buckets"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for bucket encryption (if null, uses AES256)"
  type        = string
  default     = null
}

variable "enable_lifecycle_policies" {
  description = "Whether to enable lifecycle policies for cost optimization"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

