# S3 Buckets for ML Datasets and Models
# These buckets are shared across all notebook instances

# S3 Bucket for ML Datasets
resource "aws_s3_bucket" "datasets" {
  bucket = var.datasets_bucket_name

  tags = merge(
    var.common_tags,
    {
      Name    = var.datasets_bucket_name
      Purpose = "ML Datasets Storage"
    }
  )
}

# Enable versioning for datasets bucket
resource "aws_s3_bucket_versioning" "datasets" {
  bucket = aws_s3_bucket.datasets.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# Server-side encryption for datasets bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "datasets" {
  bucket = aws_s3_bucket.datasets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.kms_key_id != null ? true : false
  }
}

# Block public access for datasets bucket
resource "aws_s3_bucket_public_access_block" "datasets" {
  bucket = aws_s3_bucket.datasets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy for datasets bucket
resource "aws_s3_bucket_lifecycle_configuration" "datasets" {
  count = var.enable_lifecycle_policies ? 1 : 0

  bucket = aws_s3_bucket.datasets.id

  # Archive old versions to cheaper storage
  rule {
    id     = "archive-old-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }

    filter {}
  }

  # Delete old versions after certain period
  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    filter {}
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

# S3 Bucket for ML Models
resource "aws_s3_bucket" "models" {
  bucket = var.models_bucket_name

  tags = merge(
    var.common_tags,
    {
      Name    = var.models_bucket_name
      Purpose = "ML Model Artifacts Storage"
    }
  )
}

# Enable versioning for models bucket
resource "aws_s3_bucket_versioning" "models" {
  bucket = aws_s3_bucket.models.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# Server-side encryption for models bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "models" {
  bucket = aws_s3_bucket.models.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.kms_key_id != null ? true : false
  }
}

# Block public access for models bucket
resource "aws_s3_bucket_public_access_block" "models" {
  bucket = aws_s3_bucket.models.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

