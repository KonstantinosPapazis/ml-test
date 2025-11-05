# This is an EXAMPLE file showing how to create VPC endpoints required for SageMaker
# in private subnets. You should create these endpoints separately or include them
# in your VPC module.

# Note: This file is provided as reference only. Remove or move to a separate
# module if you want to use it.

# ============================================================================
# S3 Gateway Endpoint (Required for S3 access from private subnets)
# ============================================================================

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  
  # Associate with route tables of private subnets
  route_table_ids = [
    # Add your private subnet route table IDs here
    # "rtb-xxxxxxxxx",
  ]

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.project_name}-${var.environment}-s3-endpoint"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# ============================================================================
# Security Group for VPC Endpoints
# ============================================================================

resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-${var.environment}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.project_name}-${var.environment}-vpc-endpoints-sg"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# Allow HTTPS inbound from VPC CIDR
resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_https" {
  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "Allow HTTPS from VPC"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = var.vpc_cidr_block
}

# Allow HTTPS inbound from SageMaker notebook security group
resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_sagemaker" {
  count = var.create_security_group ? 1 : 0

  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "Allow HTTPS from SageMaker notebook"

  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.sagemaker_notebook[0].id
}

# Allow all outbound
resource "aws_vpc_security_group_egress_rule" "vpc_endpoints_all" {
  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "Allow all outbound"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# ============================================================================
# SageMaker API Interface Endpoint (Required)
# ============================================================================

resource "aws_vpc_endpoint" "sagemaker_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.api"
  vpc_endpoint_type   = "Interface"
  
  # Use multiple subnets across AZs for high availability
  # If vpc_endpoint_subnet_ids is not specified, use the notebook subnet
  subnet_ids = length(var.vpc_endpoint_subnet_ids) > 0 ? var.vpc_endpoint_subnet_ids : [var.subnet_id]
  
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.project_name}-${var.environment}-sagemaker-api-endpoint"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# ============================================================================
# SageMaker Runtime Interface Endpoint (Required for inference)
# ============================================================================

resource "aws_vpc_endpoint" "sagemaker_runtime" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.runtime"
  vpc_endpoint_type   = "Interface"
  
  # Use multiple subnets across AZs for high availability
  subnet_ids = length(var.vpc_endpoint_subnet_ids) > 0 ? var.vpc_endpoint_subnet_ids : [var.subnet_id]
  
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.project_name}-${var.environment}-sagemaker-runtime-endpoint"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# ============================================================================
# EC2 Interface Endpoint (Required for ENI management)
# ============================================================================

resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  
  # Use multiple subnets across AZs for high availability
  subnet_ids = length(var.vpc_endpoint_subnet_ids) > 0 ? var.vpc_endpoint_subnet_ids : [var.subnet_id]
  
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.project_name}-${var.environment}-ec2-endpoint"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# ============================================================================
# CloudWatch Logs Interface Endpoint (Optional but recommended for logging)
# ============================================================================

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  
  # Use multiple subnets across AZs for high availability
  subnet_ids = length(var.vpc_endpoint_subnet_ids) > 0 ? var.vpc_endpoint_subnet_ids : [var.subnet_id]
  
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.project_name}-${var.environment}-logs-endpoint"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# ============================================================================
# ECR API Interface Endpoint (Required for custom container images)
# ============================================================================

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  
  # Use multiple subnets across AZs for high availability
  subnet_ids = length(var.vpc_endpoint_subnet_ids) > 0 ? var.vpc_endpoint_subnet_ids : [var.subnet_id]
  
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.project_name}-${var.environment}-ecr-api-endpoint"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# ============================================================================
# ECR Docker Interface Endpoint (Required for pulling container images)
# ============================================================================

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  
  # Use multiple subnets across AZs for high availability
  subnet_ids = length(var.vpc_endpoint_subnet_ids) > 0 ? var.vpc_endpoint_subnet_ids : [var.subnet_id]
  
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.project_name}-${var.environment}-ecr-dkr-endpoint"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# ============================================================================
# STS Interface Endpoint (Required for assuming roles)
# ============================================================================

resource "aws_vpc_endpoint" "sts" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  
  # Use multiple subnets across AZs for high availability
  subnet_ids = length(var.vpc_endpoint_subnet_ids) > 0 ? var.vpc_endpoint_subnet_ids : [var.subnet_id]
  
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.project_name}-${var.environment}-sts-endpoint"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# ============================================================================
# KMS Interface Endpoint (Required if using KMS encryption)
# ============================================================================

resource "aws_vpc_endpoint" "kms" {
  count = var.kms_key_id != null ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type   = "Interface"
  
  # Use multiple subnets across AZs for high availability
  subnet_ids = length(var.vpc_endpoint_subnet_ids) > 0 ? var.vpc_endpoint_subnet_ids : [var.subnet_id]
  
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.project_name}-${var.environment}-kms-endpoint"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# ============================================================================
# Outputs
# ============================================================================

output "s3_vpc_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "sagemaker_api_vpc_endpoint_id" {
  description = "ID of the SageMaker API VPC endpoint"
  value       = aws_vpc_endpoint.sagemaker_api.id
}

output "sagemaker_runtime_vpc_endpoint_id" {
  description = "ID of the SageMaker Runtime VPC endpoint"
  value       = aws_vpc_endpoint.sagemaker_runtime.id
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the VPC endpoints security group"
  value       = aws_security_group.vpc_endpoints.id
}

