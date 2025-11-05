locals {
  notebook_name = var.notebook_name != null ? var.notebook_name : "${var.project_name}-${var.environment}-notebook"
  
  security_group_ids = concat(
    var.create_security_group ? [aws_security_group.sagemaker_notebook[0].id] : [],
    var.additional_security_group_ids
  )
  
  iam_role_arn = var.create_iam_role ? aws_iam_role.sagemaker_notebook[0].arn : var.iam_role_arn
}

# Lifecycle Configuration (optional)
resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "this" {
  count = var.create_lifecycle_config ? 1 : 0

  name      = var.lifecycle_config_name != null ? var.lifecycle_config_name : "${var.project_name}-${var.environment}-lifecycle-config"
  on_create = var.lifecycle_config_on_create
  on_start  = var.lifecycle_config_on_start
}

# SageMaker Notebook Instance
resource "aws_sagemaker_notebook_instance" "this" {
  name                    = local.notebook_name
  instance_type           = var.instance_type
  role_arn                = local.iam_role_arn
  subnet_id               = var.subnet_id
  security_groups         = local.security_group_ids
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
    minimum_instance_metadata_service_version = var.instance_metadata_service_configuration.minimum_instance_metadata_service_version
  }

  tags = merge(
    var.default_tags,
    var.notebook_tags,
    {
      Name        = local.notebook_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  # Ensure IAM role and security group are created before the notebook
  depends_on = [
    aws_iam_role.sagemaker_notebook,
    aws_iam_role_policy.sagemaker_operations,
    aws_iam_role_policy.vpc_access,
    aws_security_group.sagemaker_notebook,
    aws_cloudwatch_log_group.notebook
  ]
}

