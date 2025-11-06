# Reusable SageMaker Notebook Instance Module

locals {
  notebook_name = var.notebook_name != null ? var.notebook_name : "${var.project_name}-${var.environment}-notebook"
}

# Lifecycle Configuration (optional)
resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "this" {
  count = var.create_lifecycle_config ? 1 : 0

  name      = "${local.notebook_name}-lifecycle"
  on_create = var.lifecycle_config_on_create
  on_start  = var.lifecycle_config_on_start
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "notebook" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name              = "/aws/sagemaker/NotebookInstances/${local.notebook_name}"
  retention_in_days = var.cloudwatch_logs_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "${local.notebook_name}-logs"
    }
  )
}

# SageMaker Notebook Instance
resource "aws_sagemaker_notebook_instance" "this" {
  name                    = local.notebook_name
  instance_type           = var.instance_type
  role_arn                = var.iam_role_arn
  subnet_id               = var.subnet_id
  security_groups         = var.security_group_ids
  kms_key_id              = var.kms_key_id
  volume_size             = var.volume_size
  direct_internet_access  = var.direct_internet_access
  root_access             = var.root_access
  platform_identifier     = var.platform_identifier

  # Lifecycle configuration
  lifecycle_config_name = var.create_lifecycle_config ? aws_sagemaker_notebook_instance_lifecycle_configuration.this[0].name : var.lifecycle_config_name

  # Code repositories
  default_code_repository     = var.default_code_repository
  additional_code_repositories = var.additional_code_repositories

  # Instance metadata service configuration
  instance_metadata_service_configuration {
    minimum_instance_metadata_service_version = var.instance_metadata_service_version
  }

  tags = merge(
    var.common_tags,
    {
      Name        = local.notebook_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.notebook,
    aws_sagemaker_notebook_instance_lifecycle_configuration.this
  ]
}

