# Shared IAM Role for all SageMaker Notebooks

# IAM Role
resource "aws_iam_role" "sagemaker_shared" {
  name        = var.iam_role_name
  path        = "/"
  description = "Shared IAM role for all SageMaker notebook instances"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = var.iam_role_name
    }
  )
}

# S3 Access Policy
resource "aws_iam_role_policy" "s3_access" {
  name = "${var.iam_role_name}-s3-access"
  role = aws_iam_role.sagemaker_shared.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads",
          "s3:AbortMultipartUpload"
        ]
        Resource = flatten([
          var.s3_bucket_arns,
          [for bucket in var.s3_bucket_arns : "${bucket}/*"]
        ])
      }
    ]
  })
}

# SageMaker Operations Policy
resource "aws_iam_role_policy" "sagemaker_operations" {
  name = "${var.iam_role_name}-sagemaker-operations"
  role = aws_iam_role.sagemaker_shared.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Logs Policy
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.iam_role_name}-cloudwatch-logs"
  role = aws_iam_role.sagemaker_shared.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/sagemaker/*"
      }
    ]
  })
}

# ECR Access Policy
resource "aws_iam_role_policy" "ecr_access" {
  name = "${var.iam_role_name}-ecr-access"
  role = aws_iam_role.sagemaker_shared.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "arn:aws:ecr:${var.aws_region}:*:repository/*"
      }
    ]
  })
}

# VPC Access Policy
resource "aws_iam_role_policy" "vpc_access" {
  name = "${var.iam_role_name}-vpc-access"
  role = aws_iam_role.sagemaker_shared.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:CreateNetworkInterfacePermission",
          "ec2:DeleteNetworkInterface",
          "ec2:DeleteNetworkInterfacePermission",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeVpcs",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:ModifyNetworkInterfaceAttribute"
        ]
        Resource = "*"
      }
    ]
  })
}

# Git/CodeCommit Access Policy
resource "aws_iam_role_policy" "git_access" {
  count = var.enable_git_access ? 1 : 0

  name = "${var.iam_role_name}-git-access"
  role = aws_iam_role.sagemaker_shared.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codecommit:GitPull",
          "codecommit:GitPush",
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:ListBranches",
          "codecommit:ListRepositories",
          "codecommit:GetRepository"
        ]
        Resource = "*"
      }
    ]
  })
}

# Secrets Manager Access Policy
resource "aws_iam_role_policy" "secrets_manager_access" {
  count = var.enable_secrets_manager_access ? 1 : 0

  name = "${var.iam_role_name}-secrets-access"
  role = aws_iam_role.sagemaker_shared.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:*:secret:*git*",
          "arn:aws:secretsmanager:${var.aws_region}:*:secret:*sagemaker*"
        ]
      }
    ]
  })
}

# KMS Access Policy (optional)
resource "aws_iam_role_policy" "kms_access" {
  count = var.kms_key_id != null ? 1 : 0

  name = "${var.iam_role_name}-kms-access"
  role = aws_iam_role.sagemaker_shared.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = var.kms_key_id
      }
    ]
  })
}

