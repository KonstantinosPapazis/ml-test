# Development Notebook Instance

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }
}

# Use the shared notebook module
module "notebook" {
  source = "../../modules/sagemaker-notebook"

  # Basic Configuration
  project_name  = var.project_name
  environment   = var.environment
  notebook_name = var.notebook_name

  # Instance Configuration
  instance_type          = var.instance_type
  volume_size            = var.volume_size
  root_access            = var.root_access
  direct_internet_access = var.direct_internet_access
  platform_identifier    = var.platform_identifier

  # Network Configuration
  subnet_id          = var.subnet_id
  security_group_ids = var.security_group_ids

  # IAM Configuration (from shared-infra/iam)
  iam_role_arn = var.iam_role_arn

  # Encryption
  kms_key_id = var.kms_key_id

  # Lifecycle Configuration
  create_lifecycle_config    = var.create_lifecycle_config
  lifecycle_config_on_create = var.lifecycle_config_on_create
  lifecycle_config_on_start  = var.lifecycle_config_on_start

  # Git Repository
  default_code_repository      = var.default_code_repository
  additional_code_repositories = var.additional_code_repositories

  # Monitoring
  enable_cloudwatch_logs         = var.enable_cloudwatch_logs
  cloudwatch_logs_retention_days = var.cloudwatch_logs_retention_days

  # Tags
  common_tags = var.common_tags
}

