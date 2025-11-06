# S3 Bucket for ML Datasets
resource "aws_s3_bucket" "datasets" {
  count = var.create_datasets_bucket ? 1 : 0

  bucket = var.datasets_bucket_name != null ? var.datasets_bucket_name : "${var.project_name}-${var.environment}-datasets"

  tags = merge(
    var.default_tags,
    var.datasets_bucket_tags,
    {
      Name        = var.datasets_bucket_name != null ? var.datasets_bucket_name : "${var.project_name}-${var.environment}-datasets"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "ML Datasets Storage"
    }
  )
}

# Enable versioning for data protection
resource "aws_s3_bucket_versioning" "datasets" {
  count = var.create_datasets_bucket && var.enable_datasets_bucket_versioning ? 1 : 0

  bucket = aws_s3_bucket.datasets[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "datasets" {
  count = var.create_datasets_bucket ? 1 : 0

  bucket = aws_s3_bucket.datasets[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.datasets_bucket_kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.datasets_bucket_kms_key_id
    }
    bucket_key_enabled = var.datasets_bucket_kms_key_id != null ? true : false
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "datasets" {
  count = var.create_datasets_bucket ? 1 : 0

  bucket = aws_s3_bucket.datasets[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "datasets" {
  count = var.create_datasets_bucket && var.enable_datasets_bucket_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.datasets[0].id

  # Archive old versions to cheaper storage
  rule {
    id     = "archive-old-versions"
    status = var.datasets_bucket_lifecycle_rules.archive_old_versions.enabled ? "Enabled" : "Disabled"

    noncurrent_version_transition {
      noncurrent_days = var.datasets_bucket_lifecycle_rules.archive_old_versions.transition_days
      storage_class   = var.datasets_bucket_lifecycle_rules.archive_old_versions.storage_class
    }

    filter {}
  }

  # Delete old versions after certain period
  rule {
    id     = "delete-old-versions"
    status = var.datasets_bucket_lifecycle_rules.delete_old_versions.enabled ? "Enabled" : "Disabled"

    noncurrent_version_expiration {
      noncurrent_days = var.datasets_bucket_lifecycle_rules.delete_old_versions.expiration_days
    }

    filter {}
  }

  # Transition current objects to IA after certain period (good for infrequently accessed datasets)
  rule {
    id     = "transition-to-ia"
    status = var.datasets_bucket_lifecycle_rules.transition_to_ia.enabled ? "Enabled" : "Disabled"

    transition {
      days          = var.datasets_bucket_lifecycle_rules.transition_to_ia.transition_days
      storage_class = "STANDARD_IA"
    }

    filter {
      prefix = var.datasets_bucket_lifecycle_rules.transition_to_ia.prefix
    }
  }

  # Clean up incomplete multipart uploads
  rule {
    id     = "cleanup-incomplete-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    filter {}
  }
}

# Optional: S3 bucket for model artifacts
resource "aws_s3_bucket" "models" {
  count = var.create_models_bucket ? 1 : 0

  bucket = var.models_bucket_name != null ? var.models_bucket_name : "${var.project_name}-${var.environment}-models"

  tags = merge(
    var.default_tags,
    var.models_bucket_tags,
    {
      Name        = var.models_bucket_name != null ? var.models_bucket_name : "${var.project_name}-${var.environment}-models"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "ML Model Artifacts Storage"
    }
  )
}

# Enable versioning for models
resource "aws_s3_bucket_versioning" "models" {
  count = var.create_models_bucket && var.enable_models_bucket_versioning ? 1 : 0

  bucket = aws_s3_bucket.models[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for models
resource "aws_s3_bucket_server_side_encryption_configuration" "models" {
  count = var.create_models_bucket ? 1 : 0

  bucket = aws_s3_bucket.models[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.models_bucket_kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.models_bucket_kms_key_id
    }
    bucket_key_enabled = var.models_bucket_kms_key_id != null ? true : false
  }
}

# Block public access for models
resource "aws_s3_bucket_public_access_block" "models" {
  count = var.create_models_bucket ? 1 : 0

  bucket = aws_s3_bucket.models[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Local variable to combine bucket ARNs
locals {
  created_bucket_arns = concat(
    var.create_datasets_bucket ? [aws_s3_bucket.datasets[0].arn] : [],
    var.create_models_bucket ? [aws_s3_bucket.models[0].arn] : []
  )

  # Combine created buckets with user-provided bucket ARNs
  all_s3_bucket_arns = concat(
    local.created_bucket_arns,
    var.s3_bucket_arns
  )
}

