# IAM Role for SageMaker Notebook Instance
resource "aws_iam_role" "sagemaker_notebook" {
  count = var.create_iam_role ? 1 : 0

  name        = var.iam_role_name != null ? var.iam_role_name : "${var.project_name}-${var.environment}-sagemaker-notebook"
  path        = var.iam_role_path
  description = "IAM role for SageMaker notebook instance ${var.project_name}-${var.environment}"

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

  permissions_boundary = var.iam_role_permissions_boundary

  tags = merge(
    var.default_tags,
    var.iam_role_tags,
    {
      Name        = var.iam_role_name != null ? var.iam_role_name : "${var.project_name}-${var.environment}-sagemaker-notebook"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# Inline policy for S3 access
resource "aws_iam_role_policy" "s3_access" {
  count = var.create_iam_role && length(var.s3_bucket_arns) > 0 ? 1 : 0

  name = "${var.project_name}-${var.environment}-sagemaker-s3-access"
  role = aws_iam_role.sagemaker_notebook[0].id

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

# Inline policy for KMS access (if KMS key is provided)
resource "aws_iam_role_policy" "kms_access" {
  count = var.create_iam_role && var.kms_key_id != null ? 1 : 0

  name = "${var.project_name}-${var.environment}-sagemaker-kms-access"
  role = aws_iam_role.sagemaker_notebook[0].id

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

# Inline policy for SageMaker operations
resource "aws_iam_role_policy" "sagemaker_operations" {
  count = var.create_iam_role ? 1 : 0

  name = "${var.project_name}-${var.environment}-sagemaker-operations"
  role = aws_iam_role.sagemaker_notebook[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:DescribeNotebookInstance",
          "sagemaker:StartNotebookInstance",
          "sagemaker:StopNotebookInstance",
          "sagemaker:UpdateNotebookInstance",
          "sagemaker:CreatePresignedNotebookInstanceUrl",
          "sagemaker:DescribeTrainingJob",
          "sagemaker:CreateTrainingJob",
          "sagemaker:StopTrainingJob",
          "sagemaker:DescribeEndpoint",
          "sagemaker:DescribeEndpointConfig",
          "sagemaker:DescribeModel",
          "sagemaker:CreateModel",
          "sagemaker:CreateEndpointConfig",
          "sagemaker:CreateEndpoint",
          "sagemaker:DeleteModel",
          "sagemaker:DeleteEndpointConfig",
          "sagemaker:DeleteEndpoint",
          "sagemaker:InvokeEndpoint",
          "sagemaker:ListTrainingJobs",
          "sagemaker:ListModels",
          "sagemaker:ListEndpoints",
          "sagemaker:ListNotebookInstances",
          "sagemaker:Search",
          "sagemaker:AddTags",
          "sagemaker:ListTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# Inline policy for CloudWatch Logs
resource "aws_iam_role_policy" "cloudwatch_logs" {
  count = var.create_iam_role && var.enable_cloudwatch_logs ? 1 : 0

  name = "${var.project_name}-${var.environment}-sagemaker-cloudwatch-logs"
  role = aws_iam_role.sagemaker_notebook[0].id

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

# Inline policy for ECR access (for custom containers)
resource "aws_iam_role_policy" "ecr_access" {
  count = var.create_iam_role ? 1 : 0

  name = "${var.project_name}-${var.environment}-sagemaker-ecr-access"
  role = aws_iam_role.sagemaker_notebook[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
        Resource = "*"
      }
    ]
  })
}

# Inline policy for VPC access (required for private subnets)
resource "aws_iam_role_policy" "vpc_access" {
  count = var.create_iam_role ? 1 : 0

  name = "${var.project_name}-${var.environment}-sagemaker-vpc-access"
  role = aws_iam_role.sagemaker_notebook[0].id

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

# Attach additional IAM policies
resource "aws_iam_role_policy_attachment" "additional" {
  count = var.create_iam_role ? length(var.additional_iam_policies) : 0

  role       = aws_iam_role.sagemaker_notebook[0].name
  policy_arn = var.additional_iam_policies[count.index]
}

# CloudWatch Log Group for notebook instance
resource "aws_cloudwatch_log_group" "notebook" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name              = "/aws/sagemaker/NotebookInstances/${local.notebook_name}"
  retention_in_days = var.cloudwatch_logs_retention_days

  tags = merge(
    var.default_tags,
    {
      Name        = "${var.project_name}-${var.environment}-sagemaker-notebook-logs"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

