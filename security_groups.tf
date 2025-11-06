# Security Group for SageMaker Notebook Instance
resource "aws_security_group" "sagemaker_notebook" {
  count = var.create_security_group ? 1 : 0

  name        = var.security_group_name != null ? var.security_group_name : "${var.project_name}-${var.environment}-sagemaker-notebook-sg"
  description = "Security group for SageMaker notebook instance ${var.project_name}-${var.environment}"
  vpc_id      = var.vpc_id

  tags = merge(
    var.default_tags,
    var.security_group_tags,
    {
      Name        = var.security_group_name != null ? var.security_group_name : "${var.project_name}-${var.environment}-sagemaker-notebook-sg"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# Egress rule: Allow all outbound traffic to VPC CIDR
resource "aws_vpc_security_group_egress_rule" "vpc_cidr" {
  count = var.create_security_group ? 1 : 0

  security_group_id = aws_security_group.sagemaker_notebook[0].id
  description       = "Allow all outbound traffic to VPC CIDR"

  ip_protocol = "-1"
  cidr_ipv4   = var.vpc_cidr_block
}

# Egress rule: HTTPS to AWS services (for VPC endpoints)
resource "aws_vpc_security_group_egress_rule" "https_vpc_endpoints" {
  count = var.create_security_group ? 1 : 0

  security_group_id = aws_security_group.sagemaker_notebook[0].id
  description       = "Allow HTTPS to AWS VPC endpoints"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = var.vpc_cidr_block
}

# Egress rule: S3 prefix list (if available in the region)
# Note: This is for S3 gateway endpoint access
resource "aws_vpc_security_group_egress_rule" "s3_prefix_list" {
  count = var.create_security_group && var.enable_s3_vpc_endpoint ? 1 : 0

  security_group_id = aws_security_group.sagemaker_notebook[0].id
  description       = "Allow access to S3 via prefix list"

  ip_protocol    = "tcp"
  from_port      = 443
  to_port        = 443
  prefix_list_id = data.aws_ec2_managed_prefix_list.s3[0].id
}

# Egress rule: Allow DNS resolution
resource "aws_vpc_security_group_egress_rule" "dns" {
  count = var.create_security_group ? 1 : 0

  security_group_id = aws_security_group.sagemaker_notebook[0].id
  description       = "Allow DNS resolution"

  ip_protocol = "udp"
  from_port   = 53
  to_port     = 53
  cidr_ipv4   = var.vpc_cidr_block
}

# Egress rule: NTP for time synchronization
resource "aws_vpc_security_group_egress_rule" "ntp" {
  count = var.create_security_group ? 1 : 0

  security_group_id = aws_security_group.sagemaker_notebook[0].id
  description       = "Allow NTP for time synchronization"

  ip_protocol = "udp"
  from_port   = 123
  to_port     = 123
  cidr_ipv4   = "0.0.0.0/0"
}

# Egress rule: Git operations (HTTPS/SSH)
resource "aws_vpc_security_group_egress_rule" "git_https" {
  count = var.create_security_group && var.enable_git_access ? 1 : 0

  security_group_id = aws_security_group.sagemaker_notebook[0].id
  description       = "Allow HTTPS for Git operations (GitHub, GitLab, etc.)"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "git_ssh" {
  count = var.create_security_group && var.enable_git_access && var.enable_git_ssh ? 1 : 0

  security_group_id = aws_security_group.sagemaker_notebook[0].id
  description       = "Allow SSH for Git operations"

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_ipv4   = "0.0.0.0/0"
}

# Egress rule: Allow outbound to internet if direct internet access is enabled
resource "aws_vpc_security_group_egress_rule" "internet" {
  count = var.create_security_group && var.direct_internet_access == "Enabled" ? 1 : 0

  security_group_id = aws_security_group.sagemaker_notebook[0].id
  description       = "Allow all outbound traffic to internet"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# Ingress rule: Allow traffic from specified CIDR blocks
resource "aws_vpc_security_group_ingress_rule" "cidr_blocks" {
  count = var.create_security_group ? length(var.allowed_cidr_blocks) : 0

  security_group_id = aws_security_group.sagemaker_notebook[0].id
  description       = "Allow HTTPS from specified CIDR block"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = var.allowed_cidr_blocks[count.index]
}

# Ingress rule: Allow traffic from specified security groups
resource "aws_vpc_security_group_ingress_rule" "security_groups" {
  count = var.create_security_group ? length(var.allowed_security_group_ids) : 0

  security_group_id = aws_security_group.sagemaker_notebook[0].id
  description       = "Allow HTTPS from security group"

  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = var.allowed_security_group_ids[count.index]
}

# Self-referencing rule: Allow communication between instances in the same security group
resource "aws_vpc_security_group_ingress_rule" "self" {
  count = var.create_security_group ? 1 : 0

  security_group_id = aws_security_group.sagemaker_notebook[0].id
  description       = "Allow communication within security group"

  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.sagemaker_notebook[0].id
}

resource "aws_vpc_security_group_egress_rule" "self" {
  count = var.create_security_group ? 1 : 0

  security_group_id = aws_security_group.sagemaker_notebook[0].id
  description       = "Allow communication within security group"

  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.sagemaker_notebook[0].id
}

# Data source to get S3 prefix list
data "aws_ec2_managed_prefix_list" "s3" {
  count = var.create_security_group && var.enable_s3_vpc_endpoint ? 1 : 0

  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.${var.aws_region}.s3"]
  }
}

