# Shared Security Groups for SageMaker Notebooks

# Security Group for Notebook Instances
resource "aws_security_group" "sagemaker_notebook" {
  name        = var.notebook_sg_name
  description = "Shared security group for SageMaker notebook instances"
  vpc_id      = var.vpc_id

  # Egress to VPC CIDR
  egress {
    description = "Allow all traffic to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Egress to HTTPS for VPC endpoints
  egress {
    description = "HTTPS to VPC endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Self-referencing for communication between notebooks
  egress {
    description     = "Allow communication between notebooks"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    self            = true
  }

  ingress {
    description = "Allow HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    description = "Self-referencing for communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = var.notebook_sg_name
    }
  )
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  count = var.create_vpc_endpoint_sg ? 1 : 0

  name        = var.vpc_endpoint_sg_name
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTPS from notebook security group"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.sagemaker_notebook.id]
  }

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = merge(
    var.common_tags,
    {
      Name = var.vpc_endpoint_sg_name
    }
  )
}

