# VPC Endpoints for SageMaker Notebooks in Private Subnets

# S3 Gateway Endpoint (Free)
resource "aws_vpc_endpoint" "s3" {
  count = var.create_s3_endpoint ? 1 : 0

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  tags = merge(
    var.common_tags,
    {
      Name = "sagemaker-s3-endpoint"
    }
  )
}

# SageMaker API Interface Endpoint
resource "aws_vpc_endpoint" "sagemaker_api" {
  count = var.create_sagemaker_api_endpoint ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "sagemaker-api-endpoint"
    }
  )
}

# SageMaker Runtime Interface Endpoint
resource "aws_vpc_endpoint" "sagemaker_runtime" {
  count = var.create_sagemaker_runtime_endpoint ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "sagemaker-runtime-endpoint"
    }
  )
}

# EC2 Interface Endpoint (for ENI management)
resource "aws_vpc_endpoint" "ec2" {
  count = var.create_ec2_endpoint ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "ec2-endpoint"
    }
  )
}

# CloudWatch Logs Interface Endpoint (optional)
resource "aws_vpc_endpoint" "logs" {
  count = var.create_logs_endpoint ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "cloudwatch-logs-endpoint"
    }
  )
}

# ECR API Interface Endpoint (for Docker images)
resource "aws_vpc_endpoint" "ecr_api" {
  count = var.create_ecr_endpoints ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "ecr-api-endpoint"
    }
  )
}

# ECR DKR Interface Endpoint (for Docker images)
resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.create_ecr_endpoints ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "ecr-dkr-endpoint"
    }
  )
}

