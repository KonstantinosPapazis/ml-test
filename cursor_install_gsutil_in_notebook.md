# Install gsutil in notebook
_Exported on 11/6/2025 at 08:27:41 GMT+1 from Cursor (2.0.63)_

---

**User**

i have created a notebook using this code. 

Now i need to install inside notebook the gsutils so as to download a dataset from google storage bucket

---

**Cursor**

I'll help you install gsutil in your notebook to download data from Google Cloud Storage. Let me first find the notebook file you created.

I don't see any notebook files (*.ipynb) in the current workspace. Could you clarify:

1. **Where is your notebook located?** (Please provide the path)
2. **Or would you like me to create a new notebook** for you with gsutil installation included?

In the meantime, here's how to install and use gsutil in a Jupyter notebook:

**For installing gsutil in a notebook cell:**

```python
# Install gsutil (gcloud SDK includes gsutil)
!pip install gsutil

# Or if you want the full Google Cloud SDK
!pip install google-cloud-storage
```

**Alternative - Using the full gcloud SDK:**

```bash
# Install the full Google Cloud SDK (includes gsutil)
!curl https://sdk.cloud.google.com | bash
!exec -l $SHELL
!gcloud init
```

**After installation, to download from a GCS bucket:**

```python
# Using gsutil command
!gsutil cp gs://your-bucket-name/your-file.csv ./

# Or download entire directory
!gsutil -m cp -r gs://your-bucket-name/your-directory ./
```

**Or using the Python library (recommended):**

```python
from google.cloud import storage

# Download a file
client = storage.Client()
bucket = client.bucket('your-bucket-name')
blob = bucket.blob('your-file.csv')
blob.download_to_filename('local-file.csv')
```

Would you like me to create a complete notebook with these installation steps, or can you share the path to your existing notebook so I can add the gsutil installation to it?

```python
# Install gsutil (gcloud SDK includes gsutil)
!pip install gsutil

# Or if you want the full Google Cloud SDK
!pip install google-cloud-storage
```

```shellscript
# Install the full Google Cloud SDK (includes gsutil)
!curl https://sdk.cloud.google.com | bash
!exec -l $SHELL
!gcloud init
```

```python
# Using gsutil command
!gsutil cp gs://your-bucket-name/your-file.csv ./

# Or download entire directory
!gsutil -m cp -r gs://your-bucket-name/your-directory ./
```

```python
from google.cloud import storage

# Download a file
client = storage.Client()
bucket = client.bucket('your-bucket-name')
blob = bucket.blob('your-file.csv')
blob.download_to_filename('local-file.csv')
```

---

**User**

the datasets should be downloaded inside notebooks or can be in s3 buckets?

---

**Cursor**

Great question! For ML workloads on AWS (which appears to be what you're setting up based on your Terraform infrastructure), **datasets should typically be stored in S3 buckets**, not inside notebooks. Here's why:

## **Recommended: S3 Buckets for Datasets**

**Advantages:**
- ✅ **Persistent storage** - Data survives notebook restarts/terminations
- ✅ **Scalable** - Handle datasets of any size
- ✅ **Cost-effective** - Much cheaper than instance storage
- ✅ **Shared access** - Multiple notebooks/instances can access the same data
- ✅ **Versioning** - Track dataset versions over time
- ✅ **Security** - Fine-grained IAM controls
- ✅ **Integration** - Native integration with SageMaker, EMR, etc.

**Typical workflow:**
```python
# In your notebook
import boto3
import pandas as pd

# Download from S3 to local instance (for processing)
s3 = boto3.client('s3')
s3.download_file('your-bucket-name', 'dataset.csv', '/tmp/dataset.csv')

# Or read directly from S3 (without downloading)
df = pd.read_csv('s3://your-bucket-name/dataset.csv')
```

## **Inside Notebooks (Local Storage): Only for Temporary Data**

**Use local storage only for:**
- Small temporary files during processing
- Intermediate results
- Cache files
- Quick prototyping

**Disadvantages:**
- ❌ Data lost when notebook stops
- ❌ Limited disk space
- ❌ Slower performance with large files
- ❌ Can't share data across instances

## **Your Specific Case: Google Cloud Storage → S3**

Since you mentioned downloading from Google Cloud Storage, here's the recommended approach:

1. **One-time transfer**: Download from GCS → Upload to S3 (do this once, outside notebook)
2. **In notebooks**: Always read from S3

```python
# One-time migration (can run in a notebook or EC2 instance)
# 1. Download from GCS
!gsutil cp gs://gcs-bucket/dataset.csv ./dataset.csv

# 2. Upload to S3
import boto3
s3 = boto3.client('s3')
s3.upload_file('dataset.csv', 'your-s3-bucket', 'datasets/dataset.csv')

# 3. Clean up local copy
!rm dataset.csv
```

Then in your notebooks:
```python
# Always read from S3
df = pd.read_csv('s3://your-s3-bucket/datasets/dataset.csv')
```

## **Question for You:**

Looking at your Terraform files, do you already have an S3 bucket configured for datasets? If not, would you like me to help you:
1. Add an S3 bucket to your Terraform configuration?
2. Set up proper IAM permissions for notebook access to S3?

```python
# In your notebook
import boto3
import pandas as pd

# Download from S3 to local instance (for processing)
s3 = boto3.client('s3')
s3.download_file('your-bucket-name', 'dataset.csv', '/tmp/dataset.csv')

# Or read directly from S3 (without downloading)
df = pd.read_csv('s3://your-bucket-name/dataset.csv')
```

```python
# One-time migration (can run in a notebook or EC2 instance)
# 1. Download from GCS
!gsutil cp gs://gcs-bucket/dataset.csv ./dataset.csv

# 2. Upload to S3
import boto3
s3 = boto3.client('s3')
s3.upload_file('dataset.csv', 'your-s3-bucket', 'datasets/dataset.csv')

# 3. Clean up local copy
!rm dataset.csv
```

```python
# Always read from S3
df = pd.read_csv('s3://your-s3-bucket/datasets/dataset.csv')
```

---

**User**

yes, help me add a bucket in my code and set the proper permissions

---

**Cursor**

I'll help you add an S3 bucket for datasets to your Terraform configuration and set up the proper IAM permissions. Let me first examine your existing Terraform files to understand your setup.

Perfect! I can see your SageMaker notebook infrastructure. Now I'll add an S3 bucket for your datasets with proper IAM permissions. Let me create the necessary files.

```plaintext
# S3 Bucket for ML Datasets
resource "aws_s3_bucket" "datasets" {
  count = var.create_datasets_bucket ? 1 : 0

  bucket = var.datasets_bucket_name != null ? var.datasets_bucket_name : "${var.project_name}-${var.environment}-datasets"

  tags = merge(
    var.default_tags,
    var.datasets_bucket_tags,
    {
      Name        = var.datasets_bucket_name != null ? var.datasets_bucket_name : "${var.project_name}-${var.environment}-datasets"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "ML Datasets Storage"
    }
  )
}

# Enable versioning for data protection
resource "aws_s3_bucket_versioning" "datasets" {
  count = var.create_datasets_bucket && var.enable_datasets_bucket_versioning ? 1 : 0

  bucket = aws_s3_bucket.datasets[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "datasets" {
  count = var.create_datasets_bucket ? 1 : 0

  bucket = aws_s3_bucket.datasets[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.datasets_bucket_kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.datasets_bucket_kms_key_id
    }
    bucket_key_enabled = var.datasets_bucket_kms_key_id != null ? true : false
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "datasets" {
  count = var.create_datasets_bucket ? 1 : 0

  bucket = aws_s3_bucket.datasets[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "datasets" {
  count = var.create_datasets_bucket && var.enable_datasets_bucket_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.datasets[0].id

  # Archive old versions to cheaper storage
  rule {
    id     = "archive-old-versions"
    status = var.datasets_bucket_lifecycle_rules.archive_old_versions.enabled ? "Enabled" : "Disabled"

    noncurrent_version_transition {
      noncurrent_days = var.datasets_bucket_lifecycle_rules.archive_old_versions.transition_days
      storage_class   = var.datasets_bucket_lifecycle_rules.archive_old_versions.storage_class
    }

    filter {}
  }

  # Delete old versions after certain period
  rule {
    id     = "delete-old-versions"
    status = var.datasets_bucket_lifecycle_rules.delete_old_versions.enabled ? "Enabled" : "Disabled"

    noncurrent_version_expiration {
      noncurrent_days = var.datasets_bucket_lifecycle_rules.delete_old_versions.expiration_days
    }

    filter {}
  }

  # Transition current objects to IA after certain period (good for infrequently accessed datasets)
  rule {
    id     = "transition-to-ia"
    status = var.datasets_bucket_lifecycle_rules.transition_to_ia.enabled ? "Enabled" : "Disabled"

    transition {
      days          = var.datasets_bucket_lifecycle_rules.transition_to_ia.transition_days
      storage_class = "STANDARD_IA"
    }

    filter {
      prefix = var.datasets_bucket_lifecycle_rules.transition_to_ia.prefix
    }
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

# Optional: S3 bucket for model artifacts
resource "aws_s3_bucket" "models" {
  count = var.create_models_bucket ? 1 : 0

  bucket = var.models_bucket_name != null ? var.models_bucket_name : "${var.project_name}-${var.environment}-models"

  tags = merge(
    var.default_tags,
    var.models_bucket_tags,
    {
      Name        = var.models_bucket_name != null ? var.models_bucket_name : "${var.project_name}-${var.environment}-models"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "ML Model Artifacts Storage"
    }
  )
}

# Enable versioning for models
resource "aws_s3_bucket_versioning" "models" {
  count = var.create_models_bucket && var.enable_models_bucket_versioning ? 1 : 0

  bucket = aws_s3_bucket.models[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for models
resource "aws_s3_bucket_server_side_encryption_configuration" "models" {
  count = var.create_models_bucket ? 1 : 0

  bucket = aws_s3_bucket.models[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.models_bucket_kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.models_bucket_kms_key_id
    }
    bucket_key_enabled = var.models_bucket_kms_key_id != null ? true : false
  }
}

# Block public access for models
resource "aws_s3_bucket_public_access_block" "models" {
  count = var.create_models_bucket ? 1 : 0

  bucket = aws_s3_bucket.models[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Local variable to combine bucket ARNs
locals {
  created_bucket_arns = concat(
    var.create_datasets_bucket ? [aws_s3_bucket.datasets[0].arn] : [],
    var.create_models_bucket ? [aws_s3_bucket.models[0].arn] : []
  )
  
  # Combine created buckets with user-provided bucket ARNs
  all_s3_bucket_arns = concat(
    local.created_bucket_arns,
    var.s3_bucket_arns
  )
}

```

Now let me update the IAM role to automatically use the created bucket ARNs:

```plaintext
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
  count = var.create_iam_role && length(local.all_s3_bucket_arns) > 0 ? 1 : 0

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
          local.all_s3_bucket_arns,
          [for bucket in local.all_s3_bucket_arns : "${bucket}/*"]
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
          "ecr:CompleteLayerUpload",
          "ecr:CreateRepository",
          "ecr:TagResource"
        ]
        Resource = var.ecr_repository_arns != null ? var.ecr_repository_arns : ["arn:aws:ecr:${var.aws_region}:*:repository/*"]
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

# Inline policy for Git/CodeCommit access
resource "aws_iam_role_policy" "git_access" {
  count = var.create_iam_role && var.enable_git_access ? 1 : 0

  name = "${var.project_name}-${var.environment}-sagemaker-git-access"
  role = aws_iam_role.sagemaker_notebook[0].id

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
          "codecommit:GetRepository",
          "codecommit:CreateBranch"
        ]
        Resource = var.codecommit_repository_arns != null ? var.codecommit_repository_arns : ["*"]
      }
    ]
  })
}

# Inline policy for Secrets Manager access (for Git credentials)
resource "aws_iam_role_policy" "secrets_manager_access" {
  count = var.create_iam_role && var.enable_secrets_manager_access ? 1 : 0

  name = "${var.project_name}-${var.environment}-sagemaker-secrets-access"
  role = aws_iam_role.sagemaker_notebook[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secrets_manager_secret_arns != null ? var.secrets_manager_secret_arns : [
          "arn:aws:secretsmanager:${var.aws_region}:*:secret:*git*",
          "arn:aws:secretsmanager:${var.aws_region}:*:secret:*sagemaker*"
        ]
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


```

Now let me add the necessary variables to `variables.tf`:

```plaintext
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name to be used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

# SageMaker Notebook Instance Configuration
variable "notebook_name" {
  description = "Name of the SageMaker notebook instance"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type for the notebook instance"
  type        = string
  default     = "ml.t3.medium"
}

variable "volume_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 5
  validation {
    condition     = var.volume_size >= 5 && var.volume_size <= 16384
    error_message = "Volume size must be between 5 GB and 16384 GB."
  }
}

variable "platform_identifier" {
  description = "Platform identifier for the notebook instance (notebook-al2-v2, notebook-al1-v1, etc.)"
  type        = string
  default     = "notebook-al2-v2"
}

variable "root_access" {
  description = "Whether root access is enabled for notebook instance users"
  type        = string
  default     = "Disabled"
  validation {
    condition     = contains(["Enabled", "Disabled"], var.root_access)
    error_message = "Root access must be either 'Enabled' or 'Disabled'."
  }
}

variable "direct_internet_access" {
  description = "Whether direct internet access is enabled (Enabled or Disabled)"
  type        = string
  default     = "Disabled"
  validation {
    condition     = contains(["Enabled", "Disabled"], var.direct_internet_access)
    error_message = "Direct internet access must be either 'Enabled' or 'Disabled'."
  }
}

# Network Configuration
variable "vpc_id" {
  description = "VPC ID where the notebook instance will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the notebook instance (should be private subnet). Note: SageMaker notebooks only support a single subnet."
  type        = string
}

variable "vpc_endpoint_subnet_ids" {
  description = "List of subnet IDs for VPC endpoints (recommended: use multiple subnets across AZs for high availability)"
  type        = list(string)
  default     = []
}

variable "additional_security_group_ids" {
  description = "Additional security group IDs to attach to the notebook instance"
  type        = list(string)
  default     = []
}

# Security Group Configuration
variable "create_security_group" {
  description = "Whether to create a new security group for the notebook instance"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name for the security group (if creating new one)"
  type        = string
  default     = null
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the notebook instance"
  type        = list(string)
  default     = []
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block for internal communication"
  type        = string
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to access the notebook instance"
  type        = list(string)
  default     = []
}

# VPC Endpoint Configuration (for private subnet access)
variable "enable_s3_vpc_endpoint" {
  description = "Whether to allow traffic to S3 VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_sagemaker_api_vpc_endpoint" {
  description = "Whether to allow traffic to SageMaker API VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_sagemaker_runtime_vpc_endpoint" {
  description = "Whether to allow traffic to SageMaker Runtime VPC endpoint"
  type        = bool
  default     = true
}

# IAM Configuration
variable "create_iam_role" {
  description = "Whether to create a new IAM role for the notebook instance"
  type        = bool
  default     = true
}

variable "iam_role_arn" {
  description = "ARN of existing IAM role to use (if not creating new one)"
  type        = string
  default     = null
}

variable "iam_role_name" {
  description = "Name for the IAM role (if creating new one)"
  type        = string
  default     = null
}

variable "iam_role_path" {
  description = "Path for the IAM role"
  type        = string
  default     = "/"
}

variable "iam_role_permissions_boundary" {
  description = "ARN of the permissions boundary policy to attach to the IAM role"
  type        = string
  default     = null
}

variable "additional_iam_policies" {
  description = "Additional IAM policy ARNs to attach to the notebook role"
  type        = list(string)
  default     = []
}

variable "s3_bucket_arns" {
  description = "Additional S3 bucket ARNs that the notebook instance needs access to (beyond the managed datasets/models buckets)"
  type        = list(string)
  default     = []
}

# S3 Datasets Bucket Configuration
variable "create_datasets_bucket" {
  description = "Whether to create an S3 bucket for ML datasets"
  type        = bool
  default     = true
}

variable "datasets_bucket_name" {
  description = "Name for the datasets S3 bucket (if not provided, will be auto-generated)"
  type        = string
  default     = null
}

variable "enable_datasets_bucket_versioning" {
  description = "Whether to enable versioning for the datasets bucket"
  type        = bool
  default     = true
}

variable "datasets_bucket_kms_key_id" {
  description = "KMS key ID for encrypting the datasets bucket (if null, uses AES256)"
  type        = string
  default     = null
}

variable "enable_datasets_bucket_lifecycle" {
  description = "Whether to enable lifecycle policies for the datasets bucket"
  type        = bool
  default     = true
}

variable "datasets_bucket_lifecycle_rules" {
  description = "Lifecycle rules for the datasets bucket"
  type = object({
    archive_old_versions = object({
      enabled         = bool
      transition_days = number
      storage_class   = string
    })
    delete_old_versions = object({
      enabled        = bool
      expiration_days = number
    })
    transition_to_ia = object({
      enabled         = bool
      transition_days = number
      prefix          = string
    })
  })
  default = {
    archive_old_versions = {
      enabled         = true
      transition_days = 30
      storage_class   = "GLACIER"
    }
    delete_old_versions = {
      enabled        = true
      expiration_days = 90
    }
    transition_to_ia = {
      enabled         = false
      transition_days = 90
      prefix          = "archive/"
    }
  }
}

variable "datasets_bucket_tags" {
  description = "Additional tags for the datasets bucket"
  type        = map(string)
  default     = {}
}

# S3 Models Bucket Configuration
variable "create_models_bucket" {
  description = "Whether to create an S3 bucket for ML model artifacts"
  type        = bool
  default     = true
}

variable "models_bucket_name" {
  description = "Name for the models S3 bucket (if not provided, will be auto-generated)"
  type        = string
  default     = null
}

variable "enable_models_bucket_versioning" {
  description = "Whether to enable versioning for the models bucket"
  type        = bool
  default     = true
}

variable "models_bucket_kms_key_id" {
  description = "KMS key ID for encrypting the models bucket (if null, uses AES256)"
  type        = string
  default     = null
}

variable "models_bucket_tags" {
  description = "Additional tags for the models bucket"
  type        = map(string)
  default     = {}
}

variable "ecr_repository_arns" {
  description = "ECR repository ARNs that the notebook needs push access to (use null for all repositories in the account)"
  type        = list(string)
  default     = null
}

# Git Access Configuration
variable "enable_git_access" {
  description = "Whether to enable Git/CodeCommit access for the notebook instance"
  type        = bool
  default     = true
}

variable "codecommit_repository_arns" {
  description = "CodeCommit repository ARNs that the notebook needs access to (use null for all repositories)"
  type        = list(string)
  default     = null
}

variable "enable_secrets_manager_access" {
  description = "Whether to enable Secrets Manager access for Git credentials"
  type        = bool
  default     = true
}

variable "secrets_manager_secret_arns" {
  description = "Secrets Manager secret ARNs for Git credentials (use null for secrets matching *git* and *sagemaker*)"
  type        = list(string)
  default     = null
}

variable "enable_git_ssh" {
  description = "Whether to enable SSH access for Git operations (port 22)"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting the notebook instance storage volume"
  type        = string
  default     = null
}

# Lifecycle Configuration
variable "lifecycle_config_name" {
  description = "Name of the lifecycle configuration to attach"
  type        = string
  default     = null
}

variable "create_lifecycle_config" {
  description = "Whether to create a lifecycle configuration"
  type        = bool
  default     = false
}

variable "lifecycle_config_on_create" {
  description = "Base64-encoded shell script to run on notebook instance creation"
  type        = string
  default     = null
}

variable "lifecycle_config_on_start" {
  description = "Base64-encoded shell script to run on notebook instance start"
  type        = string
  default     = null
}

# Code Repository
variable "default_code_repository" {
  description = "The Git repository to associate with the notebook instance as its default code repository"
  type        = string
  default     = null
}

variable "additional_code_repositories" {
  description = "An array of up to three Git repositories to associate with the notebook instance"
  type        = list(string)
  default     = []
}

# Monitoring and Logging
variable "enable_cloudwatch_logs" {
  description = "Whether to enable CloudWatch logs for the notebook instance"
  type        = bool
  default     = true
}

variable "cloudwatch_logs_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

# Tags
variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "notebook_tags" {
  description = "Additional tags for the notebook instance"
  type        = map(string)
  default     = {}
}

variable "security_group_tags" {
  description = "Additional tags for the security group"
  type        = map(string)
  default     = {}
}

variable "iam_role_tags" {
  description = "Additional tags for the IAM role"
  type        = map(string)
  default     = {}
}

# Advanced Configuration
variable "instance_metadata_service_configuration" {
  description = "Configuration for Instance Metadata Service"
  type = object({
    minimum_instance_metadata_service_version = string
  })
  default = {
    minimum_instance_metadata_service_version = "2"
  }
}


```

Now let me add outputs for the S3 buckets:

```plaintext
output "notebook_instance_name" {
  description = "Name of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.this.name
}

output "notebook_instance_arn" {
  description = "ARN of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.this.arn
}

output "notebook_instance_url" {
  description = "URL of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.this.url
}

output "notebook_instance_id" {
  description = "ID of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.this.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role used by the notebook instance"
  value       = local.iam_role_arn
}

output "iam_role_name" {
  description = "Name of the IAM role used by the notebook instance"
  value       = var.create_iam_role ? aws_iam_role.sagemaker_notebook[0].name : null
}

output "security_group_id" {
  description = "ID of the security group created for the notebook instance"
  value       = var.create_security_group ? aws_security_group.sagemaker_notebook[0].id : null
}

output "security_group_arn" {
  description = "ARN of the security group created for the notebook instance"
  value       = var.create_security_group ? aws_security_group.sagemaker_notebook[0].arn : null
}

output "security_group_name" {
  description = "Name of the security group created for the notebook instance"
  value       = var.create_security_group ? aws_security_group.sagemaker_notebook[0].name : null
}

output "all_security_group_ids" {
  description = "All security group IDs attached to the notebook instance"
  value       = local.security_group_ids
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for the notebook instance"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.notebook[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for the notebook instance"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.notebook[0].arn : null
}

output "lifecycle_config_name" {
  description = "Name of the lifecycle configuration"
  value       = var.create_lifecycle_config ? aws_sagemaker_notebook_instance_lifecycle_configuration.this[0].name : var.lifecycle_config_name
}

output "lifecycle_config_arn" {
  description = "ARN of the lifecycle configuration"
  value       = var.create_lifecycle_config ? aws_sagemaker_notebook_instance_lifecycle_configuration.this[0].arn : null
}

output "network_interface_id" {
  description = "Network interface ID of the notebook instance"
  value       = aws_sagemaker_notebook_instance.this.network_interface_id
}

# S3 Bucket Outputs
output "datasets_bucket_name" {
  description = "Name of the datasets S3 bucket"
  value       = var.create_datasets_bucket ? aws_s3_bucket.datasets[0].id : null
}

output "datasets_bucket_arn" {
  description = "ARN of the datasets S3 bucket"
  value       = var.create_datasets_bucket ? aws_s3_bucket.datasets[0].arn : null
}

output "datasets_bucket_regional_domain_name" {
  description = "Regional domain name of the datasets S3 bucket"
  value       = var.create_datasets_bucket ? aws_s3_bucket.datasets[0].bucket_regional_domain_name : null
}

output "models_bucket_name" {
  description = "Name of the models S3 bucket"
  value       = var.create_models_bucket ? aws_s3_bucket.models[0].id : null
}

output "models_bucket_arn" {
  description = "ARN of the models S3 bucket"
  value       = var.create_models_bucket ? aws_s3_bucket.models[0].arn : null
}

output "models_bucket_regional_domain_name" {
  description = "Regional domain name of the models S3 bucket"
  value       = var.create_models_bucket ? aws_s3_bucket.models[0].bucket_regional_domain_name : null
}

output "all_s3_bucket_arns" {
  description = "All S3 bucket ARNs accessible by the notebook instance"
  value       = local.all_s3_bucket_arns
}


```

Now let me create a helpful guide for using the S3 buckets from your notebook:

```markdown
# S3 Datasets and Models Storage Guide

This guide explains how to use the automatically provisioned S3 buckets for storing and accessing ML datasets and model artifacts from your SageMaker notebook.

## Overview

The Terraform configuration automatically creates two S3 buckets:
1. **Datasets Bucket**: For storing training/testing datasets
2. **Models Bucket**: For storing trained model artifacts

Both buckets come with:
- ✅ Encryption at rest (AES256 or KMS)
- ✅ Versioning enabled (protects against accidental deletion)
- ✅ Public access blocked
- ✅ Lifecycle policies for cost optimization
- ✅ Automatic IAM permissions for your SageMaker notebook

## Getting Bucket Names

After deploying with Terraform, get your bucket names:

```bash
terraform output datasets_bucket_name
terraform output models_bucket_name
```

Or view all S3 bucket ARNs accessible by your notebook:

```bash
terraform output all_s3_bucket_arns
```

## Using S3 from Your Jupyter Notebook

### Method 1: Using Pandas (Easiest)

```python
import pandas as pd

# Read CSV directly from S3
df = pd.read_csv('s3://your-project-dev-datasets/raw/dataset.csv')

# Write CSV to S3
df.to_csv('s3://your-project-dev-datasets/processed/cleaned_data.csv', index=False)

# Read Parquet (more efficient for large datasets)
df = pd.read_parquet('s3://your-project-dev-datasets/raw/dataset.parquet')

# Write Parquet
df.to_parquet('s3://your-project-dev-datasets/processed/cleaned_data.parquet')
```

### Method 2: Using Boto3 (AWS SDK)

```python
import boto3
import pandas as pd

# Initialize S3 client
s3 = boto3.client('s3')

# Get bucket name from environment or config
DATASETS_BUCKET = 'your-project-dev-datasets'
MODELS_BUCKET = 'your-project-dev-models'

# Download a file from S3
s3.download_file(
    Bucket=DATASETS_BUCKET,
    Key='raw/dataset.csv',
    Filename='/tmp/dataset.csv'
)

# Upload a file to S3
s3.upload_file(
    Filename='/tmp/processed_data.csv',
    Bucket=DATASETS_BUCKET,
    Key='processed/processed_data.csv'
)

# List files in a bucket
response = s3.list_objects_v2(
    Bucket=DATASETS_BUCKET,
    Prefix='raw/'
)
for obj in response.get('Contents', []):
    print(obj['Key'])

# Copy files between buckets
s3.copy_object(
    CopySource={'Bucket': DATASETS_BUCKET, 'Key': 'raw/dataset.csv'},
    Bucket=DATASETS_BUCKET,
    Key='archive/dataset-backup.csv'
)
```

### Method 3: Using SageMaker SDK

```python
import sagemaker
from sagemaker.s3 import S3Uploader, S3Downloader

# Get default bucket or use your custom bucket
sagemaker_session = sagemaker.Session()
default_bucket = sagemaker_session.default_bucket()

# Or use your custom bucket
DATASETS_BUCKET = 'your-project-dev-datasets'

# Upload a file or directory
S3Uploader.upload(
    local_path='./local_dataset.csv',
    desired_s3_uri=f's3://{DATASETS_BUCKET}/raw/dataset.csv',
    sagemaker_session=sagemaker_session
)

# Download a file or directory
S3Downloader.download(
    s3_uri=f's3://{DATASETS_BUCKET}/raw/dataset.csv',
    local_path='/tmp/',
    sagemaker_session=sagemaker_session
)

# List files
files = S3Downloader.list(
    s3_uri=f's3://{DATASETS_BUCKET}/raw/',
    sagemaker_session=sagemaker_session
)
print(files)
```

## Recommended Directory Structure

Organize your S3 buckets with this structure:

### Datasets Bucket
```
your-project-dev-datasets/
├── raw/                    # Original, unprocessed data
│   ├── dataset1.csv
│   └── dataset2.parquet
├── processed/              # Cleaned, transformed data
│   ├── train.csv
│   ├── validation.csv
│   └── test.csv
├── features/              # Feature engineering outputs
│   └── feature_store.parquet
└── archive/               # Old versions (lifecycle rules apply)
    └── dataset1_v1.csv
```

### Models Bucket
```
your-project-dev-models/
├── experiments/           # Experimental models
│   └── exp-001/
│       ├── model.pkl
│       └── metrics.json
├── production/            # Production-ready models
│   └── model-v1.0/
│       ├── model.tar.gz
│       ├── model_metadata.json
│       └── requirements.txt
└── checkpoints/           # Training checkpoints
    └── checkpoint-epoch-10.pth
```

## Migrating Data from Google Cloud Storage to S3

If you need to migrate datasets from GCS to S3 (one-time operation):

### Option 1: Using gsutil and AWS CLI (from your notebook)

```bash
# Install gsutil
!pip install gsutil

# Authenticate with GCS (if needed)
# You may need to set up credentials

# Download from GCS
!gsutil -m cp -r gs://your-gcs-bucket/dataset ./temp_dataset/

# Upload to S3 using AWS CLI
!aws s3 cp ./temp_dataset/ s3://your-project-dev-datasets/raw/ --recursive

# Clean up local copy
!rm -rf ./temp_dataset
```

### Option 2: Python Script (from your notebook)

```python
import boto3
import subprocess
import os

# Configuration
GCS_BUCKET = 'your-gcs-bucket'
GCS_PATH = 'path/to/dataset'
S3_BUCKET = 'your-project-dev-datasets'
S3_PATH = 'raw/dataset'
TEMP_DIR = '/tmp/dataset_migration'

# Create temp directory
os.makedirs(TEMP_DIR, exist_ok=True)

# Download from GCS
subprocess.run([
    'gsutil', '-m', 'cp', '-r',
    f'gs://{GCS_BUCKET}/{GCS_PATH}',
    TEMP_DIR
])

# Upload to S3
s3 = boto3.client('s3')
for root, dirs, files in os.walk(TEMP_DIR):
    for file in files:
        local_path = os.path.join(root, file)
        relative_path = os.path.relpath(local_path, TEMP_DIR)
        s3_key = f'{S3_PATH}/{relative_path}'
        
        print(f'Uploading {local_path} to s3://{S3_BUCKET}/{s3_key}')
        s3.upload_file(local_path, S3_BUCKET, s3_key)

# Clean up
import shutil
shutil.rmtree(TEMP_DIR)
print('Migration complete!')
```

### Option 3: AWS DataSync (for large datasets, recommended)

For very large datasets (>1TB), use AWS DataSync:
1. Set up a DataSync task from GCS to S3 (one-time setup)
2. More cost-effective and faster for large transfers
3. See: https://aws.amazon.com/datasync/

## Working with Large Datasets

### Chunked Reading (for datasets larger than memory)

```python
import pandas as pd

# Read CSV in chunks
chunk_size = 100000
for chunk in pd.read_csv('s3://your-bucket/large_dataset.csv', chunksize=chunk_size):
    # Process each chunk
    processed_chunk = process_data(chunk)
    # Write results incrementally
    processed_chunk.to_csv('s3://your-bucket/processed/output.csv', mode='a', header=False)
```

### Using PyArrow for Large Files

```python
import pyarrow.parquet as pq
import s3fs

# Create S3 filesystem
s3 = s3fs.S3FileSystem()

# Read Parquet with PyArrow (memory efficient)
parquet_file = pq.ParquetFile(s3.open('your-bucket/large_dataset.parquet'))

# Read in batches
for batch in parquet_file.iter_batches(batch_size=10000):
    df = batch.to_pandas()
    # Process batch
    process_batch(df)
```

## Cost Optimization Tips

1. **Use Parquet format** instead of CSV for large datasets (10-100x smaller)
2. **Enable lifecycle policies** (automatically configured):
   - Old versions moved to Glacier after 30 days
   - Deleted after 90 days
3. **Delete temporary files** after processing
4. **Use S3 Intelligent-Tiering** for unpredictable access patterns
5. **Compress data** before uploading (gzip, bzip2)

## Example: Complete ML Workflow

```python
import pandas as pd
import boto3
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
import joblib

# Configuration
DATASETS_BUCKET = 'your-project-dev-datasets'
MODELS_BUCKET = 'your-project-dev-models'
s3 = boto3.client('s3')

# 1. Load data from S3
print("Loading data from S3...")
df = pd.read_csv(f's3://{DATASETS_BUCKET}/raw/dataset.csv')

# 2. Process data
print("Processing data...")
# Your data processing code here
X = df.drop('target', axis=1)
y = df['target']

# 3. Split data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

# 4. Save processed data back to S3
print("Saving processed data to S3...")
X_train.to_parquet(f's3://{DATASETS_BUCKET}/processed/X_train.parquet')
X_test.to_parquet(f's3://{DATASETS_BUCKET}/processed/X_test.parquet')
y_train.to_csv(f's3://{DATASETS_BUCKET}/processed/y_train.csv', index=False)
y_test.to_csv(f's3://{DATASETS_BUCKET}/processed/y_test.csv', index=False)

# 5. Train model
print("Training model...")
model = RandomForestClassifier(n_estimators=100)
model.fit(X_train, y_train)

# 6. Save model to S3
print("Saving model to S3...")
local_model_path = '/tmp/model.pkl'
joblib.dump(model, local_model_path)
s3.upload_file(
    local_model_path, 
    MODELS_BUCKET, 
    'production/model-v1.0/model.pkl'
)

# 7. Load model from S3 (for inference)
print("Loading model from S3...")
s3.download_file(
    MODELS_BUCKET,
    'production/model-v1.0/model.pkl',
    '/tmp/loaded_model.pkl'
)
loaded_model = joblib.load('/tmp/loaded_model.pkl')

# 8. Make predictions
predictions = loaded_model.predict(X_test)
print(f"Accuracy: {(predictions == y_test).mean():.2f}")
```

## Troubleshooting

### Permission Denied Error

If you get permission errors, ensure:
1. The IAM role is properly attached to your notebook
2. The bucket ARN is included in `s3_bucket_arns` or buckets were created by Terraform
3. Run: `terraform output all_s3_bucket_arns` to verify bucket permissions

### Bucket Not Found

```python
# Verify bucket exists
import boto3
s3 = boto3.client('s3')
try:
    s3.head_bucket(Bucket='your-bucket-name')
    print("Bucket exists and is accessible")
except Exception as e:
    print(f"Error: {e}")
```

### Slow Data Transfer

For better performance:
1. Use Parquet instead of CSV
2. Enable multipart upload for large files
3. Use S3 Transfer Acceleration (enable in bucket settings)
4. Consider using EC2 in the same region as your S3 bucket

## Security Best Practices

1. ✅ **Never hardcode credentials** - use IAM roles (automatically configured)
2. ✅ **Enable versioning** - protects against accidental deletion (enabled by default)
3. ✅ **Use encryption** - enabled by default (AES256 or KMS)
4. ✅ **Block public access** - enabled by default
5. ✅ **Use VPC endpoints** - for private subnet access (configure if needed)
6. ✅ **Tag your data** - use S3 object tagging for data governance

## Additional Resources

- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [Boto3 S3 Documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html)
- [SageMaker Python SDK](https://sagemaker.readthedocs.io/)
- [Pandas S3 Integration](https://pandas.pydata.org/docs/user_guide/io.html#s3)

## Get Bucket Information

In your notebook, you can get bucket information programmatically:

```python
import boto3
import sagemaker

# Option 1: Using SageMaker session
session = sagemaker.Session()
default_bucket = session.default_bucket()
print(f"Default SageMaker bucket: {default_bucket}")

# Option 2: List all accessible buckets
s3 = boto3.client('s3')
response = s3.list_buckets()
print("Accessible S3 buckets:")
for bucket in response['Buckets']:
    if 'dataset' in bucket['Name'] or 'model' in bucket['Name']:
        print(f"  - {bucket['Name']}")
```

---

**Note**: Replace `your-project-dev-datasets` and `your-project-dev-models` with your actual bucket names from `terraform output`.

```

Now let me check for any linting errors:

Perfect! Now let me create an example configuration file showing how to use the S3 buckets:

```plaintext
# Example Terraform Variables for SageMaker Notebook with S3 Buckets
# Copy this file to terraform.tfvars and customize for your environment

# Basic Configuration
project_name = "ml-project"
environment  = "dev"
aws_region   = "us-east-1"

# Network Configuration (replace with your actual VPC/subnet IDs)
vpc_id          = "vpc-0123456789abcdef0"
subnet_id       = "subnet-0123456789abcdef0"
vpc_cidr_block  = "10.0.0.0/16"

# SageMaker Notebook Configuration
instance_type = "ml.t3.medium"  # or ml.t3.large, ml.t3.xlarge for more power
volume_size   = 20              # GB of EBS storage
root_access   = "Enabled"       # Enable for pip installs and system packages

# S3 Buckets Configuration
create_datasets_bucket = true
create_models_bucket   = true

# Optional: Custom bucket names (if not provided, auto-generated as project-environment-datasets/models)
# datasets_bucket_name = "my-company-ml-datasets"
# models_bucket_name   = "my-company-ml-models"

# S3 Bucket Features
enable_datasets_bucket_versioning = true  # Recommended: protects against accidental deletion
enable_models_bucket_versioning   = true  # Recommended: track model versions

# Lifecycle policies for cost optimization
enable_datasets_bucket_lifecycle = true

# Customize lifecycle rules (optional)
datasets_bucket_lifecycle_rules = {
  archive_old_versions = {
    enabled         = true
    transition_days = 30        # Move old versions to Glacier after 30 days
    storage_class   = "GLACIER"
  }
  delete_old_versions = {
    enabled        = true
    expiration_days = 90        # Delete old versions after 90 days
  }
  transition_to_ia = {
    enabled         = false     # Set to true to move infrequently accessed data to IA
    transition_days = 90
    prefix          = "archive/"
  }
}

# Optional: Add additional S3 buckets (beyond the managed datasets/models buckets)
# s3_bucket_arns = [
#   "arn:aws:s3:::another-bucket-name",
#   "arn:aws:s3:::yet-another-bucket"
# ]

# Optional: KMS encryption (if not provided, uses AES256)
# datasets_bucket_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
# models_bucket_kms_key_id   = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

# Security Configuration
create_security_group = true
direct_internet_access = "Disabled"  # Recommended for security

# IAM Configuration
create_iam_role = true

# Git Configuration (for code repositories)
enable_git_access              = true
enable_secrets_manager_access  = true

# CloudWatch Logs
enable_cloudwatch_logs         = true
cloudwatch_logs_retention_days = 30

# Tags
default_tags = {
  Project     = "ML Project"
  Environment = "Development"
  Team        = "Data Science"
  CostCenter  = "ML-001"
}

# Additional bucket tags
datasets_bucket_tags = {
  DataClassification = "Confidential"
  Compliance        = "GDPR"
}

models_bucket_tags = {
  Purpose = "Production ML Models"
}

```

Now let me validate the Terraform configuration:

Let me format the Terraform code and do a basic syntax check:

Let me check the current README to see where I should add information about the S3 buckets:

Now let me update the README to include information about the S3 buckets:

```markdown
# Production-Ready SageMaker Notebook Terraform Module

This Terraform configuration provides a complete, production-ready deployment of an AWS SageMaker notebook instance with full support for private subnets, comprehensive IAM roles, and security groups.

## Features

- ✅ **Complete IAM Role Configuration** - Includes all necessary permissions for SageMaker operations
- ✅ **Managed S3 Buckets** - Automatic creation of datasets and models buckets with versioning, encryption, and lifecycle policies (see [S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md))
- ✅ **Private Subnet Support** - Designed for deployment in private subnets with VPC endpoints
- ✅ **Security Groups** - Pre-configured security groups with all necessary rules
- ✅ **Git Integration** - Full support for GitHub, GitLab, Bitbucket, and AWS CodeCommit (see [GIT_SETUP.md](GIT_SETUP.md))
- ✅ **Encryption Support** - Optional KMS encryption for EBS volumes and S3 buckets
- ✅ **CloudWatch Logs** - Integrated logging and monitoring
- ✅ **Lifecycle Configuration** - Support for custom startup scripts
- ✅ **Fully Parameterized** - All options are configurable via variables
- ✅ **Production Best Practices** - Follows AWS best practices for security and operations

## Architecture

This module creates the following resources:

1. **SageMaker Notebook Instance** - The main ML development environment
2. **IAM Role** - With policies for SageMaker, S3, ECR, CloudWatch, VPC, KMS, Git (CodeCommit), and Secrets Manager
3. **Security Group** - With rules for private subnet communication, VPC endpoints, and Git access
4. **CloudWatch Log Group** - For notebook instance logs
5. **Lifecycle Configuration** (optional) - For custom initialization scripts

## Prerequisites

Before using this module, ensure you have:

1. **AWS Account** with appropriate permissions
2. **VPC with Private Subnets** configured
3. **VPC Endpoints** (recommended for private subnets):
   - S3 Gateway Endpoint
   - SageMaker API Interface Endpoint
   - SageMaker Runtime Interface Endpoint
   - EC2 Interface Endpoint (for ENI management)
4. **Terraform >= 1.0** installed
5. **AWS Provider >= 5.0** configured

## Quick Start

### 1. Copy the Example Variables File

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit `terraform.tfvars`

Update the required variables:

```hcl
# Minimum required variables
aws_region     = "us-east-1"
project_name   = "my-ml-project"
environment    = "dev"
vpc_id         = "vpc-xxxxxxxxx"
subnet_id      = "subnet-xxxxxxxxx"  # Private subnet
vpc_cidr_block = "10.0.0.0/16"

# S3 buckets for data access
s3_bucket_arns = [
  "arn:aws:s3:::my-ml-data-bucket"
]
```

### 3. Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 4. Access Your Notebook

After deployment, access the notebook through the AWS Console or use the presigned URL:

```bash
# Get the notebook instance name
terraform output notebook_instance_name

# Open in AWS Console
# Navigate to: SageMaker > Notebook Instances > [notebook-name] > Open JupyterLab
```

## Configuration Options

### Instance Types

Choose based on your workload:

| Instance Type | vCPUs | Memory | Use Case |
|--------------|-------|--------|----------|
| `ml.t3.medium` | 2 | 4 GB | Development, light workloads |
| `ml.t3.xlarge` | 4 | 16 GB | General purpose |
| `ml.m5.xlarge` | 4 | 16 GB | Balanced compute/memory |
| `ml.m5.2xlarge` | 8 | 32 GB | Larger datasets |
| `ml.p3.2xlarge` | 8 | 61 GB | GPU workloads |
| `ml.p3.8xlarge` | 32 | 244 GB | Heavy GPU workloads |

### Network Configuration

#### For Private Subnets (Recommended)

```hcl
direct_internet_access = "Disabled"
subnet_id              = "subnet-private-xxx"

# Ensure VPC endpoints are configured
enable_s3_vpc_endpoint                = true
enable_sagemaker_api_vpc_endpoint     = true
enable_sagemaker_runtime_vpc_endpoint = true
```

#### For Public Subnets

```hcl
direct_internet_access = "Enabled"
subnet_id              = "subnet-public-xxx"
```

### Security Configuration

#### Using Auto-Created Security Group

```hcl
create_security_group = true
allowed_cidr_blocks = [
  "10.0.0.0/16"  # Your VPC CIDR
]
```

#### Using Existing Security Group

```hcl
create_security_group = false
additional_security_group_ids = [
  "sg-existing123"
]
```

### IAM Configuration

#### Auto-Create IAM Role (Recommended)

```hcl
create_iam_role = true
s3_bucket_arns = [
  "arn:aws:s3:::my-data-bucket"
]
```

#### Use Existing IAM Role

```hcl
create_iam_role = false
iam_role_arn    = "arn:aws:iam::123456789012:role/existing-role"
```

### Lifecycle Configuration

Use lifecycle configurations to install packages or configure the environment:

```hcl
create_lifecycle_config = true

lifecycle_config_on_create = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Install system packages
  sudo yum update -y
  sudo yum install -y htop git
  
  # Install Python packages
  sudo -u ec2-user -i <<'USEREOF'
  source /home/ec2-user/anaconda3/bin/activate JupyterSystemEnv
  pip install --upgrade pip
  pip install pandas numpy scikit-learn matplotlib seaborn
  source /home/ec2-user/anaconda3/bin/deactivate
  USEREOF
  
  echo "Notebook instance created at $(date)"
EOF
)

lifecycle_config_on_start = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Run on every start
  echo "Notebook instance started at $(date)"
  
  # Pull latest code from git
  cd /home/ec2-user/SageMaker
  if [ -d ".git" ]; then
    git pull
  fi
EOF
)
```

### Encryption

Enable EBS volume encryption:

```hcl
kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
```

## VPC Endpoints Setup

For private subnet deployments, create the following VPC endpoints in your VPC:

### S3 Gateway Endpoint

```hcl
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  
  route_table_ids = [aws_route_table.private.id]
}
```

### SageMaker API Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "sagemaker_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

### SageMaker Runtime Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "sagemaker_runtime" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

### EC2 Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

## Security Groups Explained

The module creates a security group with the following rules:

### Egress Rules (Outbound)

1. **All traffic to VPC CIDR** - For internal communication
2. **HTTPS (443) to VPC CIDR** - For VPC endpoints
3. **HTTPS (443) to S3 prefix list** - For S3 gateway endpoint
4. **DNS (53)** - For name resolution
5. **NTP (123)** - For time synchronization
6. **All traffic to internet** (only if `direct_internet_access = "Enabled"`)

### Ingress Rules (Inbound)

1. **HTTPS (443) from allowed CIDR blocks** - For accessing the notebook
2. **HTTPS (443) from allowed security groups** - For accessing from specific resources
3. **HTTPS (443) from VPC CIDR** - For internal VPC access
4. **Self-referencing** - For communication within the security group

## IAM Permissions Explained

The IAM role created includes the following permissions:

### SageMaker Operations
- Create, describe, start, stop, and update notebook instances
- Create and manage training jobs
- Create and manage models and endpoints
- Invoke endpoints for inference

### S3 Access
- Read/write access to specified S3 buckets
- List bucket contents
- Manage multipart uploads

### ECR Access
- Pull container images for custom ML environments

### CloudWatch Logs
- Create and write to log groups for monitoring

### VPC Access
- Create and manage network interfaces in your VPC
- Required for private subnet deployments

### KMS Access (if KMS key is provided)
- Encrypt/decrypt data using the specified KMS key

## Outputs

The module provides the following outputs:

```hcl
# Notebook information
output "notebook_instance_name"  # Name of the notebook
output "notebook_instance_arn"   # ARN of the notebook
output "notebook_instance_url"   # URL to access the notebook
output "notebook_instance_id"    # ID of the notebook

# IAM information
output "iam_role_arn"           # ARN of the IAM role
output "iam_role_name"          # Name of the IAM role

# Security group information
output "security_group_id"       # ID of the security group
output "security_group_arn"      # ARN of the security group
output "all_security_group_ids"  # All attached security groups

# Logging information
output "cloudwatch_log_group_name"  # CloudWatch log group name
output "cloudwatch_log_group_arn"   # CloudWatch log group ARN

# Network information
output "network_interface_id"    # ENI ID of the notebook
```

## Examples

### Example 1: Basic Development Environment

```hcl
aws_region   = "us-east-1"
project_name = "ml-dev"
environment  = "dev"

instance_type = "ml.t3.medium"
volume_size   = 10

vpc_id         = "vpc-12345678"
subnet_id      = "subnet-private-123"
vpc_cidr_block = "10.0.0.0/16"

direct_internet_access = "Disabled"
root_access            = "Disabled"

s3_bucket_arns = [
  "arn:aws:s3:::ml-dev-data"
]
```

### Example 2: Production Environment with Encryption

```hcl
aws_region   = "us-east-1"
project_name = "ml-prod"
environment  = "prod"

instance_type = "ml.m5.xlarge"
volume_size   = 50

vpc_id         = "vpc-87654321"
subnet_id      = "subnet-private-456"
vpc_cidr_block = "10.1.0.0/16"

direct_internet_access = "Disabled"
root_access            = "Disabled"

# Encryption
kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/abc123..."

# Permissions boundary for compliance
iam_role_permissions_boundary = "arn:aws:iam::123456789012:policy/OrgBoundary"

s3_bucket_arns = [
  "arn:aws:s3:::ml-prod-data",
  "arn:aws:s3:::ml-prod-models"
]

# CloudWatch logs retention
cloudwatch_logs_retention_days = 90

default_tags = {
  Environment = "Production"
  Compliance  = "Required"
  DataClass   = "Sensitive"
}
```

### Example 3: GPU Instance with Custom Lifecycle

```hcl
aws_region   = "us-east-1"
project_name = "ml-training"
environment  = "dev"

instance_type = "ml.p3.2xlarge"  # GPU instance
volume_size   = 100

vpc_id         = "vpc-12345678"
subnet_id      = "subnet-private-789"
vpc_cidr_block = "10.0.0.0/16"

# Lifecycle configuration for GPU drivers and frameworks
create_lifecycle_config = true
lifecycle_config_on_create = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Install GPU-accelerated libraries
  sudo -u ec2-user -i <<'USEREOF'
  source /home/ec2-user/anaconda3/bin/activate pytorch_p39
  pip install --upgrade pip
  pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu118
  pip install transformers accelerate
  source /home/ec2-user/anaconda3/bin/deactivate
  USEREOF
EOF
)

s3_bucket_arns = [
  "arn:aws:s3:::ml-training-data",
  "arn:aws:s3:::ml-model-artifacts"
]
```

## Troubleshooting

### Notebook Instance Fails to Start

**Issue**: Notebook instance is stuck in "Pending" or fails to start.

**Solutions**:
1. Check VPC endpoints are configured correctly
2. Verify security group allows outbound traffic to VPC endpoints
3. Check CloudWatch logs: `/aws/sagemaker/NotebookInstances/[notebook-name]`
4. Ensure IAM role has VPC access permissions

### Cannot Access S3 Buckets

**Issue**: Unable to read/write to S3 from the notebook.

**Solutions**:
1. Verify S3 bucket ARNs in `s3_bucket_arns` variable
2. Check S3 VPC endpoint is configured
3. Verify security group allows HTTPS traffic to S3 prefix list
4. Test with AWS CLI: `aws s3 ls s3://your-bucket/`

### Lifecycle Configuration Fails

**Issue**: Lifecycle script fails during instance creation/start.

**Solutions**:
1. Check CloudWatch logs for script errors
2. Ensure script is properly base64 encoded
3. Test script locally before encoding
4. Add error handling: `set -e` and proper logging

### VPC Endpoint Connection Issues

**Issue**: Cannot connect to AWS services from private subnet.

**Solutions**:
1. Verify VPC endpoints exist: `aws ec2 describe-vpc-endpoints`
2. Check private DNS is enabled for interface endpoints
3. Verify security groups allow HTTPS from notebook security group
4. Ensure route tables are properly configured

## Cost Optimization

### Instance Selection
- Use `ml.t3.medium` for development ($0.05/hour)
- Stop instances when not in use
- Consider spot instances for non-production

### Storage
- Start with minimum 5 GB, increase as needed
- Clean up unused data regularly
- Use S3 for long-term storage

### Lifecycle
- Automatically stop instances after idle time
- Use lifecycle configs to clean up temp files

## Security Best Practices

1. ✅ **Use Private Subnets** - Deploy in private subnets without direct internet access
2. ✅ **Disable Root Access** - Set `root_access = "Disabled"`
3. ✅ **Enable Encryption** - Use KMS encryption for EBS volumes
4. ✅ **Least Privilege IAM** - Only grant necessary S3 bucket access
5. ✅ **Use IMDSv2** - Instance metadata service v2 is enforced
6. ✅ **Enable CloudWatch Logs** - Monitor notebook activity
7. ✅ **Apply Tags** - Use tags for cost tracking and compliance
8. ✅ **Permissions Boundary** - Use boundaries for organizational compliance
9. ✅ **Security Groups** - Restrict inbound/outbound traffic
10. ✅ **VPC Endpoints** - Use VPC endpoints for AWS service access

## Maintenance

### Updating the Notebook

```bash
# Modify variables in terraform.tfvars
# For example, change instance type

# Apply changes
terraform apply
```

**Note**: Some changes (like instance type) require stopping the notebook instance.

### Destroying Resources

```bash
# Remove all resources
terraform destroy
```

**Warning**: This will delete the notebook instance and all local data. Ensure important data is saved to S3.

## Git Repository Access

This module includes full support for Git integration. See [GIT_SETUP.md](GIT_SETUP.md) for detailed instructions on:

- Cloning public and private repositories
- AWS CodeCommit integration
- GitHub/GitLab authentication with Secrets Manager
- SSH vs HTTPS configuration
- Automatic repository cloning on notebook start

**Quick Start:**
```hcl
# In terraform.tfvars:
enable_git_access = true  # Already enabled by default!
default_code_repository = "https://github.com/username/repo-name"
```

## Support and Contributions

For issues, questions, or contributions:
- Review AWS SageMaker documentation
- Check Terraform AWS provider documentation
- Review CloudWatch logs for debugging
- See [GIT_SETUP.md](GIT_SETUP.md) for Git-related issues

## Documentation

- **[README.md](README.md)** - This file, comprehensive module documentation
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Step-by-step deployment instructions
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick command reference
- **[GIT_SETUP.md](GIT_SETUP.md)** - Git repository integration guide
- **[vpc_endpoints_example.tf](vpc_endpoints_example.tf)** - VPC endpoints configuration example

## License

This module is provided as-is for use in your AWS environment.

## Additional Resources

- [AWS SageMaker Documentation](https://docs.aws.amazon.com/sagemaker/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [SageMaker Notebook Instances](https://docs.aws.amazon.com/sagemaker/latest/dg/nbi.html)
- [VPC Endpoints for SageMaker](https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-interface-endpoint.html)

```

```markdown
# Production-Ready SageMaker Notebook Terraform Module

This Terraform configuration provides a complete, production-ready deployment of an AWS SageMaker notebook instance with full support for private subnets, comprehensive IAM roles, and security groups.

## Features

- ✅ **Complete IAM Role Configuration** - Includes all necessary permissions for SageMaker operations
- ✅ **Managed S3 Buckets** - Automatic creation of datasets and models buckets with versioning, encryption, and lifecycle policies (see [S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md))
- ✅ **Private Subnet Support** - Designed for deployment in private subnets with VPC endpoints
- ✅ **Security Groups** - Pre-configured security groups with all necessary rules
- ✅ **Git Integration** - Full support for GitHub, GitLab, Bitbucket, and AWS CodeCommit (see [GIT_SETUP.md](GIT_SETUP.md))
- ✅ **Encryption Support** - Optional KMS encryption for EBS volumes and S3 buckets
- ✅ **CloudWatch Logs** - Integrated logging and monitoring
- ✅ **Lifecycle Configuration** - Support for custom startup scripts
- ✅ **Fully Parameterized** - All options are configurable via variables
- ✅ **Production Best Practices** - Follows AWS best practices for security and operations

## Architecture

This module creates the following resources:

1. **SageMaker Notebook Instance** - The main ML development environment
2. **S3 Buckets** (optional, enabled by default):
   - **Datasets Bucket** - For storing ML training/testing datasets with versioning and lifecycle policies
   - **Models Bucket** - For storing trained model artifacts with versioning
3. **IAM Role** - With policies for SageMaker, S3, ECR, CloudWatch, VPC, KMS, Git (CodeCommit), and Secrets Manager
4. **Security Group** - With rules for private subnet communication, VPC endpoints, and Git access
5. **CloudWatch Log Group** - For notebook instance logs
6. **Lifecycle Configuration** (optional) - For custom initialization scripts

## Prerequisites

Before using this module, ensure you have:

1. **AWS Account** with appropriate permissions
2. **VPC with Private Subnets** configured
3. **VPC Endpoints** (recommended for private subnets):
   - S3 Gateway Endpoint
   - SageMaker API Interface Endpoint
   - SageMaker Runtime Interface Endpoint
   - EC2 Interface Endpoint (for ENI management)
4. **Terraform >= 1.0** installed
5. **AWS Provider >= 5.0** configured

## Quick Start

### 1. Copy the Example Variables File

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit `terraform.tfvars`

Update the required variables:

```hcl
# Minimum required variables
aws_region     = "us-east-1"
project_name   = "my-ml-project"
environment    = "dev"
vpc_id         = "vpc-xxxxxxxxx"
subnet_id      = "subnet-xxxxxxxxx"  # Private subnet
vpc_cidr_block = "10.0.0.0/16"

# S3 buckets for data access
s3_bucket_arns = [
  "arn:aws:s3:::my-ml-data-bucket"
]
```

### 3. Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 4. Access Your Notebook

After deployment, access the notebook through the AWS Console or use the presigned URL:

```bash
# Get the notebook instance name
terraform output notebook_instance_name

# Open in AWS Console
# Navigate to: SageMaker > Notebook Instances > [notebook-name] > Open JupyterLab
```

## Configuration Options

### Instance Types

Choose based on your workload:

| Instance Type | vCPUs | Memory | Use Case |
|--------------|-------|--------|----------|
| `ml.t3.medium` | 2 | 4 GB | Development, light workloads |
| `ml.t3.xlarge` | 4 | 16 GB | General purpose |
| `ml.m5.xlarge` | 4 | 16 GB | Balanced compute/memory |
| `ml.m5.2xlarge` | 8 | 32 GB | Larger datasets |
| `ml.p3.2xlarge` | 8 | 61 GB | GPU workloads |
| `ml.p3.8xlarge` | 32 | 244 GB | Heavy GPU workloads |

### Network Configuration

#### For Private Subnets (Recommended)

```hcl
direct_internet_access = "Disabled"
subnet_id              = "subnet-private-xxx"

# Ensure VPC endpoints are configured
enable_s3_vpc_endpoint                = true
enable_sagemaker_api_vpc_endpoint     = true
enable_sagemaker_runtime_vpc_endpoint = true
```

#### For Public Subnets

```hcl
direct_internet_access = "Enabled"
subnet_id              = "subnet-public-xxx"
```

### Security Configuration

#### Using Auto-Created Security Group

```hcl
create_security_group = true
allowed_cidr_blocks = [
  "10.0.0.0/16"  # Your VPC CIDR
]
```

#### Using Existing Security Group

```hcl
create_security_group = false
additional_security_group_ids = [
  "sg-existing123"
]
```

### IAM Configuration

#### Auto-Create IAM Role (Recommended)

```hcl
create_iam_role = true
s3_bucket_arns = [
  "arn:aws:s3:::my-data-bucket"
]
```

#### Use Existing IAM Role

```hcl
create_iam_role = false
iam_role_arn    = "arn:aws:iam::123456789012:role/existing-role"
```

### Lifecycle Configuration

Use lifecycle configurations to install packages or configure the environment:

```hcl
create_lifecycle_config = true

lifecycle_config_on_create = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Install system packages
  sudo yum update -y
  sudo yum install -y htop git
  
  # Install Python packages
  sudo -u ec2-user -i <<'USEREOF'
  source /home/ec2-user/anaconda3/bin/activate JupyterSystemEnv
  pip install --upgrade pip
  pip install pandas numpy scikit-learn matplotlib seaborn
  source /home/ec2-user/anaconda3/bin/deactivate
  USEREOF
  
  echo "Notebook instance created at $(date)"
EOF
)

lifecycle_config_on_start = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Run on every start
  echo "Notebook instance started at $(date)"
  
  # Pull latest code from git
  cd /home/ec2-user/SageMaker
  if [ -d ".git" ]; then
    git pull
  fi
EOF
)
```

### Encryption

Enable EBS volume encryption:

```hcl
kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
```

## VPC Endpoints Setup

For private subnet deployments, create the following VPC endpoints in your VPC:

### S3 Gateway Endpoint

```hcl
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  
  route_table_ids = [aws_route_table.private.id]
}
```

### SageMaker API Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "sagemaker_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

### SageMaker Runtime Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "sagemaker_runtime" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

### EC2 Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

## Security Groups Explained

The module creates a security group with the following rules:

### Egress Rules (Outbound)

1. **All traffic to VPC CIDR** - For internal communication
2. **HTTPS (443) to VPC CIDR** - For VPC endpoints
3. **HTTPS (443) to S3 prefix list** - For S3 gateway endpoint
4. **DNS (53)** - For name resolution
5. **NTP (123)** - For time synchronization
6. **All traffic to internet** (only if `direct_internet_access = "Enabled"`)

### Ingress Rules (Inbound)

1. **HTTPS (443) from allowed CIDR blocks** - For accessing the notebook
2. **HTTPS (443) from allowed security groups** - For accessing from specific resources
3. **HTTPS (443) from VPC CIDR** - For internal VPC access
4. **Self-referencing** - For communication within the security group

## IAM Permissions Explained

The IAM role created includes the following permissions:

### SageMaker Operations
- Create, describe, start, stop, and update notebook instances
- Create and manage training jobs
- Create and manage models and endpoints
- Invoke endpoints for inference

### S3 Access
- Read/write access to specified S3 buckets
- List bucket contents
- Manage multipart uploads

### ECR Access
- Pull container images for custom ML environments

### CloudWatch Logs
- Create and write to log groups for monitoring

### VPC Access
- Create and manage network interfaces in your VPC
- Required for private subnet deployments

### KMS Access (if KMS key is provided)
- Encrypt/decrypt data using the specified KMS key

## Outputs

The module provides the following outputs:

```hcl
# Notebook information
output "notebook_instance_name"  # Name of the notebook
output "notebook_instance_arn"   # ARN of the notebook
output "notebook_instance_url"   # URL to access the notebook
output "notebook_instance_id"    # ID of the notebook

# IAM information
output "iam_role_arn"           # ARN of the IAM role
output "iam_role_name"          # Name of the IAM role

# Security group information
output "security_group_id"       # ID of the security group
output "security_group_arn"      # ARN of the security group
output "all_security_group_ids"  # All attached security groups

# Logging information
output "cloudwatch_log_group_name"  # CloudWatch log group name
output "cloudwatch_log_group_arn"   # CloudWatch log group ARN

# Network information
output "network_interface_id"    # ENI ID of the notebook
```

## Examples

### Example 1: Basic Development Environment

```hcl
aws_region   = "us-east-1"
project_name = "ml-dev"
environment  = "dev"

instance_type = "ml.t3.medium"
volume_size   = 10

vpc_id         = "vpc-12345678"
subnet_id      = "subnet-private-123"
vpc_cidr_block = "10.0.0.0/16"

direct_internet_access = "Disabled"
root_access            = "Disabled"

s3_bucket_arns = [
  "arn:aws:s3:::ml-dev-data"
]
```

### Example 2: Production Environment with Encryption

```hcl
aws_region   = "us-east-1"
project_name = "ml-prod"
environment  = "prod"

instance_type = "ml.m5.xlarge"
volume_size   = 50

vpc_id         = "vpc-87654321"
subnet_id      = "subnet-private-456"
vpc_cidr_block = "10.1.0.0/16"

direct_internet_access = "Disabled"
root_access            = "Disabled"

# Encryption
kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/abc123..."

# Permissions boundary for compliance
iam_role_permissions_boundary = "arn:aws:iam::123456789012:policy/OrgBoundary"

s3_bucket_arns = [
  "arn:aws:s3:::ml-prod-data",
  "arn:aws:s3:::ml-prod-models"
]

# CloudWatch logs retention
cloudwatch_logs_retention_days = 90

default_tags = {
  Environment = "Production"
  Compliance  = "Required"
  DataClass   = "Sensitive"
}
```

### Example 3: GPU Instance with Custom Lifecycle

```hcl
aws_region   = "us-east-1"
project_name = "ml-training"
environment  = "dev"

instance_type = "ml.p3.2xlarge"  # GPU instance
volume_size   = 100

vpc_id         = "vpc-12345678"
subnet_id      = "subnet-private-789"
vpc_cidr_block = "10.0.0.0/16"

# Lifecycle configuration for GPU drivers and frameworks
create_lifecycle_config = true
lifecycle_config_on_create = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Install GPU-accelerated libraries
  sudo -u ec2-user -i <<'USEREOF'
  source /home/ec2-user/anaconda3/bin/activate pytorch_p39
  pip install --upgrade pip
  pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu118
  pip install transformers accelerate
  source /home/ec2-user/anaconda3/bin/deactivate
  USEREOF
EOF
)

s3_bucket_arns = [
  "arn:aws:s3:::ml-training-data",
  "arn:aws:s3:::ml-model-artifacts"
]
```

## Troubleshooting

### Notebook Instance Fails to Start

**Issue**: Notebook instance is stuck in "Pending" or fails to start.

**Solutions**:
1. Check VPC endpoints are configured correctly
2. Verify security group allows outbound traffic to VPC endpoints
3. Check CloudWatch logs: `/aws/sagemaker/NotebookInstances/[notebook-name]`
4. Ensure IAM role has VPC access permissions

### Cannot Access S3 Buckets

**Issue**: Unable to read/write to S3 from the notebook.

**Solutions**:
1. Verify S3 bucket ARNs in `s3_bucket_arns` variable
2. Check S3 VPC endpoint is configured
3. Verify security group allows HTTPS traffic to S3 prefix list
4. Test with AWS CLI: `aws s3 ls s3://your-bucket/`

### Lifecycle Configuration Fails

**Issue**: Lifecycle script fails during instance creation/start.

**Solutions**:
1. Check CloudWatch logs for script errors
2. Ensure script is properly base64 encoded
3. Test script locally before encoding
4. Add error handling: `set -e` and proper logging

### VPC Endpoint Connection Issues

**Issue**: Cannot connect to AWS services from private subnet.

**Solutions**:
1. Verify VPC endpoints exist: `aws ec2 describe-vpc-endpoints`
2. Check private DNS is enabled for interface endpoints
3. Verify security groups allow HTTPS from notebook security group
4. Ensure route tables are properly configured

## Cost Optimization

### Instance Selection
- Use `ml.t3.medium` for development ($0.05/hour)
- Stop instances when not in use
- Consider spot instances for non-production

### Storage
- Start with minimum 5 GB, increase as needed
- Clean up unused data regularly
- Use S3 for long-term storage

### Lifecycle
- Automatically stop instances after idle time
- Use lifecycle configs to clean up temp files

## Security Best Practices

1. ✅ **Use Private Subnets** - Deploy in private subnets without direct internet access
2. ✅ **Disable Root Access** - Set `root_access = "Disabled"`
3. ✅ **Enable Encryption** - Use KMS encryption for EBS volumes
4. ✅ **Least Privilege IAM** - Only grant necessary S3 bucket access
5. ✅ **Use IMDSv2** - Instance metadata service v2 is enforced
6. ✅ **Enable CloudWatch Logs** - Monitor notebook activity
7. ✅ **Apply Tags** - Use tags for cost tracking and compliance
8. ✅ **Permissions Boundary** - Use boundaries for organizational compliance
9. ✅ **Security Groups** - Restrict inbound/outbound traffic
10. ✅ **VPC Endpoints** - Use VPC endpoints for AWS service access

## Maintenance

### Updating the Notebook

```bash
# Modify variables in terraform.tfvars
# For example, change instance type

# Apply changes
terraform apply
```

**Note**: Some changes (like instance type) require stopping the notebook instance.

### Destroying Resources

```bash
# Remove all resources
terraform destroy
```

**Warning**: This will delete the notebook instance and all local data. Ensure important data is saved to S3.

## Git Repository Access

This module includes full support for Git integration. See [GIT_SETUP.md](GIT_SETUP.md) for detailed instructions on:

- Cloning public and private repositories
- AWS CodeCommit integration
- GitHub/GitLab authentication with Secrets Manager
- SSH vs HTTPS configuration
- Automatic repository cloning on notebook start

**Quick Start:**
```hcl
# In terraform.tfvars:
enable_git_access = true  # Already enabled by default!
default_code_repository = "https://github.com/username/repo-name"
```

## Support and Contributions

For issues, questions, or contributions:
- Review AWS SageMaker documentation
- Check Terraform AWS provider documentation
- Review CloudWatch logs for debugging
- See [GIT_SETUP.md](GIT_SETUP.md) for Git-related issues

## Documentation

- **[README.md](README.md)** - This file, comprehensive module documentation
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Step-by-step deployment instructions
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick command reference
- **[GIT_SETUP.md](GIT_SETUP.md)** - Git repository integration guide
- **[vpc_endpoints_example.tf](vpc_endpoints_example.tf)** - VPC endpoints configuration example

## License

This module is provided as-is for use in your AWS environment.

## Additional Resources

- [AWS SageMaker Documentation](https://docs.aws.amazon.com/sagemaker/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [SageMaker Notebook Instances](https://docs.aws.amazon.com/sagemaker/latest/dg/nbi.html)
- [VPC Endpoints for SageMaker](https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-interface-endpoint.html)

```

```markdown
# Production-Ready SageMaker Notebook Terraform Module

This Terraform configuration provides a complete, production-ready deployment of an AWS SageMaker notebook instance with full support for private subnets, comprehensive IAM roles, and security groups.

## Features

- ✅ **Complete IAM Role Configuration** - Includes all necessary permissions for SageMaker operations
- ✅ **Managed S3 Buckets** - Automatic creation of datasets and models buckets with versioning, encryption, and lifecycle policies (see [S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md))
- ✅ **Private Subnet Support** - Designed for deployment in private subnets with VPC endpoints
- ✅ **Security Groups** - Pre-configured security groups with all necessary rules
- ✅ **Git Integration** - Full support for GitHub, GitLab, Bitbucket, and AWS CodeCommit (see [GIT_SETUP.md](GIT_SETUP.md))
- ✅ **Encryption Support** - Optional KMS encryption for EBS volumes and S3 buckets
- ✅ **CloudWatch Logs** - Integrated logging and monitoring
- ✅ **Lifecycle Configuration** - Support for custom startup scripts
- ✅ **Fully Parameterized** - All options are configurable via variables
- ✅ **Production Best Practices** - Follows AWS best practices for security and operations

## Architecture

This module creates the following resources:

1. **SageMaker Notebook Instance** - The main ML development environment
2. **S3 Buckets** (optional, enabled by default):
   - **Datasets Bucket** - For storing ML training/testing datasets with versioning and lifecycle policies
   - **Models Bucket** - For storing trained model artifacts with versioning
3. **IAM Role** - With policies for SageMaker, S3, ECR, CloudWatch, VPC, KMS, Git (CodeCommit), and Secrets Manager
4. **Security Group** - With rules for private subnet communication, VPC endpoints, and Git access
5. **CloudWatch Log Group** - For notebook instance logs
6. **Lifecycle Configuration** (optional) - For custom initialization scripts

## Prerequisites

Before using this module, ensure you have:

1. **AWS Account** with appropriate permissions
2. **VPC with Private Subnets** configured
3. **VPC Endpoints** (recommended for private subnets):
   - S3 Gateway Endpoint
   - SageMaker API Interface Endpoint
   - SageMaker Runtime Interface Endpoint
   - EC2 Interface Endpoint (for ENI management)
4. **Terraform >= 1.0** installed
5. **AWS Provider >= 5.0** configured

## Quick Start

### 1. Copy the Example Variables File

```bash
# For basic setup
cp terraform.tfvars.example terraform.tfvars

# For setup with S3 buckets (recommended for ML workflows)
cp terraform.tfvars.s3-example terraform.tfvars
```

### 2. Edit `terraform.tfvars`

Update the required variables:

```hcl
# Minimum required variables
aws_region     = "us-east-1"
project_name   = "my-ml-project"
environment    = "dev"
vpc_id         = "vpc-xxxxxxxxx"
subnet_id      = "subnet-xxxxxxxxx"  # Private subnet
vpc_cidr_block = "10.0.0.0/16"

# S3 buckets (automatically created by default)
create_datasets_bucket = true
create_models_bucket   = true

# Optional: Provide additional external bucket access
s3_bucket_arns = [
  "arn:aws:s3:::existing-data-bucket"
]
```

### 3. Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 4. Access Your Notebook

After deployment, access the notebook through the AWS Console or use the presigned URL:

```bash
# Get the notebook instance name
terraform output notebook_instance_name

# Open in AWS Console
# Navigate to: SageMaker > Notebook Instances > [notebook-name] > Open JupyterLab
```

## Configuration Options

### Instance Types

Choose based on your workload:

| Instance Type | vCPUs | Memory | Use Case |
|--------------|-------|--------|----------|
| `ml.t3.medium` | 2 | 4 GB | Development, light workloads |
| `ml.t3.xlarge` | 4 | 16 GB | General purpose |
| `ml.m5.xlarge` | 4 | 16 GB | Balanced compute/memory |
| `ml.m5.2xlarge` | 8 | 32 GB | Larger datasets |
| `ml.p3.2xlarge` | 8 | 61 GB | GPU workloads |
| `ml.p3.8xlarge` | 32 | 244 GB | Heavy GPU workloads |

### Network Configuration

#### For Private Subnets (Recommended)

```hcl
direct_internet_access = "Disabled"
subnet_id              = "subnet-private-xxx"

# Ensure VPC endpoints are configured
enable_s3_vpc_endpoint                = true
enable_sagemaker_api_vpc_endpoint     = true
enable_sagemaker_runtime_vpc_endpoint = true
```

#### For Public Subnets

```hcl
direct_internet_access = "Enabled"
subnet_id              = "subnet-public-xxx"
```

### Security Configuration

#### Using Auto-Created Security Group

```hcl
create_security_group = true
allowed_cidr_blocks = [
  "10.0.0.0/16"  # Your VPC CIDR
]
```

#### Using Existing Security Group

```hcl
create_security_group = false
additional_security_group_ids = [
  "sg-existing123"
]
```

### IAM Configuration

#### Auto-Create IAM Role (Recommended)

```hcl
create_iam_role = true
s3_bucket_arns = [
  "arn:aws:s3:::my-data-bucket"
]
```

#### Use Existing IAM Role

```hcl
create_iam_role = false
iam_role_arn    = "arn:aws:iam::123456789012:role/existing-role"
```

### Lifecycle Configuration

Use lifecycle configurations to install packages or configure the environment:

```hcl
create_lifecycle_config = true

lifecycle_config_on_create = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Install system packages
  sudo yum update -y
  sudo yum install -y htop git
  
  # Install Python packages
  sudo -u ec2-user -i <<'USEREOF'
  source /home/ec2-user/anaconda3/bin/activate JupyterSystemEnv
  pip install --upgrade pip
  pip install pandas numpy scikit-learn matplotlib seaborn
  source /home/ec2-user/anaconda3/bin/deactivate
  USEREOF
  
  echo "Notebook instance created at $(date)"
EOF
)

lifecycle_config_on_start = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Run on every start
  echo "Notebook instance started at $(date)"
  
  # Pull latest code from git
  cd /home/ec2-user/SageMaker
  if [ -d ".git" ]; then
    git pull
  fi
EOF
)
```

### Encryption

Enable EBS volume encryption:

```hcl
kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
```

## VPC Endpoints Setup

For private subnet deployments, create the following VPC endpoints in your VPC:

### S3 Gateway Endpoint

```hcl
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  
  route_table_ids = [aws_route_table.private.id]
}
```

### SageMaker API Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "sagemaker_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

### SageMaker Runtime Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "sagemaker_runtime" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

### EC2 Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

## Security Groups Explained

The module creates a security group with the following rules:

### Egress Rules (Outbound)

1. **All traffic to VPC CIDR** - For internal communication
2. **HTTPS (443) to VPC CIDR** - For VPC endpoints
3. **HTTPS (443) to S3 prefix list** - For S3 gateway endpoint
4. **DNS (53)** - For name resolution
5. **NTP (123)** - For time synchronization
6. **All traffic to internet** (only if `direct_internet_access = "Enabled"`)

### Ingress Rules (Inbound)

1. **HTTPS (443) from allowed CIDR blocks** - For accessing the notebook
2. **HTTPS (443) from allowed security groups** - For accessing from specific resources
3. **HTTPS (443) from VPC CIDR** - For internal VPC access
4. **Self-referencing** - For communication within the security group

## IAM Permissions Explained

The IAM role created includes the following permissions:

### SageMaker Operations
- Create, describe, start, stop, and update notebook instances
- Create and manage training jobs
- Create and manage models and endpoints
- Invoke endpoints for inference

### S3 Access
- Read/write access to specified S3 buckets
- List bucket contents
- Manage multipart uploads

### ECR Access
- Pull container images for custom ML environments

### CloudWatch Logs
- Create and write to log groups for monitoring

### VPC Access
- Create and manage network interfaces in your VPC
- Required for private subnet deployments

### KMS Access (if KMS key is provided)
- Encrypt/decrypt data using the specified KMS key

## Outputs

The module provides the following outputs:

```hcl
# Notebook information
output "notebook_instance_name"  # Name of the notebook
output "notebook_instance_arn"   # ARN of the notebook
output "notebook_instance_url"   # URL to access the notebook
output "notebook_instance_id"    # ID of the notebook

# IAM information
output "iam_role_arn"           # ARN of the IAM role
output "iam_role_name"          # Name of the IAM role

# Security group information
output "security_group_id"       # ID of the security group
output "security_group_arn"      # ARN of the security group
output "all_security_group_ids"  # All attached security groups

# Logging information
output "cloudwatch_log_group_name"  # CloudWatch log group name
output "cloudwatch_log_group_arn"   # CloudWatch log group ARN

# Network information
output "network_interface_id"    # ENI ID of the notebook
```

## Examples

### Example 1: Basic Development Environment

```hcl
aws_region   = "us-east-1"
project_name = "ml-dev"
environment  = "dev"

instance_type = "ml.t3.medium"
volume_size   = 10

vpc_id         = "vpc-12345678"
subnet_id      = "subnet-private-123"
vpc_cidr_block = "10.0.0.0/16"

direct_internet_access = "Disabled"
root_access            = "Disabled"

s3_bucket_arns = [
  "arn:aws:s3:::ml-dev-data"
]
```

### Example 2: Production Environment with Encryption

```hcl
aws_region   = "us-east-1"
project_name = "ml-prod"
environment  = "prod"

instance_type = "ml.m5.xlarge"
volume_size   = 50

vpc_id         = "vpc-87654321"
subnet_id      = "subnet-private-456"
vpc_cidr_block = "10.1.0.0/16"

direct_internet_access = "Disabled"
root_access            = "Disabled"

# Encryption
kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/abc123..."

# Permissions boundary for compliance
iam_role_permissions_boundary = "arn:aws:iam::123456789012:policy/OrgBoundary"

s3_bucket_arns = [
  "arn:aws:s3:::ml-prod-data",
  "arn:aws:s3:::ml-prod-models"
]

# CloudWatch logs retention
cloudwatch_logs_retention_days = 90

default_tags = {
  Environment = "Production"
  Compliance  = "Required"
  DataClass   = "Sensitive"
}
```

### Example 3: GPU Instance with Custom Lifecycle

```hcl
aws_region   = "us-east-1"
project_name = "ml-training"
environment  = "dev"

instance_type = "ml.p3.2xlarge"  # GPU instance
volume_size   = 100

vpc_id         = "vpc-12345678"
subnet_id      = "subnet-private-789"
vpc_cidr_block = "10.0.0.0/16"

# Lifecycle configuration for GPU drivers and frameworks
create_lifecycle_config = true
lifecycle_config_on_create = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Install GPU-accelerated libraries
  sudo -u ec2-user -i <<'USEREOF'
  source /home/ec2-user/anaconda3/bin/activate pytorch_p39
  pip install --upgrade pip
  pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu118
  pip install transformers accelerate
  source /home/ec2-user/anaconda3/bin/deactivate
  USEREOF
EOF
)

s3_bucket_arns = [
  "arn:aws:s3:::ml-training-data",
  "arn:aws:s3:::ml-model-artifacts"
]
```

## Troubleshooting

### Notebook Instance Fails to Start

**Issue**: Notebook instance is stuck in "Pending" or fails to start.

**Solutions**:
1. Check VPC endpoints are configured correctly
2. Verify security group allows outbound traffic to VPC endpoints
3. Check CloudWatch logs: `/aws/sagemaker/NotebookInstances/[notebook-name]`
4. Ensure IAM role has VPC access permissions

### Cannot Access S3 Buckets

**Issue**: Unable to read/write to S3 from the notebook.

**Solutions**:
1. Verify S3 bucket ARNs in `s3_bucket_arns` variable
2. Check S3 VPC endpoint is configured
3. Verify security group allows HTTPS traffic to S3 prefix list
4. Test with AWS CLI: `aws s3 ls s3://your-bucket/`

### Lifecycle Configuration Fails

**Issue**: Lifecycle script fails during instance creation/start.

**Solutions**:
1. Check CloudWatch logs for script errors
2. Ensure script is properly base64 encoded
3. Test script locally before encoding
4. Add error handling: `set -e` and proper logging

### VPC Endpoint Connection Issues

**Issue**: Cannot connect to AWS services from private subnet.

**Solutions**:
1. Verify VPC endpoints exist: `aws ec2 describe-vpc-endpoints`
2. Check private DNS is enabled for interface endpoints
3. Verify security groups allow HTTPS from notebook security group
4. Ensure route tables are properly configured

## Cost Optimization

### Instance Selection
- Use `ml.t3.medium` for development ($0.05/hour)
- Stop instances when not in use
- Consider spot instances for non-production

### Storage
- Start with minimum 5 GB, increase as needed
- Clean up unused data regularly
- Use S3 for long-term storage

### Lifecycle
- Automatically stop instances after idle time
- Use lifecycle configs to clean up temp files

## Security Best Practices

1. ✅ **Use Private Subnets** - Deploy in private subnets without direct internet access
2. ✅ **Disable Root Access** - Set `root_access = "Disabled"`
3. ✅ **Enable Encryption** - Use KMS encryption for EBS volumes
4. ✅ **Least Privilege IAM** - Only grant necessary S3 bucket access
5. ✅ **Use IMDSv2** - Instance metadata service v2 is enforced
6. ✅ **Enable CloudWatch Logs** - Monitor notebook activity
7. ✅ **Apply Tags** - Use tags for cost tracking and compliance
8. ✅ **Permissions Boundary** - Use boundaries for organizational compliance
9. ✅ **Security Groups** - Restrict inbound/outbound traffic
10. ✅ **VPC Endpoints** - Use VPC endpoints for AWS service access

## Maintenance

### Updating the Notebook

```bash
# Modify variables in terraform.tfvars
# For example, change instance type

# Apply changes
terraform apply
```

**Note**: Some changes (like instance type) require stopping the notebook instance.

### Destroying Resources

```bash
# Remove all resources
terraform destroy
```

**Warning**: This will delete the notebook instance and all local data. Ensure important data is saved to S3.

## Git Repository Access

This module includes full support for Git integration. See [GIT_SETUP.md](GIT_SETUP.md) for detailed instructions on:

- Cloning public and private repositories
- AWS CodeCommit integration
- GitHub/GitLab authentication with Secrets Manager
- SSH vs HTTPS configuration
- Automatic repository cloning on notebook start

**Quick Start:**
```hcl
# In terraform.tfvars:
enable_git_access = true  # Already enabled by default!
default_code_repository = "https://github.com/username/repo-name"
```

## Support and Contributions

For issues, questions, or contributions:
- Review AWS SageMaker documentation
- Check Terraform AWS provider documentation
- Review CloudWatch logs for debugging
- See [GIT_SETUP.md](GIT_SETUP.md) for Git-related issues

## Documentation

- **[README.md](README.md)** - This file, comprehensive module documentation
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Step-by-step deployment instructions
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick command reference
- **[GIT_SETUP.md](GIT_SETUP.md)** - Git repository integration guide
- **[vpc_endpoints_example.tf](vpc_endpoints_example.tf)** - VPC endpoints configuration example

## License

This module is provided as-is for use in your AWS environment.

## Additional Resources

- [AWS SageMaker Documentation](https://docs.aws.amazon.com/sagemaker/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [SageMaker Notebook Instances](https://docs.aws.amazon.com/sagemaker/latest/dg/nbi.html)
- [VPC Endpoints for SageMaker](https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-interface-endpoint.html)

```

```markdown
# Production-Ready SageMaker Notebook Terraform Module

This Terraform configuration provides a complete, production-ready deployment of an AWS SageMaker notebook instance with full support for private subnets, comprehensive IAM roles, and security groups.

## Features

- ✅ **Complete IAM Role Configuration** - Includes all necessary permissions for SageMaker operations
- ✅ **Managed S3 Buckets** - Automatic creation of datasets and models buckets with versioning, encryption, and lifecycle policies (see [S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md))
- ✅ **Private Subnet Support** - Designed for deployment in private subnets with VPC endpoints
- ✅ **Security Groups** - Pre-configured security groups with all necessary rules
- ✅ **Git Integration** - Full support for GitHub, GitLab, Bitbucket, and AWS CodeCommit (see [GIT_SETUP.md](GIT_SETUP.md))
- ✅ **Encryption Support** - Optional KMS encryption for EBS volumes and S3 buckets
- ✅ **CloudWatch Logs** - Integrated logging and monitoring
- ✅ **Lifecycle Configuration** - Support for custom startup scripts
- ✅ **Fully Parameterized** - All options are configurable via variables
- ✅ **Production Best Practices** - Follows AWS best practices for security and operations

## Architecture

This module creates the following resources:

1. **SageMaker Notebook Instance** - The main ML development environment
2. **S3 Buckets** (optional, enabled by default):
   - **Datasets Bucket** - For storing ML training/testing datasets with versioning and lifecycle policies
   - **Models Bucket** - For storing trained model artifacts with versioning
3. **IAM Role** - With policies for SageMaker, S3, ECR, CloudWatch, VPC, KMS, Git (CodeCommit), and Secrets Manager
4. **Security Group** - With rules for private subnet communication, VPC endpoints, and Git access
5. **CloudWatch Log Group** - For notebook instance logs
6. **Lifecycle Configuration** (optional) - For custom initialization scripts

## Prerequisites

Before using this module, ensure you have:

1. **AWS Account** with appropriate permissions
2. **VPC with Private Subnets** configured
3. **VPC Endpoints** (recommended for private subnets):
   - S3 Gateway Endpoint
   - SageMaker API Interface Endpoint
   - SageMaker Runtime Interface Endpoint
   - EC2 Interface Endpoint (for ENI management)
4. **Terraform >= 1.0** installed
5. **AWS Provider >= 5.0** configured

## Quick Start

### 1. Copy the Example Variables File

```bash
# For basic setup
cp terraform.tfvars.example terraform.tfvars

# For setup with S3 buckets (recommended for ML workflows)
cp terraform.tfvars.s3-example terraform.tfvars
```

### 2. Edit `terraform.tfvars`

Update the required variables:

```hcl
# Minimum required variables
aws_region     = "us-east-1"
project_name   = "my-ml-project"
environment    = "dev"
vpc_id         = "vpc-xxxxxxxxx"
subnet_id      = "subnet-xxxxxxxxx"  # Private subnet
vpc_cidr_block = "10.0.0.0/16"

# S3 buckets (automatically created by default)
create_datasets_bucket = true
create_models_bucket   = true

# Optional: Provide additional external bucket access
s3_bucket_arns = [
  "arn:aws:s3:::existing-data-bucket"
]
```

### 3. Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 4. Access Your Notebook

After deployment, access the notebook through the AWS Console or use the presigned URL:

```bash
# Get the notebook instance name
terraform output notebook_instance_name

# Open in AWS Console
# Navigate to: SageMaker > Notebook Instances > [notebook-name] > Open JupyterLab
```

## Configuration Options

### Instance Types

Choose based on your workload:

| Instance Type | vCPUs | Memory | Use Case |
|--------------|-------|--------|----------|
| `ml.t3.medium` | 2 | 4 GB | Development, light workloads |
| `ml.t3.xlarge` | 4 | 16 GB | General purpose |
| `ml.m5.xlarge` | 4 | 16 GB | Balanced compute/memory |
| `ml.m5.2xlarge` | 8 | 32 GB | Larger datasets |
| `ml.p3.2xlarge` | 8 | 61 GB | GPU workloads |
| `ml.p3.8xlarge` | 32 | 244 GB | Heavy GPU workloads |

### Network Configuration

#### For Private Subnets (Recommended)

```hcl
direct_internet_access = "Disabled"
subnet_id              = "subnet-private-xxx"

# Ensure VPC endpoints are configured
enable_s3_vpc_endpoint                = true
enable_sagemaker_api_vpc_endpoint     = true
enable_sagemaker_runtime_vpc_endpoint = true
```

#### For Public Subnets

```hcl
direct_internet_access = "Enabled"
subnet_id              = "subnet-public-xxx"
```

### Security Configuration

#### Using Auto-Created Security Group

```hcl
create_security_group = true
allowed_cidr_blocks = [
  "10.0.0.0/16"  # Your VPC CIDR
]
```

#### Using Existing Security Group

```hcl
create_security_group = false
additional_security_group_ids = [
  "sg-existing123"
]
```

### IAM Configuration

#### Auto-Create IAM Role (Recommended)

```hcl
create_iam_role = true
s3_bucket_arns = [
  "arn:aws:s3:::my-data-bucket"
]
```

#### Use Existing IAM Role

```hcl
create_iam_role = false
iam_role_arn    = "arn:aws:iam::123456789012:role/existing-role"
```

### Lifecycle Configuration

Use lifecycle configurations to install packages or configure the environment:

```hcl
create_lifecycle_config = true

lifecycle_config_on_create = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Install system packages
  sudo yum update -y
  sudo yum install -y htop git
  
  # Install Python packages
  sudo -u ec2-user -i <<'USEREOF'
  source /home/ec2-user/anaconda3/bin/activate JupyterSystemEnv
  pip install --upgrade pip
  pip install pandas numpy scikit-learn matplotlib seaborn
  source /home/ec2-user/anaconda3/bin/deactivate
  USEREOF
  
  echo "Notebook instance created at $(date)"
EOF
)

lifecycle_config_on_start = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Run on every start
  echo "Notebook instance started at $(date)"
  
  # Pull latest code from git
  cd /home/ec2-user/SageMaker
  if [ -d ".git" ]; then
    git pull
  fi
EOF
)
```

### Encryption

Enable EBS volume encryption:

```hcl
kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
```

## VPC Endpoints Setup

For private subnet deployments, create the following VPC endpoints in your VPC:

### S3 Gateway Endpoint

```hcl
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  
  route_table_ids = [aws_route_table.private.id]
}
```

### SageMaker API Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "sagemaker_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

### SageMaker Runtime Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "sagemaker_runtime" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

### EC2 Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

## Security Groups Explained

The module creates a security group with the following rules:

### Egress Rules (Outbound)

1. **All traffic to VPC CIDR** - For internal communication
2. **HTTPS (443) to VPC CIDR** - For VPC endpoints
3. **HTTPS (443) to S3 prefix list** - For S3 gateway endpoint
4. **DNS (53)** - For name resolution
5. **NTP (123)** - For time synchronization
6. **All traffic to internet** (only if `direct_internet_access = "Enabled"`)

### Ingress Rules (Inbound)

1. **HTTPS (443) from allowed CIDR blocks** - For accessing the notebook
2. **HTTPS (443) from allowed security groups** - For accessing from specific resources
3. **HTTPS (443) from VPC CIDR** - For internal VPC access
4. **Self-referencing** - For communication within the security group

## IAM Permissions Explained

The IAM role created includes the following permissions:

### SageMaker Operations
- Create, describe, start, stop, and update notebook instances
- Create and manage training jobs
- Create and manage models and endpoints
- Invoke endpoints for inference

### S3 Access
- Read/write access to specified S3 buckets
- List bucket contents
- Manage multipart uploads

### ECR Access
- Pull container images for custom ML environments

### CloudWatch Logs
- Create and write to log groups for monitoring

### VPC Access
- Create and manage network interfaces in your VPC
- Required for private subnet deployments

### KMS Access (if KMS key is provided)
- Encrypt/decrypt data using the specified KMS key

## Outputs

The module provides the following outputs:

```hcl
# Notebook information
output "notebook_instance_name"  # Name of the notebook
output "notebook_instance_arn"   # ARN of the notebook
output "notebook_instance_url"   # URL to access the notebook
output "notebook_instance_id"    # ID of the notebook

# S3 bucket information
output "datasets_bucket_name"    # Name of the datasets bucket
output "datasets_bucket_arn"     # ARN of the datasets bucket
output "models_bucket_name"      # Name of the models bucket
output "models_bucket_arn"       # ARN of the models bucket
output "all_s3_bucket_arns"      # All S3 bucket ARNs accessible

# IAM information
output "iam_role_arn"           # ARN of the IAM role
output "iam_role_name"          # Name of the IAM role

# Security group information
output "security_group_id"       # ID of the security group
output "security_group_arn"      # ARN of the security group
output "all_security_group_ids"  # All attached security groups

# Logging information
output "cloudwatch_log_group_name"  # CloudWatch log group name
output "cloudwatch_log_group_arn"   # CloudWatch log group ARN

# Network information
output "network_interface_id"    # ENI ID of the notebook
```

## Examples

### Example 1: Basic Development Environment

```hcl
aws_region   = "us-east-1"
project_name = "ml-dev"
environment  = "dev"

instance_type = "ml.t3.medium"
volume_size   = 10

vpc_id         = "vpc-12345678"
subnet_id      = "subnet-private-123"
vpc_cidr_block = "10.0.0.0/16"

direct_internet_access = "Disabled"
root_access            = "Disabled"

s3_bucket_arns = [
  "arn:aws:s3:::ml-dev-data"
]
```

### Example 2: Production Environment with Encryption

```hcl
aws_region   = "us-east-1"
project_name = "ml-prod"
environment  = "prod"

instance_type = "ml.m5.xlarge"
volume_size   = 50

vpc_id         = "vpc-87654321"
subnet_id      = "subnet-private-456"
vpc_cidr_block = "10.1.0.0/16"

direct_internet_access = "Disabled"
root_access            = "Disabled"

# Encryption
kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/abc123..."

# Permissions boundary for compliance
iam_role_permissions_boundary = "arn:aws:iam::123456789012:policy/OrgBoundary"

s3_bucket_arns = [
  "arn:aws:s3:::ml-prod-data",
  "arn:aws:s3:::ml-prod-models"
]

# CloudWatch logs retention
cloudwatch_logs_retention_days = 90

default_tags = {
  Environment = "Production"
  Compliance  = "Required"
  DataClass   = "Sensitive"
}
```

### Example 3: GPU Instance with Custom Lifecycle

```hcl
aws_region   = "us-east-1"
project_name = "ml-training"
environment  = "dev"

instance_type = "ml.p3.2xlarge"  # GPU instance
volume_size   = 100

vpc_id         = "vpc-12345678"
subnet_id      = "subnet-private-789"
vpc_cidr_block = "10.0.0.0/16"

# Lifecycle configuration for GPU drivers and frameworks
create_lifecycle_config = true
lifecycle_config_on_create = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Install GPU-accelerated libraries
  sudo -u ec2-user -i <<'USEREOF'
  source /home/ec2-user/anaconda3/bin/activate pytorch_p39
  pip install --upgrade pip
  pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu118
  pip install transformers accelerate
  source /home/ec2-user/anaconda3/bin/deactivate
  USEREOF
EOF
)

s3_bucket_arns = [
  "arn:aws:s3:::ml-training-data",
  "arn:aws:s3:::ml-model-artifacts"
]
```

## Troubleshooting

### Notebook Instance Fails to Start

**Issue**: Notebook instance is stuck in "Pending" or fails to start.

**Solutions**:
1. Check VPC endpoints are configured correctly
2. Verify security group allows outbound traffic to VPC endpoints
3. Check CloudWatch logs: `/aws/sagemaker/NotebookInstances/[notebook-name]`
4. Ensure IAM role has VPC access permissions

### Cannot Access S3 Buckets

**Issue**: Unable to read/write to S3 from the notebook.

**Solutions**:
1. Verify S3 bucket ARNs in `s3_bucket_arns` variable
2. Check S3 VPC endpoint is configured
3. Verify security group allows HTTPS traffic to S3 prefix list
4. Test with AWS CLI: `aws s3 ls s3://your-bucket/`

### Lifecycle Configuration Fails

**Issue**: Lifecycle script fails during instance creation/start.

**Solutions**:
1. Check CloudWatch logs for script errors
2. Ensure script is properly base64 encoded
3. Test script locally before encoding
4. Add error handling: `set -e` and proper logging

### VPC Endpoint Connection Issues

**Issue**: Cannot connect to AWS services from private subnet.

**Solutions**:
1. Verify VPC endpoints exist: `aws ec2 describe-vpc-endpoints`
2. Check private DNS is enabled for interface endpoints
3. Verify security groups allow HTTPS from notebook security group
4. Ensure route tables are properly configured

## Cost Optimization

### Instance Selection
- Use `ml.t3.medium` for development ($0.05/hour)
- Stop instances when not in use
- Consider spot instances for non-production

### Storage
- Start with minimum 5 GB, increase as needed
- Clean up unused data regularly
- Use S3 for long-term storage

### Lifecycle
- Automatically stop instances after idle time
- Use lifecycle configs to clean up temp files

## Security Best Practices

1. ✅ **Use Private Subnets** - Deploy in private subnets without direct internet access
2. ✅ **Disable Root Access** - Set `root_access = "Disabled"`
3. ✅ **Enable Encryption** - Use KMS encryption for EBS volumes
4. ✅ **Least Privilege IAM** - Only grant necessary S3 bucket access
5. ✅ **Use IMDSv2** - Instance metadata service v2 is enforced
6. ✅ **Enable CloudWatch Logs** - Monitor notebook activity
7. ✅ **Apply Tags** - Use tags for cost tracking and compliance
8. ✅ **Permissions Boundary** - Use boundaries for organizational compliance
9. ✅ **Security Groups** - Restrict inbound/outbound traffic
10. ✅ **VPC Endpoints** - Use VPC endpoints for AWS service access

## Maintenance

### Updating the Notebook

```bash
# Modify variables in terraform.tfvars
# For example, change instance type

# Apply changes
terraform apply
```

**Note**: Some changes (like instance type) require stopping the notebook instance.

### Destroying Resources

```bash
# Remove all resources
terraform destroy
```

**Warning**: This will delete the notebook instance and all local data. Ensure important data is saved to S3.

## Git Repository Access

This module includes full support for Git integration. See [GIT_SETUP.md](GIT_SETUP.md) for detailed instructions on:

- Cloning public and private repositories
- AWS CodeCommit integration
- GitHub/GitLab authentication with Secrets Manager
- SSH vs HTTPS configuration
- Automatic repository cloning on notebook start

**Quick Start:**
```hcl
# In terraform.tfvars:
enable_git_access = true  # Already enabled by default!
default_code_repository = "https://github.com/username/repo-name"
```

## Support and Contributions

For issues, questions, or contributions:
- Review AWS SageMaker documentation
- Check Terraform AWS provider documentation
- Review CloudWatch logs for debugging
- See [GIT_SETUP.md](GIT_SETUP.md) for Git-related issues

## Documentation

- **[README.md](README.md)** - This file, comprehensive module documentation
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Step-by-step deployment instructions
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick command reference
- **[GIT_SETUP.md](GIT_SETUP.md)** - Git repository integration guide
- **[vpc_endpoints_example.tf](vpc_endpoints_example.tf)** - VPC endpoints configuration example

## License

This module is provided as-is for use in your AWS environment.

## Additional Resources

- [AWS SageMaker Documentation](https://docs.aws.amazon.com/sagemaker/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [SageMaker Notebook Instances](https://docs.aws.amazon.com/sagemaker/latest/dg/nbi.html)
- [VPC Endpoints for SageMaker](https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-interface-endpoint.html)

```

```markdown
# Production-Ready SageMaker Notebook Terraform Module

This Terraform configuration provides a complete, production-ready deployment of an AWS SageMaker notebook instance with full support for private subnets, comprehensive IAM roles, and security groups.

## Features

- ✅ **Complete IAM Role Configuration** - Includes all necessary permissions for SageMaker operations
- ✅ **Managed S3 Buckets** - Automatic creation of datasets and models buckets with versioning, encryption, and lifecycle policies (see [S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md))
- ✅ **Private Subnet Support** - Designed for deployment in private subnets with VPC endpoints
- ✅ **Security Groups** - Pre-configured security groups with all necessary rules
- ✅ **Git Integration** - Full support for GitHub, GitLab, Bitbucket, and AWS CodeCommit (see [GIT_SETUP.md](GIT_SETUP.md))
- ✅ **Encryption Support** - Optional KMS encryption for EBS volumes and S3 buckets
- ✅ **CloudWatch Logs** - Integrated logging and monitoring
- ✅ **Lifecycle Configuration** - Support for custom startup scripts
- ✅ **Fully Parameterized** - All options are configurable via variables
- ✅ **Production Best Practices** - Follows AWS best practices for security and operations

## Architecture

This module creates the following resources:

1. **SageMaker Notebook Instance** - The main ML development environment
2. **S3 Buckets** (optional, enabled by default):
   - **Datasets Bucket** - For storing ML training/testing datasets with versioning and lifecycle policies
   - **Models Bucket** - For storing trained model artifacts with versioning
3. **IAM Role** - With policies for SageMaker, S3, ECR, CloudWatch, VPC, KMS, Git (CodeCommit), and Secrets Manager
4. **Security Group** - With rules for private subnet communication, VPC endpoints, and Git access
5. **CloudWatch Log Group** - For notebook instance logs
6. **Lifecycle Configuration** (optional) - For custom initialization scripts

## Prerequisites

Before using this module, ensure you have:

1. **AWS Account** with appropriate permissions
2. **VPC with Private Subnets** configured
3. **VPC Endpoints** (recommended for private subnets):
   - S3 Gateway Endpoint
   - SageMaker API Interface Endpoint
   - SageMaker Runtime Interface Endpoint
   - EC2 Interface Endpoint (for ENI management)
4. **Terraform >= 1.0** installed
5. **AWS Provider >= 5.0** configured

## Quick Start

### 1. Copy the Example Variables File

```bash
# For basic setup
cp terraform.tfvars.example terraform.tfvars

# For setup with S3 buckets (recommended for ML workflows)
cp terraform.tfvars.s3-example terraform.tfvars
```

### 2. Edit `terraform.tfvars`

Update the required variables:

```hcl
# Minimum required variables
aws_region     = "us-east-1"
project_name   = "my-ml-project"
environment    = "dev"
vpc_id         = "vpc-xxxxxxxxx"
subnet_id      = "subnet-xxxxxxxxx"  # Private subnet
vpc_cidr_block = "10.0.0.0/16"

# S3 buckets (automatically created by default)
create_datasets_bucket = true
create_models_bucket   = true

# Optional: Provide additional external bucket access
s3_bucket_arns = [
  "arn:aws:s3:::existing-data-bucket"
]
```

### 3. Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 4. Access Your Notebook

After deployment, access the notebook through the AWS Console or use the presigned URL:

```bash
# Get the notebook instance name
terraform output notebook_instance_name

# Open in AWS Console
# Navigate to: SageMaker > Notebook Instances > [notebook-name] > Open JupyterLab
```

## Configuration Options

### Instance Types

Choose based on your workload:

| Instance Type | vCPUs | Memory | Use Case |
|--------------|-------|--------|----------|
| `ml.t3.medium` | 2 | 4 GB | Development, light workloads |
| `ml.t3.xlarge` | 4 | 16 GB | General purpose |
| `ml.m5.xlarge` | 4 | 16 GB | Balanced compute/memory |
| `ml.m5.2xlarge` | 8 | 32 GB | Larger datasets |
| `ml.p3.2xlarge` | 8 | 61 GB | GPU workloads |
| `ml.p3.8xlarge` | 32 | 244 GB | Heavy GPU workloads |

### Network Configuration

#### For Private Subnets (Recommended)

```hcl
direct_internet_access = "Disabled"
subnet_id              = "subnet-private-xxx"

# Ensure VPC endpoints are configured
enable_s3_vpc_endpoint                = true
enable_sagemaker_api_vpc_endpoint     = true
enable_sagemaker_runtime_vpc_endpoint = true
```

#### For Public Subnets

```hcl
direct_internet_access = "Enabled"
subnet_id              = "subnet-public-xxx"
```

### Security Configuration

#### Using Auto-Created Security Group

```hcl
create_security_group = true
allowed_cidr_blocks = [
  "10.0.0.0/16"  # Your VPC CIDR
]
```

#### Using Existing Security Group

```hcl
create_security_group = false
additional_security_group_ids = [
  "sg-existing123"
]
```

### IAM Configuration

#### Auto-Create IAM Role (Recommended)

```hcl
create_iam_role = true
s3_bucket_arns = [
  "arn:aws:s3:::my-data-bucket"
]
```

#### Use Existing IAM Role

```hcl
create_iam_role = false
iam_role_arn    = "arn:aws:iam::123456789012:role/existing-role"
```

### Lifecycle Configuration

Use lifecycle configurations to install packages or configure the environment:

```hcl
create_lifecycle_config = true

lifecycle_config_on_create = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Install system packages
  sudo yum update -y
  sudo yum install -y htop git
  
  # Install Python packages
  sudo -u ec2-user -i <<'USEREOF'
  source /home/ec2-user/anaconda3/bin/activate JupyterSystemEnv
  pip install --upgrade pip
  pip install pandas numpy scikit-learn matplotlib seaborn
  source /home/ec2-user/anaconda3/bin/deactivate
  USEREOF
  
  echo "Notebook instance created at $(date)"
EOF
)

lifecycle_config_on_start = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Run on every start
  echo "Notebook instance started at $(date)"
  
  # Pull latest code from git
  cd /home/ec2-user/SageMaker
  if [ -d ".git" ]; then
    git pull
  fi
EOF
)
```

### Encryption

Enable EBS volume encryption:

```hcl
kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
```

## VPC Endpoints Setup

For private subnet deployments, create the following VPC endpoints in your VPC:

### S3 Gateway Endpoint

```hcl
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  
  route_table_ids = [aws_route_table.private.id]
}
```

### SageMaker API Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "sagemaker_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

### SageMaker Runtime Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "sagemaker_runtime" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

### EC2 Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

## Security Groups Explained

The module creates a security group with the following rules:

### Egress Rules (Outbound)

1. **All traffic to VPC CIDR** - For internal communication
2. **HTTPS (443) to VPC CIDR** - For VPC endpoints
3. **HTTPS (443) to S3 prefix list** - For S3 gateway endpoint
4. **DNS (53)** - For name resolution
5. **NTP (123)** - For time synchronization
6. **All traffic to internet** (only if `direct_internet_access = "Enabled"`)

### Ingress Rules (Inbound)

1. **HTTPS (443) from allowed CIDR blocks** - For accessing the notebook
2. **HTTPS (443) from allowed security groups** - For accessing from specific resources
3. **HTTPS (443) from VPC CIDR** - For internal VPC access
4. **Self-referencing** - For communication within the security group

## IAM Permissions Explained

The IAM role created includes the following permissions:

### SageMaker Operations
- Create, describe, start, stop, and update notebook instances
- Create and manage training jobs
- Create and manage models and endpoints
- Invoke endpoints for inference

### S3 Access
- Read/write access to specified S3 buckets
- List bucket contents
- Manage multipart uploads

### ECR Access
- Pull container images for custom ML environments

### CloudWatch Logs
- Create and write to log groups for monitoring

### VPC Access
- Create and manage network interfaces in your VPC
- Required for private subnet deployments

### KMS Access (if KMS key is provided)
- Encrypt/decrypt data using the specified KMS key

## S3 Bucket Management

The module automatically creates and manages S3 buckets for your ML workflows with production-ready configurations. See [S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md) for detailed usage instructions.

### Managed Buckets

#### Datasets Bucket
- **Purpose**: Store training/testing datasets
- **Features**: 
  - Versioning enabled by default
  - Lifecycle policies (archive old versions to Glacier after 30 days, delete after 90 days)
  - Server-side encryption (AES256 or KMS)
  - Public access blocked
  - Automatic IAM permissions for notebook access

#### Models Bucket
- **Purpose**: Store trained model artifacts
- **Features**:
  - Versioning enabled by default
  - Server-side encryption (AES256 or KMS)
  - Public access blocked
  - Automatic IAM permissions for notebook access

### Configuration Options

```hcl
# Enable/disable bucket creation
create_datasets_bucket = true  # Default: true
create_models_bucket   = true  # Default: true

# Custom bucket names (optional)
datasets_bucket_name = "my-company-datasets"
models_bucket_name   = "my-company-models"

# Versioning
enable_datasets_bucket_versioning = true
enable_models_bucket_versioning   = true

# KMS encryption (optional, uses AES256 if not provided)
datasets_bucket_kms_key_id = "arn:aws:kms:..."
models_bucket_kms_key_id   = "arn:aws:kms:..."

# Lifecycle policies for cost optimization
enable_datasets_bucket_lifecycle = true
datasets_bucket_lifecycle_rules = {
  archive_old_versions = {
    enabled         = true
    transition_days = 30
    storage_class   = "GLACIER"
  }
  delete_old_versions = {
    enabled        = true
    expiration_days = 90
  }
  transition_to_ia = {
    enabled         = false
    transition_days = 90
    prefix          = "archive/"
  }
}
```

### Using S3 Buckets from Notebooks

After deployment, get your bucket names:

```bash
terraform output datasets_bucket_name
terraform output models_bucket_name
```

Access from Python:

```python
import pandas as pd

# Read data from S3 (using pandas)
df = pd.read_csv('s3://your-project-dev-datasets/raw/dataset.csv')

# Write data to S3
df.to_parquet('s3://your-project-dev-datasets/processed/data.parquet')
```

See [S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md) for comprehensive examples including:
- Boto3 usage
- SageMaker SDK integration
- Migrating data from Google Cloud Storage
- Best practices and directory structure
- Large dataset handling

### Additional S3 Buckets

You can grant access to additional external buckets:

```hcl
s3_bucket_arns = [
  "arn:aws:s3:::existing-company-data",
  "arn:aws:s3:::shared-datasets"
]
```

## Outputs

The module provides the following outputs:

```hcl
# Notebook information
output "notebook_instance_name"  # Name of the notebook
output "notebook_instance_arn"   # ARN of the notebook
output "notebook_instance_url"   # URL to access the notebook
output "notebook_instance_id"    # ID of the notebook

# S3 bucket information
output "datasets_bucket_name"    # Name of the datasets bucket
output "datasets_bucket_arn"     # ARN of the datasets bucket
output "models_bucket_name"      # Name of the models bucket
output "models_bucket_arn"       # ARN of the models bucket
output "all_s3_bucket_arns"      # All S3 bucket ARNs accessible

# IAM information
output "iam_role_arn"           # ARN of the IAM role
output "iam_role_name"          # Name of the IAM role

# Security group information
output "security_group_id"       # ID of the security group
output "security_group_arn"      # ARN of the security group
output "all_security_group_ids"  # All attached security groups

# Logging information
output "cloudwatch_log_group_name"  # CloudWatch log group name
output "cloudwatch_log_group_arn"   # CloudWatch log group ARN

# Network information
output "network_interface_id"    # ENI ID of the notebook
```

## Examples

### Example 1: Basic Development Environment

```hcl
aws_region   = "us-east-1"
project_name = "ml-dev"
environment  = "dev"

instance_type = "ml.t3.medium"
volume_size   = 10

vpc_id         = "vpc-12345678"
subnet_id      = "subnet-private-123"
vpc_cidr_block = "10.0.0.0/16"

direct_internet_access = "Disabled"
root_access            = "Disabled"

s3_bucket_arns = [
  "arn:aws:s3:::ml-dev-data"
]
```

### Example 2: Production Environment with Encryption

```hcl
aws_region   = "us-east-1"
project_name = "ml-prod"
environment  = "prod"

instance_type = "ml.m5.xlarge"
volume_size   = 50

vpc_id         = "vpc-87654321"
subnet_id      = "subnet-private-456"
vpc_cidr_block = "10.1.0.0/16"

direct_internet_access = "Disabled"
root_access            = "Disabled"

# Encryption
kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/abc123..."

# Permissions boundary for compliance
iam_role_permissions_boundary = "arn:aws:iam::123456789012:policy/OrgBoundary"

s3_bucket_arns = [
  "arn:aws:s3:::ml-prod-data",
  "arn:aws:s3:::ml-prod-models"
]

# CloudWatch logs retention
cloudwatch_logs_retention_days = 90

default_tags = {
  Environment = "Production"
  Compliance  = "Required"
  DataClass   = "Sensitive"
}
```

### Example 3: GPU Instance with Custom Lifecycle

```hcl
aws_region   = "us-east-1"
project_name = "ml-training"
environment  = "dev"

instance_type = "ml.p3.2xlarge"  # GPU instance
volume_size   = 100

vpc_id         = "vpc-12345678"
subnet_id      = "subnet-private-789"
vpc_cidr_block = "10.0.0.0/16"

# Lifecycle configuration for GPU drivers and frameworks
create_lifecycle_config = true
lifecycle_config_on_create = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Install GPU-accelerated libraries
  sudo -u ec2-user -i <<'USEREOF'
  source /home/ec2-user/anaconda3/bin/activate pytorch_p39
  pip install --upgrade pip
  pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu118
  pip install transformers accelerate
  source /home/ec2-user/anaconda3/bin/deactivate
  USEREOF
EOF
)

s3_bucket_arns = [
  "arn:aws:s3:::ml-training-data",
  "arn:aws:s3:::ml-model-artifacts"
]
```

## Troubleshooting

### Notebook Instance Fails to Start

**Issue**: Notebook instance is stuck in "Pending" or fails to start.

**Solutions**:
1. Check VPC endpoints are configured correctly
2. Verify security group allows outbound traffic to VPC endpoints
3. Check CloudWatch logs: `/aws/sagemaker/NotebookInstances/[notebook-name]`
4. Ensure IAM role has VPC access permissions

### Cannot Access S3 Buckets

**Issue**: Unable to read/write to S3 from the notebook.

**Solutions**:
1. Verify S3 bucket ARNs in `s3_bucket_arns` variable
2. Check S3 VPC endpoint is configured
3. Verify security group allows HTTPS traffic to S3 prefix list
4. Test with AWS CLI: `aws s3 ls s3://your-bucket/`

### Lifecycle Configuration Fails

**Issue**: Lifecycle script fails during instance creation/start.

**Solutions**:
1. Check CloudWatch logs for script errors
2. Ensure script is properly base64 encoded
3. Test script locally before encoding
4. Add error handling: `set -e` and proper logging

### VPC Endpoint Connection Issues

**Issue**: Cannot connect to AWS services from private subnet.

**Solutions**:
1. Verify VPC endpoints exist: `aws ec2 describe-vpc-endpoints`
2. Check private DNS is enabled for interface endpoints
3. Verify security groups allow HTTPS from notebook security group
4. Ensure route tables are properly configured

## Cost Optimization

### Instance Selection
- Use `ml.t3.medium` for development ($0.05/hour)
- Stop instances when not in use
- Consider spot instances for non-production

### Storage
- Start with minimum 5 GB, increase as needed
- Clean up unused data regularly
- Use S3 for long-term storage

### Lifecycle
- Automatically stop instances after idle time
- Use lifecycle configs to clean up temp files

## Security Best Practices

1. ✅ **Use Private Subnets** - Deploy in private subnets without direct internet access
2. ✅ **Disable Root Access** - Set `root_access = "Disabled"`
3. ✅ **Enable Encryption** - Use KMS encryption for EBS volumes
4. ✅ **Least Privilege IAM** - Only grant necessary S3 bucket access
5. ✅ **Use IMDSv2** - Instance metadata service v2 is enforced
6. ✅ **Enable CloudWatch Logs** - Monitor notebook activity
7. ✅ **Apply Tags** - Use tags for cost tracking and compliance
8. ✅ **Permissions Boundary** - Use boundaries for organizational compliance
9. ✅ **Security Groups** - Restrict inbound/outbound traffic
10. ✅ **VPC Endpoints** - Use VPC endpoints for AWS service access

## Maintenance

### Updating the Notebook

```bash
# Modify variables in terraform.tfvars
# For example, change instance type

# Apply changes
terraform apply
```

**Note**: Some changes (like instance type) require stopping the notebook instance.

### Destroying Resources

```bash
# Remove all resources
terraform destroy
```

**Warning**: This will delete the notebook instance and all local data. Ensure important data is saved to S3.

## Git Repository Access

This module includes full support for Git integration. See [GIT_SETUP.md](GIT_SETUP.md) for detailed instructions on:

- Cloning public and private repositories
- AWS CodeCommit integration
- GitHub/GitLab authentication with Secrets Manager
- SSH vs HTTPS configuration
- Automatic repository cloning on notebook start

**Quick Start:**
```hcl
# In terraform.tfvars:
enable_git_access = true  # Already enabled by default!
default_code_repository = "https://github.com/username/repo-name"
```

## Support and Contributions

For issues, questions, or contributions:
- Review AWS SageMaker documentation
- Check Terraform AWS provider documentation
- Review CloudWatch logs for debugging
- See [GIT_SETUP.md](GIT_SETUP.md) for Git-related issues

## Documentation

- **[README.md](README.md)** - This file, comprehensive module documentation
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Step-by-step deployment instructions
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick command reference
- **[GIT_SETUP.md](GIT_SETUP.md)** - Git repository integration guide
- **[vpc_endpoints_example.tf](vpc_endpoints_example.tf)** - VPC endpoints configuration example

## License

This module is provided as-is for use in your AWS environment.

## Additional Resources

- [AWS SageMaker Documentation](https://docs.aws.amazon.com/sagemaker/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [SageMaker Notebook Instances](https://docs.aws.amazon.com/sagemaker/latest/dg/nbi.html)
- [VPC Endpoints for SageMaker](https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-interface-endpoint.html)

```

```markdown
# Production-Ready SageMaker Notebook Terraform Module

This Terraform configuration provides a complete, production-ready deployment of an AWS SageMaker notebook instance with full support for private subnets, comprehensive IAM roles, and security groups.

## Features

- ✅ **Complete IAM Role Configuration** - Includes all necessary permissions for SageMaker operations
- ✅ **Managed S3 Buckets** - Automatic creation of datasets and models buckets with versioning, encryption, and lifecycle policies (see [S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md))
- ✅ **Private Subnet Support** - Designed for deployment in private subnets with VPC endpoints
- ✅ **Security Groups** - Pre-configured security groups with all necessary rules
- ✅ **Git Integration** - Full support for GitHub, GitLab, Bitbucket, and AWS CodeCommit (see [GIT_SETUP.md](GIT_SETUP.md))
- ✅ **Encryption Support** - Optional KMS encryption for EBS volumes and S3 buckets
- ✅ **CloudWatch Logs** - Integrated logging and monitoring
- ✅ **Lifecycle Configuration** - Support for custom startup scripts
- ✅ **Fully Parameterized** - All options are configurable via variables
- ✅ **Production Best Practices** - Follows AWS best practices for security and operations

## Architecture

This module creates the following resources:

1. **SageMaker Notebook Instance** - The main ML development environment
2. **S3 Buckets** (optional, enabled by default):
   - **Datasets Bucket** - For storing ML training/testing datasets with versioning and lifecycle policies
   - **Models Bucket** - For storing trained model artifacts with versioning
3. **IAM Role** - With policies for SageMaker, S3, ECR, CloudWatch, VPC, KMS, Git (CodeCommit), and Secrets Manager
4. **Security Group** - With rules for private subnet communication, VPC endpoints, and Git access
5. **CloudWatch Log Group** - For notebook instance logs
6. **Lifecycle Configuration** (optional) - For custom initialization scripts

## Prerequisites

Before using this module, ensure you have:

1. **AWS Account** with appropriate permissions
2. **VPC with Private Subnets** configured
3. **VPC Endpoints** (recommended for private subnets):
   - S3 Gateway Endpoint
   - SageMaker API Interface Endpoint
   - SageMaker Runtime Interface Endpoint
   - EC2 Interface Endpoint (for ENI management)
4. **Terraform >= 1.0** installed
5. **AWS Provider >= 5.0** configured

## Quick Start

### 1. Copy the Example Variables File

```bash
# For basic setup
cp terraform.tfvars.example terraform.tfvars

# For setup with S3 buckets (recommended for ML workflows)
cp terraform.tfvars.s3-example terraform.tfvars
```

### 2. Edit `terraform.tfvars`

Update the required variables:

```hcl
# Minimum required variables
aws_region     = "us-east-1"
project_name   = "my-ml-project"
environment    = "dev"
vpc_id         = "vpc-xxxxxxxxx"
subnet_id      = "subnet-xxxxxxxxx"  # Private subnet
vpc_cidr_block = "10.0.0.0/16"

# S3 buckets (automatically created by default)
create_datasets_bucket = true
create_models_bucket   = true

# Optional: Provide additional external bucket access
s3_bucket_arns = [
  "arn:aws:s3:::existing-data-bucket"
]
```

### 3. Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 4. Access Your Notebook

After deployment, access the notebook through the AWS Console or use the presigned URL:

```bash
# Get the notebook instance name
terraform output notebook_instance_name

# Open in AWS Console
# Navigate to: SageMaker > Notebook Instances > [notebook-name] > Open JupyterLab
```

## Configuration Options

### Instance Types

Choose based on your workload:

| Instance Type | vCPUs | Memory | Use Case |
|--------------|-------|--------|----------|
| `ml.t3.medium` | 2 | 4 GB | Development, light workloads |
| `ml.t3.xlarge` | 4 | 16 GB | General purpose |
| `ml.m5.xlarge` | 4 | 16 GB | Balanced compute/memory |
| `ml.m5.2xlarge` | 8 | 32 GB | Larger datasets |
| `ml.p3.2xlarge` | 8 | 61 GB | GPU workloads |
| `ml.p3.8xlarge` | 32 | 244 GB | Heavy GPU workloads |

### Network Configuration

#### For Private Subnets (Recommended)

```hcl
direct_internet_access = "Disabled"
subnet_id              = "subnet-private-xxx"

# Ensure VPC endpoints are configured
enable_s3_vpc_endpoint                = true
enable_sagemaker_api_vpc_endpoint     = true
enable_sagemaker_runtime_vpc_endpoint = true
```

#### For Public Subnets

```hcl
direct_internet_access = "Enabled"
subnet_id              = "subnet-public-xxx"
```

### Security Configuration

#### Using Auto-Created Security Group

```hcl
create_security_group = true
allowed_cidr_blocks = [
  "10.0.0.0/16"  # Your VPC CIDR
]
```

#### Using Existing Security Group

```hcl
create_security_group = false
additional_security_group_ids = [
  "sg-existing123"
]
```

### IAM Configuration

#### Auto-Create IAM Role (Recommended)

```hcl
create_iam_role = true
s3_bucket_arns = [
  "arn:aws:s3:::my-data-bucket"
]
```

#### Use Existing IAM Role

```hcl
create_iam_role = false
iam_role_arn    = "arn:aws:iam::123456789012:role/existing-role"
```

### Lifecycle Configuration

Use lifecycle configurations to install packages or configure the environment:

```hcl
create_lifecycle_config = true

lifecycle_config_on_create = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Install system packages
  sudo yum update -y
  sudo yum install -y htop git
  
  # Install Python packages
  sudo -u ec2-user -i <<'USEREOF'
  source /home/ec2-user/anaconda3/bin/activate JupyterSystemEnv
  pip install --upgrade pip
  pip install pandas numpy scikit-learn matplotlib seaborn
  source /home/ec2-user/anaconda3/bin/deactivate
  USEREOF
  
  echo "Notebook instance created at $(date)"
EOF
)

lifecycle_config_on_start = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Run on every start
  echo "Notebook instance started at $(date)"
  
  # Pull latest code from git
  cd /home/ec2-user/SageMaker
  if [ -d ".git" ]; then
    git pull
  fi
EOF
)
```

### Encryption

Enable EBS volume encryption:

```hcl
kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
```

## VPC Endpoints Setup

For private subnet deployments, create the following VPC endpoints in your VPC:

### S3 Gateway Endpoint

```hcl
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  
  route_table_ids = [aws_route_table.private.id]
}
```

### SageMaker API Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "sagemaker_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

### SageMaker Runtime Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "sagemaker_runtime" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

### EC2 Interface Endpoint

```hcl
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
```

## Security Groups Explained

The module creates a security group with the following rules:

### Egress Rules (Outbound)

1. **All traffic to VPC CIDR** - For internal communication
2. **HTTPS (443) to VPC CIDR** - For VPC endpoints
3. **HTTPS (443) to S3 prefix list** - For S3 gateway endpoint
4. **DNS (53)** - For name resolution
5. **NTP (123)** - For time synchronization
6. **All traffic to internet** (only if `direct_internet_access = "Enabled"`)

### Ingress Rules (Inbound)

1. **HTTPS (443) from allowed CIDR blocks** - For accessing the notebook
2. **HTTPS (443) from allowed security groups** - For accessing from specific resources
3. **HTTPS (443) from VPC CIDR** - For internal VPC access
4. **Self-referencing** - For communication within the security group

## IAM Permissions Explained

The IAM role created includes the following permissions:

### SageMaker Operations
- Create, describe, start, stop, and update notebook instances
- Create and manage training jobs
- Create and manage models and endpoints
- Invoke endpoints for inference

### S3 Access
- Read/write access to specified S3 buckets
- List bucket contents
- Manage multipart uploads

### ECR Access
- Pull container images for custom ML environments

### CloudWatch Logs
- Create and write to log groups for monitoring

### VPC Access
- Create and manage network interfaces in your VPC
- Required for private subnet deployments

### KMS Access (if KMS key is provided)
- Encrypt/decrypt data using the specified KMS key

## S3 Bucket Management

The module automatically creates and manages S3 buckets for your ML workflows with production-ready configurations. See [S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md) for detailed usage instructions.

### Managed Buckets

#### Datasets Bucket
- **Purpose**: Store training/testing datasets
- **Features**: 
  - Versioning enabled by default
  - Lifecycle policies (archive old versions to Glacier after 30 days, delete after 90 days)
  - Server-side encryption (AES256 or KMS)
  - Public access blocked
  - Automatic IAM permissions for notebook access

#### Models Bucket
- **Purpose**: Store trained model artifacts
- **Features**:
  - Versioning enabled by default
  - Server-side encryption (AES256 or KMS)
  - Public access blocked
  - Automatic IAM permissions for notebook access

### Configuration Options

```hcl
# Enable/disable bucket creation
create_datasets_bucket = true  # Default: true
create_models_bucket   = true  # Default: true

# Custom bucket names (optional)
datasets_bucket_name = "my-company-datasets"
models_bucket_name   = "my-company-models"

# Versioning
enable_datasets_bucket_versioning = true
enable_models_bucket_versioning   = true

# KMS encryption (optional, uses AES256 if not provided)
datasets_bucket_kms_key_id = "arn:aws:kms:..."
models_bucket_kms_key_id   = "arn:aws:kms:..."

# Lifecycle policies for cost optimization
enable_datasets_bucket_lifecycle = true
datasets_bucket_lifecycle_rules = {
  archive_old_versions = {
    enabled         = true
    transition_days = 30
    storage_class   = "GLACIER"
  }
  delete_old_versions = {
    enabled        = true
    expiration_days = 90
  }
  transition_to_ia = {
    enabled         = false
    transition_days = 90
    prefix          = "archive/"
  }
}
```

### Using S3 Buckets from Notebooks

After deployment, get your bucket names:

```bash
terraform output datasets_bucket_name
terraform output models_bucket_name
```

Access from Python:

```python
import pandas as pd

# Read data from S3 (using pandas)
df = pd.read_csv('s3://your-project-dev-datasets/raw/dataset.csv')

# Write data to S3
df.to_parquet('s3://your-project-dev-datasets/processed/data.parquet')
```

See [S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md) for comprehensive examples including:
- Boto3 usage
- SageMaker SDK integration
- Migrating data from Google Cloud Storage
- Best practices and directory structure
- Large dataset handling

### Additional S3 Buckets

You can grant access to additional external buckets:

```hcl
s3_bucket_arns = [
  "arn:aws:s3:::existing-company-data",
  "arn:aws:s3:::shared-datasets"
]
```

## Outputs

The module provides the following outputs:

```hcl
# Notebook information
output "notebook_instance_name"  # Name of the notebook
output "notebook_instance_arn"   # ARN of the notebook
output "notebook_instance_url"   # URL to access the notebook
output "notebook_instance_id"    # ID of the notebook

# S3 bucket information
output "datasets_bucket_name"    # Name of the datasets bucket
output "datasets_bucket_arn"     # ARN of the datasets bucket
output "models_bucket_name"      # Name of the models bucket
output "models_bucket_arn"       # ARN of the models bucket
output "all_s3_bucket_arns"      # All S3 bucket ARNs accessible

# IAM information
output "iam_role_arn"           # ARN of the IAM role
output "iam_role_name"          # Name of the IAM role

# Security group information
output "security_group_id"       # ID of the security group
output "security_group_arn"      # ARN of the security group
output "all_security_group_ids"  # All attached security groups

# Logging information
output "cloudwatch_log_group_name"  # CloudWatch log group name
output "cloudwatch_log_group_arn"   # CloudWatch log group ARN

# Network information
output "network_interface_id"    # ENI ID of the notebook
```

## Examples

### Example 1: Basic Development Environment

```hcl
aws_region   = "us-east-1"
project_name = "ml-dev"
environment  = "dev"

instance_type = "ml.t3.medium"
volume_size   = 10

vpc_id         = "vpc-12345678"
subnet_id      = "subnet-private-123"
vpc_cidr_block = "10.0.0.0/16"

direct_internet_access = "Disabled"
root_access            = "Disabled"

s3_bucket_arns = [
  "arn:aws:s3:::ml-dev-data"
]
```

### Example 2: Production Environment with Encryption

```hcl
aws_region   = "us-east-1"
project_name = "ml-prod"
environment  = "prod"

instance_type = "ml.m5.xlarge"
volume_size   = 50

vpc_id         = "vpc-87654321"
subnet_id      = "subnet-private-456"
vpc_cidr_block = "10.1.0.0/16"

direct_internet_access = "Disabled"
root_access            = "Disabled"

# Encryption
kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/abc123..."

# Permissions boundary for compliance
iam_role_permissions_boundary = "arn:aws:iam::123456789012:policy/OrgBoundary"

s3_bucket_arns = [
  "arn:aws:s3:::ml-prod-data",
  "arn:aws:s3:::ml-prod-models"
]

# CloudWatch logs retention
cloudwatch_logs_retention_days = 90

default_tags = {
  Environment = "Production"
  Compliance  = "Required"
  DataClass   = "Sensitive"
}
```

### Example 3: GPU Instance with Custom Lifecycle

```hcl
aws_region   = "us-east-1"
project_name = "ml-training"
environment  = "dev"

instance_type = "ml.p3.2xlarge"  # GPU instance
volume_size   = 100

vpc_id         = "vpc-12345678"
subnet_id      = "subnet-private-789"
vpc_cidr_block = "10.0.0.0/16"

# Lifecycle configuration for GPU drivers and frameworks
create_lifecycle_config = true
lifecycle_config_on_create = base64encode(<<-EOF
  #!/bin/bash
  set -e
  
  # Install GPU-accelerated libraries
  sudo -u ec2-user -i <<'USEREOF'
  source /home/ec2-user/anaconda3/bin/activate pytorch_p39
  pip install --upgrade pip
  pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu118
  pip install transformers accelerate
  source /home/ec2-user/anaconda3/bin/deactivate
  USEREOF
EOF
)

s3_bucket_arns = [
  "arn:aws:s3:::ml-training-data",
  "arn:aws:s3:::ml-model-artifacts"
]
```

## Troubleshooting

### Notebook Instance Fails to Start

**Issue**: Notebook instance is stuck in "Pending" or fails to start.

**Solutions**:
1. Check VPC endpoints are configured correctly
2. Verify security group allows outbound traffic to VPC endpoints
3. Check CloudWatch logs: `/aws/sagemaker/NotebookInstances/[notebook-name]`
4. Ensure IAM role has VPC access permissions

### Cannot Access S3 Buckets

**Issue**: Unable to read/write to S3 from the notebook.

**Solutions**:
1. Verify S3 bucket ARNs in `s3_bucket_arns` variable
2. Check S3 VPC endpoint is configured
3. Verify security group allows HTTPS traffic to S3 prefix list
4. Test with AWS CLI: `aws s3 ls s3://your-bucket/`

### Lifecycle Configuration Fails

**Issue**: Lifecycle script fails during instance creation/start.

**Solutions**:
1. Check CloudWatch logs for script errors
2. Ensure script is properly base64 encoded
3. Test script locally before encoding
4. Add error handling: `set -e` and proper logging

### VPC Endpoint Connection Issues

**Issue**: Cannot connect to AWS services from private subnet.

**Solutions**:
1. Verify VPC endpoints exist: `aws ec2 describe-vpc-endpoints`
2. Check private DNS is enabled for interface endpoints
3. Verify security groups allow HTTPS from notebook security group
4. Ensure route tables are properly configured

## Cost Optimization

### Instance Selection
- Use `ml.t3.medium` for development ($0.05/hour)
- Stop instances when not in use
- Consider spot instances for non-production

### Storage
- Start with minimum 5 GB, increase as needed
- Clean up unused data regularly
- Use S3 for long-term storage

### Lifecycle
- Automatically stop instances after idle time
- Use lifecycle configs to clean up temp files

## Security Best Practices

1. ✅ **Use Private Subnets** - Deploy in private subnets without direct internet access
2. ✅ **Disable Root Access** - Set `root_access = "Disabled"`
3. ✅ **Enable Encryption** - Use KMS encryption for EBS volumes
4. ✅ **Least Privilege IAM** - Only grant necessary S3 bucket access
5. ✅ **Use IMDSv2** - Instance metadata service v2 is enforced
6. ✅ **Enable CloudWatch Logs** - Monitor notebook activity
7. ✅ **Apply Tags** - Use tags for cost tracking and compliance
8. ✅ **Permissions Boundary** - Use boundaries for organizational compliance
9. ✅ **Security Groups** - Restrict inbound/outbound traffic
10. ✅ **VPC Endpoints** - Use VPC endpoints for AWS service access

## Maintenance

### Updating the Notebook

```bash
# Modify variables in terraform.tfvars
# For example, change instance type

# Apply changes
terraform apply
```

**Note**: Some changes (like instance type) require stopping the notebook instance.

### Destroying Resources

```bash
# Remove all resources
terraform destroy
```

**Warning**: This will delete the notebook instance and all local data. Ensure important data is saved to S3.

## Git Repository Access

This module includes full support for Git integration. See [GIT_SETUP.md](GIT_SETUP.md) for detailed instructions on:

- Cloning public and private repositories
- AWS CodeCommit integration
- GitHub/GitLab authentication with Secrets Manager
- SSH vs HTTPS configuration
- Automatic repository cloning on notebook start

**Quick Start:**
```hcl
# In terraform.tfvars:
enable_git_access = true  # Already enabled by default!
default_code_repository = "https://github.com/username/repo-name"
```

## Support and Contributions

For issues, questions, or contributions:
- Review AWS SageMaker documentation
- Check Terraform AWS provider documentation
- Review CloudWatch logs for debugging
- See [GIT_SETUP.md](GIT_SETUP.md) for Git-related issues

## Documentation

- **[README.md](README.md)** - This file, comprehensive module documentation
- **[S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md)** - Complete guide for S3 datasets and models storage
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Step-by-step deployment instructions
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick command reference
- **[GIT_SETUP.md](GIT_SETUP.md)** - Git repository integration guide
- **[vpc_endpoints_example.tf](vpc_endpoints_example.tf)** - VPC endpoints configuration example

## License

This module is provided as-is for use in your AWS environment.

## Additional Resources

- [AWS SageMaker Documentation](https://docs.aws.amazon.com/sagemaker/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [SageMaker Notebook Instances](https://docs.aws.amazon.com/sagemaker/latest/dg/nbi.html)
- [VPC Endpoints for SageMaker](https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-interface-endpoint.html)

```

Now let me create a sample Jupyter notebook showing how to install gsutil and migrate data from Google Cloud Storage to S3:

```json
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Google Cloud Storage to S3 Data Migration\n",
    "\n",
    "This notebook demonstrates how to:\n",
    "1. Install gsutil in your SageMaker notebook\n",
    "2. Download datasets from Google Cloud Storage\n",
    "3. Upload them to your S3 buckets\n",
    "\n",
    "**Prerequisites:**\n",
    "- Google Cloud credentials (if accessing private GCS buckets)\n",
    "- AWS credentials (automatically configured in SageMaker notebooks)\n",
    "- Deployed S3 buckets from Terraform"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Step 1: Install gsutil\n",
    "\n",
    "Install the Google Cloud SDK which includes gsutil."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Install gsutil (Google Cloud Storage utility)\n",
    "!pip install gsutil --quiet\n",
    "\n",
    "# Verify installation\n",
    "!gsutil version"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Step 2: Configure Google Cloud Credentials (Optional)\n",
    "\n",
    "Only needed if accessing private GCS buckets. For public buckets, skip this step."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Option 1: If you have a service account key JSON file in S3\n",
    "# !aws s3 cp s3://your-bucket/gcp-credentials.json /tmp/gcp-credentials.json\n",
    "# import os\n",
    "# os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = '/tmp/gcp-credentials.json'\n",
    "\n",
    "# Option 2: For public buckets, no authentication needed\n",
    "print(\"Using anonymous access for public GCS buckets\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Step 3: Get Your S3 Bucket Names\n",
    "\n",
    "These were created by Terraform. Check your outputs:\n",
    "```bash\n",
    "terraform output datasets_bucket_name\n",
    "terraform output models_bucket_name\n",
    "```"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import boto3\n",
    "\n",
    "# Replace with your actual bucket names from terraform output\n",
    "DATASETS_BUCKET = \"your-project-dev-datasets\"  # Change this!\n",
    "MODELS_BUCKET = \"your-project-dev-models\"      # Change this!\n",
    "\n",
    "# Or auto-discover buckets\n",
    "s3 = boto3.client('s3')\n",
    "response = s3.list_buckets()\n",
    "\n",
    "print(\"Available S3 buckets:\")\n",
    "for bucket in response['Buckets']:\n",
    "    if 'dataset' in bucket['Name'].lower() or 'model' in bucket['Name'].lower():\n",
    "        print(f\"  - {bucket['Name']}\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Step 4: Download Data from Google Cloud Storage\n",
    "\n",
    "Example: Download a public dataset from GCS"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import os\n",
    "\n",
    "# Example: Public GCS bucket\n",
    "GCS_BUCKET = \"gs://your-gcs-bucket-name\"\n",
    "GCS_FILE = \"path/to/dataset.csv\"\n",
    "LOCAL_DIR = \"/tmp/gcs_downloads\"\n",
    "\n",
    "# Create local directory\n",
    "os.makedirs(LOCAL_DIR, exist_ok=True)\n",
    "\n",
    "# Download from GCS\n",
    "print(f\"Downloading from {GCS_BUCKET}/{GCS_FILE}...\")\n",
    "!gsutil -m cp {GCS_BUCKET}/{GCS_FILE} {LOCAL_DIR}/\n",
    "\n",
    "print(f\"Downloaded files:\")\n",
    "!ls -lh {LOCAL_DIR}"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "### Alternative: Download Entire Directory"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Download entire directory (recursive)\n",
    "# GCS_DIR = \"gs://your-gcs-bucket/datasets/\"\n",
    "# !gsutil -m cp -r {GCS_DIR} {LOCAL_DIR}/"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Step 5: Upload Data to S3\n",
    "\n",
    "Upload the downloaded data to your S3 datasets bucket"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import boto3\n",
    "import os\n",
    "from pathlib import Path\n",
    "\n",
    "s3 = boto3.client('s3')\n",
    "\n",
    "# Upload files to S3\n",
    "def upload_directory_to_s3(local_directory, bucket_name, s3_prefix='raw/'):\n",
    "    \"\"\"\n",
    "    Upload all files from local directory to S3\n",
    "    \"\"\"\n",
    "    for root, dirs, files in os.walk(local_directory):\n",
    "        for file in files:\n",
    "            local_path = os.path.join(root, file)\n",
    "            relative_path = os.path.relpath(local_path, local_directory)\n",
    "            s3_key = f\"{s3_prefix}{relative_path}\"\n",
    "            \n",
    "            print(f\"Uploading {local_path} to s3://{bucket_name}/{s3_key}\")\n",
    "            s3.upload_file(local_path, bucket_name, s3_key)\n",
    "    \n",
    "    print(f\"\\n✅ Upload complete to s3://{bucket_name}/{s3_prefix}\")\n",
    "\n",
    "# Upload downloaded files\n",
    "upload_directory_to_s3(LOCAL_DIR, DATASETS_BUCKET, s3_prefix='raw/')"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "### Alternative: Using AWS CLI"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Alternative method using AWS CLI (often faster for large directories)\n",
    "# !aws s3 cp {LOCAL_DIR}/ s3://{DATASETS_BUCKET}/raw/ --recursive"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Step 6: Verify Upload and Clean Up"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# List files in S3 bucket\n",
    "print(f\"Files in s3://{DATASETS_BUCKET}/raw/:\")\n",
    "!aws s3 ls s3://{DATASETS_BUCKET}/raw/ --recursive --human-readable\n",
    "\n",
    "# Clean up local temporary files\n",
    "import shutil\n",
    "shutil.rmtree(LOCAL_DIR)\n",
    "print(f\"\\n✅ Cleaned up local directory: {LOCAL_DIR}\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Step 7: Load and Verify Data\n",
    "\n",
    "Read the data directly from S3 using pandas"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import pandas as pd\n",
    "\n",
    "# Read CSV from S3\n",
    "s3_path = f\"s3://{DATASETS_BUCKET}/raw/dataset.csv\"\n",
    "print(f\"Reading data from {s3_path}...\")\n",
    "\n",
    "df = pd.read_csv(s3_path)\n",
    "\n",
    "print(f\"\\nDataset shape: {df.shape}\")\n",
    "print(f\"\\nFirst few rows:\")\n",
    "df.head()"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Complete Migration Script (All-in-One)\n",
    "\n",
    "Here's a complete function to migrate data from GCS to S3:"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "def migrate_gcs_to_s3(gcs_uri, s3_bucket, s3_prefix='raw/', temp_dir='/tmp/migration'):\n",
    "    \"\"\"\n",
    "    Migrate data from Google Cloud Storage to AWS S3\n",
    "    \n",
    "    Args:\n",
    "        gcs_uri (str): GCS URI (e.g., 'gs://bucket-name/path/to/data')\n",
    "        s3_bucket (str): Target S3 bucket name\n",
    "        s3_prefix (str): S3 key prefix (default: 'raw/')\n",
    "        temp_dir (str): Local temporary directory for download\n",
    "    \"\"\"\n",
    "    import subprocess\n",
    "    import os\n",
    "    import boto3\n",
    "    import shutil\n",
    "    \n",
    "    # Create temp directory\n",
    "    os.makedirs(temp_dir, exist_ok=True)\n",
    "    \n",
    "    try:\n",
    "        # Download from GCS\n",
    "        print(f\"📥 Downloading from {gcs_uri}...\")\n",
    "        subprocess.run(\n",
    "            ['gsutil', '-m', 'cp', '-r', gcs_uri, temp_dir],\n",
    "            check=True\n",
    "        )\n",
    "        print(\"✅ Download complete\")\n",
    "        \n",
    "        # Upload to S3\n",
    "        print(f\"\\n📤 Uploading to s3://{s3_bucket}/{s3_prefix}...\")\n",
    "        s3 = boto3.client('s3')\n",
    "        \n",
    "        for root, dirs, files in os.walk(temp_dir):\n",
    "            for file in files:\n",
    "                local_path = os.path.join(root, file)\n",
    "                relative_path = os.path.relpath(local_path, temp_dir)\n",
    "                s3_key = f\"{s3_prefix}{relative_path}\"\n",
    "                \n",
    "                print(f\"  Uploading {relative_path}...\")\n",
    "                s3.upload_file(local_path, s3_bucket, s3_key)\n",
    "        \n",
    "        print(\"✅ Upload complete\")\n",
    "        \n",
    "        # Verify\n",
    "        print(f\"\\n📋 Files in s3://{s3_bucket}/{s3_prefix}:\")\n",
    "        response = s3.list_objects_v2(Bucket=s3_bucket, Prefix=s3_prefix)\n",
    "        for obj in response.get('Contents', []):\n",
    "            print(f\"  - {obj['Key']} ({obj['Size']} bytes)\")\n",
    "        \n",
    "    finally:\n",
    "        # Clean up\n",
    "        if os.path.exists(temp_dir):\n",
    "            shutil.rmtree(temp_dir)\n",
    "            print(f\"\\n🧹 Cleaned up temporary directory\")\n",
    "\n",
    "# Example usage:\n",
    "# migrate_gcs_to_s3(\n",
    "#     gcs_uri='gs://your-gcs-bucket/datasets/dataset.csv',\n",
    "#     s3_bucket=DATASETS_BUCKET,\n",
    "#     s3_prefix='raw/'\n",
    "# )"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Tips and Best Practices\n",
    "\n",
    "### 1. Use Multipart Upload for Large Files\n",
    "\n",
    "For files > 100MB, use multipart upload:"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "from boto3.s3.transfer import TransferConfig\n",
    "\n",
    "# Configure multipart upload\n",
    "config = TransferConfig(\n",
    "    multipart_threshold=1024 * 25,  # 25 MB\n",
    "    max_concurrency=10,\n",
    "    multipart_chunksize=1024 * 25,  # 25 MB\n",
    "    use_threads=True\n",
    ")\n",
    "\n",
    "# Upload large file\n",
    "# s3.upload_file('large_file.csv', DATASETS_BUCKET, 'raw/large_file.csv', Config=config)"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "### 2. Convert CSV to Parquet for Better Performance"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Read CSV and save as Parquet (10-100x smaller!)\n",
    "# df = pd.read_csv('large_dataset.csv')\n",
    "# df.to_parquet(f's3://{DATASETS_BUCKET}/processed/dataset.parquet', compression='gzip')"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "### 3. Monitor Transfer Progress"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "from tqdm import tqdm\n",
    "\n",
    "class ProgressPercentage:\n",
    "    def __init__(self, filename):\n",
    "        self._filename = filename\n",
    "        self._size = float(os.path.getsize(filename))\n",
    "        self._seen_so_far = 0\n",
    "        self._lock = threading.Lock()\n",
    "\n",
    "    def __call__(self, bytes_amount):\n",
    "        with self._lock:\n",
    "            self._seen_so_far += bytes_amount\n",
    "            percentage = (self._seen_so_far / self._size) * 100\n",
    "            print(f\"\\r{self._filename}: {percentage:.2f}%\", end='')\n",
    "\n",
    "# Usage:\n",
    "# s3.upload_file(filename, bucket, key, Callback=ProgressPercentage(filename))"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Next Steps\n",
    "\n",
    "After migrating your data to S3:\n",
    "\n",
    "1. **Organize your data** following the recommended structure:\n",
    "   - `raw/` - Original datasets\n",
    "   - `processed/` - Cleaned data\n",
    "   - `features/` - Feature engineering outputs\n",
    "\n",
    "2. **Start your ML workflow** using data directly from S3\n",
    "\n",
    "3. **Save models** to the models bucket:\n",
    "   ```python\n",
    "   import joblib\n",
    "   joblib.dump(model, f's3://{MODELS_BUCKET}/production/model-v1.0.pkl')\n",
    "   ```\n",
    "\n",
    "4. **See the full S3 usage guide**: [S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md)\n",
    "\n",
    "**Remember:** Once data is in S3, you won't need to download from GCS again!"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.8.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}

```

Let me create a Python script instead that can be run in the notebook:

```python
#!/usr/bin/env python3
"""
Google Cloud Storage to S3 Migration Script
===========================================

This script demonstrates how to:
1. Install and use gsutil in your SageMaker notebook
2. Download datasets from Google Cloud Storage
3. Upload them to your S3 buckets

Prerequisites:
- Google Cloud credentials (if accessing private GCS buckets)
- AWS credentials (automatically configured in SageMaker notebooks)
- Deployed S3 buckets from Terraform

Usage:
    Run this in your Jupyter notebook or as a standalone script:
    
    In Jupyter:
    %run gcs_to_s3_migration.py
    
    From terminal:
    python gcs_to_s3_migration.py
"""

import os
import sys
import subprocess
import boto3
import shutil
from pathlib import Path


class GCStoS3Migrator:
    """Migrate data from Google Cloud Storage to AWS S3"""
    
    def __init__(self, datasets_bucket=None, models_bucket=None):
        """
        Initialize migrator
        
        Args:
            datasets_bucket (str): S3 datasets bucket name (from terraform output)
            models_bucket (str): S3 models bucket name (from terraform output)
        """
        self.s3_client = boto3.client('s3')
        self.datasets_bucket = datasets_bucket
        self.models_bucket = models_bucket
        
        # Auto-discover buckets if not provided
        if not datasets_bucket or not models_bucket:
            self._discover_buckets()
    
    def _discover_buckets(self):
        """Auto-discover S3 buckets created by Terraform"""
        response = self.s3_client.list_buckets()
        
        print("Discovering S3 buckets...")
        for bucket in response['Buckets']:
            name = bucket['Name']
            if 'dataset' in name.lower():
                self.datasets_bucket = self.datasets_bucket or name
                print(f"  Found datasets bucket: {name}")
            elif 'model' in name.lower():
                self.models_bucket = self.models_bucket or name
                print(f"  Found models bucket: {name}")
        
        if not self.datasets_bucket:
            print("⚠️  Warning: No datasets bucket found. Please specify manually.")
        if not self.models_bucket:
            print("⚠️  Warning: No models bucket found. Please specify manually.")
    
    def install_gsutil(self):
        """Install gsutil if not already installed"""
        print("Installing gsutil...")
        try:
            subprocess.run(['gsutil', 'version'], 
                         capture_output=True, check=True)
            print("✅ gsutil is already installed")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("Installing gsutil via pip...")
            subprocess.run([sys.executable, '-m', 'pip', 'install', 
                          'gsutil', '--quiet'], check=True)
            print("✅ gsutil installed successfully")
        
        # Verify installation
        result = subprocess.run(['gsutil', 'version'], 
                              capture_output=True, text=True)
        print(f"gsutil version: {result.stdout.strip()}")
    
    def download_from_gcs(self, gcs_uri, local_dir='/tmp/gcs_downloads'):
        """
        Download data from Google Cloud Storage
        
        Args:
            gcs_uri (str): GCS URI (e.g., 'gs://bucket-name/path/to/file')
            local_dir (str): Local directory to download to
            
        Returns:
            str: Path to downloaded directory
        """
        os.makedirs(local_dir, exist_ok=True)
        
        print(f"\n📥 Downloading from {gcs_uri}...")
        try:
            subprocess.run(
                ['gsutil', '-m', 'cp', '-r', gcs_uri, local_dir],
                check=True
            )
            print("✅ Download complete")
            
            # Show downloaded files
            print(f"\nDownloaded files in {local_dir}:")
            for file in os.listdir(local_dir):
                file_path = os.path.join(local_dir, file)
                size = os.path.getsize(file_path)
                print(f"  - {file} ({size:,} bytes)")
            
            return local_dir
        
        except subprocess.CalledProcessError as e:
            print(f"❌ Error downloading from GCS: {e}")
            raise
    
    def upload_to_s3(self, local_directory, s3_bucket, s3_prefix='raw/'):
        """
        Upload files from local directory to S3
        
        Args:
            local_directory (str): Local directory containing files
            s3_bucket (str): Target S3 bucket name
            s3_prefix (str): S3 key prefix (default: 'raw/')
        """
        if not s3_bucket:
            raise ValueError("S3 bucket not specified")
        
        print(f"\n📤 Uploading to s3://{s3_bucket}/{s3_prefix}...")
        
        uploaded_files = []
        for root, dirs, files in os.walk(local_directory):
            for file in files:
                local_path = os.path.join(root, file)
                relative_path = os.path.relpath(local_path, local_directory)
                s3_key = f"{s3_prefix}{relative_path}"
                
                print(f"  Uploading {relative_path}...")
                self.s3_client.upload_file(local_path, s3_bucket, s3_key)
                uploaded_files.append(s3_key)
        
        print(f"✅ Upload complete! {len(uploaded_files)} files uploaded")
        return uploaded_files
    
    def verify_s3_upload(self, bucket, prefix):
        """
        Verify files were uploaded to S3
        
        Args:
            bucket (str): S3 bucket name
            prefix (str): S3 key prefix
        """
        print(f"\n📋 Verifying files in s3://{bucket}/{prefix}:")
        
        response = self.s3_client.list_objects_v2(
            Bucket=bucket,
            Prefix=prefix
        )
        
        total_size = 0
        for obj in response.get('Contents', []):
            size = obj['Size']
            total_size += size
            print(f"  - {obj['Key']} ({size:,} bytes)")
        
        print(f"\nTotal: {len(response.get('Contents', []))} files, "
              f"{total_size:,} bytes ({total_size / 1024 / 1024:.2f} MB)")
    
    def migrate(self, gcs_uri, s3_prefix='raw/', 
                temp_dir='/tmp/gcs_migration', cleanup=True):
        """
        Complete migration from GCS to S3
        
        Args:
            gcs_uri (str): GCS URI to download from
            s3_prefix (str): S3 prefix to upload to (default: 'raw/')
            temp_dir (str): Temporary local directory
            cleanup (bool): Whether to clean up temp files after upload
            
        Returns:
            list: S3 keys of uploaded files
        """
        if not self.datasets_bucket:
            raise ValueError(
                "Datasets bucket not found. Please specify manually:\n"
                "  migrator = GCStoS3Migrator(datasets_bucket='your-bucket-name')"
            )
        
        try:
            # Download from GCS
            self.download_from_gcs(gcs_uri, temp_dir)
            
            # Upload to S3
            uploaded_files = self.upload_to_s3(
                temp_dir, 
                self.datasets_bucket, 
                s3_prefix
            )
            
            # Verify
            self.verify_s3_upload(self.datasets_bucket, s3_prefix)
            
            return uploaded_files
        
        finally:
            if cleanup and os.path.exists(temp_dir):
                shutil.rmtree(temp_dir)
                print(f"\n🧹 Cleaned up temporary directory: {temp_dir}")


def example_usage():
    """Example usage of the GCS to S3 migrator"""
    
    print("=" * 60)
    print("GCS to S3 Migration Example")
    print("=" * 60)
    
    # Initialize migrator (auto-discovers S3 buckets)
    migrator = GCStoS3Migrator()
    
    # Or specify buckets manually:
    # migrator = GCStoS3Migrator(
    #     datasets_bucket='my-project-dev-datasets',
    #     models_bucket='my-project-dev-models'
    # )
    
    # Install gsutil
    migrator.install_gsutil()
    
    # Example: Download and migrate a public dataset
    # Replace with your actual GCS URI
    gcs_uri = 'gs://your-gcs-bucket/path/to/dataset.csv'
    
    print(f"\n{'='*60}")
    print("To migrate data from GCS to S3, use:")
    print(f"{'='*60}")
    print(f"""
# Migrate a single file
migrator.migrate(
    gcs_uri='gs://your-gcs-bucket/path/to/dataset.csv',
    s3_prefix='raw/'
)

# Migrate an entire directory
migrator.migrate(
    gcs_uri='gs://your-gcs-bucket/datasets/*',
    s3_prefix='raw/datasets/'
)

# Migrate without cleanup (keep local copies)
migrator.migrate(
    gcs_uri='gs://your-gcs-bucket/data/',
    s3_prefix='raw/',
    cleanup=False
)
""")
    
    print(f"\n{'='*60}")
    print("After migration, access data from S3 using pandas:")
    print(f"{'='*60}")
    print(f"""
import pandas as pd

# Read from S3
df = pd.read_csv('s3://{migrator.datasets_bucket}/raw/dataset.csv')

# Or using boto3
import boto3
s3 = boto3.client('s3')
s3.download_file(
    Bucket='{migrator.datasets_bucket}',
    Key='raw/dataset.csv',
    Filename='/tmp/dataset.csv'
)
""")


def quick_install_gsutil():
    """Quick function to just install gsutil"""
    print("Installing gsutil...")
    try:
        subprocess.run(['gsutil', 'version'], 
                     capture_output=True, check=True)
        print("✅ gsutil is already installed")
    except (subprocess.CalledProcessError, FileNotFoundError):
        subprocess.run([sys.executable, '-m', 'pip', 'install', 
                      'gsutil', '--quiet'], check=True)
        print("✅ gsutil installed successfully")
    
    # Show version
    result = subprocess.run(['gsutil', 'version'], 
                          capture_output=True, text=True)
    print(f"\n{result.stdout}")


if __name__ == '__main__':
    # Run example usage
    example_usage()
    
    print(f"\n{'='*60}")
    print("Ready to migrate! Import this module in your notebook:")
    print(f"{'='*60}")
    print("""
from gcs_to_s3_migration import GCStoS3Migrator, quick_install_gsutil

# Quick install gsutil
quick_install_gsutil()

# Create migrator and migrate data
migrator = GCStoS3Migrator()
migrator.migrate('gs://your-gcs-bucket/path/to/data', s3_prefix='raw/')
""")

```

Excellent! Now let me create one final document - a quick start guide specifically for using gsutil and S3:

```markdown
# gsutil Quick Start Guide

This guide shows you how to install and use gsutil in your SageMaker notebook to download datasets from Google Cloud Storage and upload them to your S3 buckets.

## TL;DR - Quick Start

```python
# In your Jupyter notebook:

# 1. Install gsutil
!pip install gsutil

# 2. Download from Google Cloud Storage
!gsutil -m cp gs://your-gcs-bucket/dataset.csv /tmp/

# 3. Upload to S3 (replace with your bucket name from terraform output)
!aws s3 cp /tmp/dataset.csv s3://your-project-dev-datasets/raw/

# 4. Verify and read data
import pandas as pd
df = pd.read_csv('s3://your-project-dev-datasets/raw/dataset.csv')
```

## Detailed Instructions

### Step 1: Get Your S3 Bucket Names

After deploying with Terraform, get your bucket names:

```bash
terraform output datasets_bucket_name
terraform output models_bucket_name
```

### Step 2: Install gsutil in Your Notebook

Open a notebook cell and run:

```python
!pip install gsutil
!gsutil version
```

### Step 3: Download from GCS

#### For Public Buckets (No Authentication Needed)

```python
# Download a single file
!gsutil cp gs://public-bucket/dataset.csv /tmp/

# Download multiple files
!gsutil -m cp gs://public-bucket/data/*.csv /tmp/

# Download entire directory
!gsutil -m cp -r gs://public-bucket/datasets/ /tmp/datasets/
```

#### For Private Buckets (Authentication Required)

You'll need a Google Cloud service account key:

```python
# 1. Upload your GCP service account key to S3 (one-time setup)
# From your local machine:
# aws s3 cp gcp-credentials.json s3://your-project-dev-datasets/credentials/

# 2. In your notebook, download and configure credentials
!aws s3 cp s3://your-project-dev-datasets/credentials/gcp-credentials.json /tmp/

# 3. Set environment variable
import os
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = '/tmp/gcp-credentials.json'

# 4. Now you can access private buckets
!gsutil cp gs://private-bucket/dataset.csv /tmp/
```

### Step 4: Upload to S3

#### Using AWS CLI (Simplest)

```python
# Upload single file
!aws s3 cp /tmp/dataset.csv s3://your-project-dev-datasets/raw/

# Upload directory
!aws s3 cp /tmp/datasets/ s3://your-project-dev-datasets/raw/ --recursive

# Sync directory (only uploads changed files)
!aws s3 sync /tmp/datasets/ s3://your-project-dev-datasets/raw/
```

#### Using Boto3 (More Control)

```python
import boto3
import os

s3 = boto3.client('s3')
bucket = 'your-project-dev-datasets'

# Upload single file
s3.upload_file('/tmp/dataset.csv', bucket, 'raw/dataset.csv')

# Upload directory
for root, dirs, files in os.walk('/tmp/datasets'):
    for file in files:
        local_path = os.path.join(root, file)
        relative_path = os.path.relpath(local_path, '/tmp/datasets')
        s3_key = f'raw/{relative_path}'
        print(f'Uploading {relative_path}...')
        s3.upload_file(local_path, bucket, s3_key)
```

### Step 5: Clean Up and Verify

```python
# Clean up local files
!rm -rf /tmp/datasets/

# List files in S3
!aws s3 ls s3://your-project-dev-datasets/raw/ --recursive --human-readable

# Verify by reading data
import pandas as pd
df = pd.read_csv('s3://your-project-dev-datasets/raw/dataset.csv')
print(df.head())
```

## Using the Migration Script

We've provided a Python script for easier migration:

```python
# In your notebook
from gcs_to_s3_migration import GCStoS3Migrator, quick_install_gsutil

# Install gsutil
quick_install_gsutil()

# Create migrator (auto-discovers your S3 buckets)
migrator = GCStoS3Migrator()

# Migrate data (downloads from GCS, uploads to S3, cleans up)
migrator.migrate(
    gcs_uri='gs://your-gcs-bucket/path/to/data',
    s3_prefix='raw/'
)
```

The script handles:
- ✅ Installing gsutil
- ✅ Downloading from GCS
- ✅ Uploading to S3
- ✅ Verification
- ✅ Cleanup

## Common Commands

### gsutil Commands

```bash
# List buckets
!gsutil ls

# List files in bucket
!gsutil ls gs://bucket-name/

# List files recursively
!gsutil ls -r gs://bucket-name/

# Get file info
!gsutil ls -l gs://bucket-name/file.csv

# Copy with progress
!gsutil -m cp -r gs://source/path /tmp/

# Copy between GCS buckets
!gsutil cp gs://source-bucket/file gs://dest-bucket/file
```

### AWS S3 Commands

```bash
# List buckets
!aws s3 ls

# List files in bucket
!aws s3 ls s3://bucket-name/

# List files recursively
!aws s3 ls s3://bucket-name/ --recursive

# Copy to S3
!aws s3 cp /tmp/file.csv s3://bucket-name/path/

# Copy from S3
!aws s3 cp s3://bucket-name/file.csv /tmp/

# Sync directories
!aws s3 sync /tmp/local/ s3://bucket-name/remote/

# Move files (copy and delete source)
!aws s3 mv /tmp/file.csv s3://bucket-name/file.csv
```

## Best Practices

### 1. Use Parquet Instead of CSV

Parquet is 10-100x smaller and faster:

```python
import pandas as pd

# Read CSV from GCS
df = pd.read_csv('/tmp/dataset.csv')

# Save as Parquet to S3
df.to_parquet(
    's3://your-project-dev-datasets/processed/dataset.parquet',
    compression='gzip',
    index=False
)
```

### 2. Use Multipart Upload for Large Files

```python
from boto3.s3.transfer import TransferConfig

config = TransferConfig(
    multipart_threshold=1024 * 25,  # 25 MB
    max_concurrency=10,
    multipart_chunksize=1024 * 25,
    use_threads=True
)

s3.upload_file(
    'large_file.csv',
    bucket,
    'raw/large_file.csv',
    Config=config
)
```

### 3. Organize Your Data

Follow this directory structure in S3:

```
your-project-dev-datasets/
├── raw/              # Original data from GCS
├── processed/        # Cleaned data
├── features/         # Feature engineering outputs
└── archive/          # Old versions (lifecycle rules apply)

your-project-dev-models/
├── experiments/      # Experimental models
├── production/       # Production-ready models
└── checkpoints/      # Training checkpoints
```

### 4. One-Time Migration

You typically only need to migrate data **once**. After that:
- Work directly with S3
- No need to keep downloading from GCS
- S3 is faster and cheaper for AWS workloads

### 5. Delete Temporary Files

Always clean up `/tmp` after migration:

```python
import shutil
shutil.rmtree('/tmp/datasets')
```

## Troubleshooting

### Error: "No module named 'gsutil'"

```python
!pip install gsutil
```

### Error: "401 Anonymous caller does not have access"

You're trying to access a private GCS bucket. Set up authentication:

```python
import os
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = '/path/to/credentials.json'
```

### Error: "Access Denied" (S3)

Verify your bucket name and check IAM permissions:

```python
import boto3
s3 = boto3.client('s3')

# Test bucket access
try:
    s3.head_bucket(Bucket='your-bucket-name')
    print("✅ Bucket accessible")
except Exception as e:
    print(f"❌ Error: {e}")
```

### Slow Transfers

For large datasets:
1. Use `-m` flag for parallel transfers: `gsutil -m cp`
2. Use AWS CLI for S3 uploads (faster than boto3)
3. Consider using AWS DataSync for > 1TB datasets

## Cost Optimization

### Data Transfer Costs

- **GCS → Internet → EC2 → S3**: ~$0.12/GB (GCS egress) + $0.01/GB (S3 ingress)
- **Tip**: For very large datasets (>10TB), consider:
  - AWS DataSync
  - Google Transfer Service to S3
  - Physical data transfer (AWS Snowball)

### Storage Costs

- **S3 Standard**: $0.023/GB/month
- **S3 IA**: $0.0125/GB/month (good for old data)
- **S3 Glacier**: $0.004/GB/month (archive)

Lifecycle policies (already configured) automatically move old data to cheaper storage.

## Next Steps

After migrating your data:

1. **Read S3 Usage Guide**: See [S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md) for comprehensive examples

2. **Start ML Workflow**: Work directly with S3 data
   ```python
   import pandas as pd
   df = pd.read_csv('s3://your-project-dev-datasets/raw/data.csv')
   ```

3. **Save Models**: Store trained models in S3
   ```python
   import joblib
   joblib.dump(model, 's3://your-project-dev-models/production/model.pkl')
   ```

4. **Set Up Lifecycle**: Data older than 90 days is automatically archived to save costs

## Examples

### Example 1: Public Dataset

```python
# Download from public GCS bucket
!gsutil cp gs://gcp-public-data-landsat/index.csv.gz /tmp/

# Upload to S3
!aws s3 cp /tmp/index.csv.gz s3://your-project-dev-datasets/raw/landsat/

# Read from S3
import pandas as pd
df = pd.read_csv('s3://your-project-dev-datasets/raw/landsat/index.csv.gz')
```

### Example 2: Private Dataset with Authentication

```python
import os

# Set up GCP credentials
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = '/tmp/gcp-credentials.json'

# Download from private GCS bucket
!gsutil -m cp -r gs://my-private-bucket/datasets/ /tmp/datasets/

# Upload to S3
!aws s3 sync /tmp/datasets/ s3://your-project-dev-datasets/raw/datasets/

# Clean up
!rm -rf /tmp/datasets/
```

### Example 3: Complete Pipeline

```python
from gcs_to_s3_migration import GCStoS3Migrator
import pandas as pd

# 1. Migrate data
migrator = GCStoS3Migrator(datasets_bucket='your-project-dev-datasets')
migrator.migrate('gs://source-bucket/data.csv', s3_prefix='raw/')

# 2. Process data
df = pd.read_csv('s3://your-project-dev-datasets/raw/data.csv')
df_clean = df.dropna()

# 3. Save processed data
df_clean.to_parquet(
    's3://your-project-dev-datasets/processed/data.parquet',
    compression='gzip'
)

# 4. Train model
from sklearn.ensemble import RandomForestClassifier
model = RandomForestClassifier()
model.fit(df_clean[['feature1', 'feature2']], df_clean['target'])

# 5. Save model
import joblib
joblib.dump(model, 's3://your-project-dev-models/production/model-v1.0.pkl')
```

## Additional Resources

- [gsutil Documentation](https://cloud.google.com/storage/docs/gsutil)
- [AWS CLI S3 Documentation](https://docs.aws.amazon.com/cli/latest/reference/s3/)
- [S3 Usage Guide](S3_USAGE_GUIDE.md)
- [Boto3 Documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html)

---

**Remember**: After the initial migration, you should work exclusively with S3 for your AWS ML workflows. You won't need to access GCS again unless you're importing new datasets!

```

Now let me run a final format check and create a summary:

Perfect! Now let me create a summary of all the changes:

```markdown
# S3 Buckets Setup Summary

## What Was Added

I've successfully added S3 bucket management to your SageMaker notebook Terraform infrastructure. Here's what's included:

### 1. **S3 Buckets Infrastructure** (`s3.tf`)

Created two managed S3 buckets:

#### Datasets Bucket
- **Purpose**: Store ML training/testing datasets
- **Features**:
  - ✅ Versioning enabled (protects against accidental deletion)
  - ✅ Server-side encryption (AES256 or optional KMS)
  - ✅ Public access blocked
  - ✅ Lifecycle policies:
    - Archive old versions to Glacier after 30 days
    - Delete old versions after 90 days
    - Optional transition to Infrequent Access storage
  - ✅ Automatic cleanup of incomplete multipart uploads

#### Models Bucket
- **Purpose**: Store trained model artifacts
- **Features**:
  - ✅ Versioning enabled
  - ✅ Server-side encryption
  - ✅ Public access blocked
  - ✅ Automatic IAM permissions

### 2. **Automatic IAM Permissions** (Updated `iam.tf`)

The SageMaker notebook IAM role now automatically includes permissions for:
- All managed S3 buckets (datasets, models)
- Any additional S3 buckets you specify via `s3_bucket_arns`

**Permissions granted**:
- `s3:GetObject` - Read files
- `s3:PutObject` - Write files
- `s3:DeleteObject` - Delete files
- `s3:ListBucket` - List bucket contents
- `s3:GetBucketLocation` - Get bucket location
- `s3:ListBucketMultipartUploads` - Manage large file uploads
- `s3:AbortMultipartUpload` - Clean up failed uploads

### 3. **Configuration Variables** (Updated `variables.tf`)

Added comprehensive configuration options:

```hcl
# Enable/disable bucket creation
create_datasets_bucket = true  # Default: true
create_models_bucket   = true  # Default: true

# Custom names (optional)
datasets_bucket_name = "my-custom-name"
models_bucket_name   = "my-custom-name"

# Versioning
enable_datasets_bucket_versioning = true
enable_models_bucket_versioning   = true

# Encryption
datasets_bucket_kms_key_id = "arn:aws:kms:..."
models_bucket_kms_key_id   = "arn:aws:kms:..."

# Lifecycle policies
enable_datasets_bucket_lifecycle = true
datasets_bucket_lifecycle_rules = { ... }
```

### 4. **Terraform Outputs** (Updated `outputs.tf`)

New outputs to get bucket information:

```hcl
output "datasets_bucket_name"    # Bucket name
output "datasets_bucket_arn"     # Bucket ARN
output "models_bucket_name"      # Bucket name
output "models_bucket_arn"       # Bucket ARN
output "all_s3_bucket_arns"      # All accessible bucket ARNs
```

### 5. **Documentation**

Created comprehensive guides:

- **[S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md)** - Complete guide covering:
  - Using S3 from notebooks (pandas, boto3, SageMaker SDK)
  - Migrating data from Google Cloud Storage
  - Working with large datasets
  - Cost optimization tips
  - Security best practices
  - Complete ML workflow examples

- **[GSUTIL_QUICKSTART.md](GSUTIL_QUICKSTART.md)** - Quick start guide for:
  - Installing gsutil in notebooks
  - Downloading from GCS
  - Uploading to S3
  - Common commands and troubleshooting

- **[gcs_to_s3_migration.py](gcs_to_s3_migration.py)** - Python script with:
  - Automated GCS → S3 migration
  - Auto-discovery of S3 buckets
  - Progress tracking
  - Error handling
  - Cleanup utilities

- **[terraform.tfvars.s3-example](terraform.tfvars.s3-example)** - Example configuration

- **Updated [README.md](README.md)** - Added S3 bucket management section

## How to Use

### Deploy the Infrastructure

1. **Copy the example configuration**:
   ```bash
   cp terraform.tfvars.s3-example terraform.tfvars
   ```

2. **Edit `terraform.tfvars`** with your settings:
   ```hcl
   project_name = "my-ml-project"
   environment  = "dev"
   vpc_id       = "vpc-xxx"
   subnet_id    = "subnet-xxx"
   
   # S3 buckets (enabled by default)
   create_datasets_bucket = true
   create_models_bucket   = true
   ```

3. **Deploy with Terraform**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Get your bucket names**:
   ```bash
   terraform output datasets_bucket_name
   terraform output models_bucket_name
   ```

### Use S3 in Your Notebooks

After deployment, you can immediately use S3 from your notebooks:

#### Option 1: Using Pandas (Easiest)

```python
import pandas as pd

# Read data from S3
df = pd.read_csv('s3://your-project-dev-datasets/raw/dataset.csv')

# Write data to S3
df.to_parquet('s3://your-project-dev-datasets/processed/data.parquet')
```

#### Option 2: Using Boto3

```python
import boto3

s3 = boto3.client('s3')

# Download from S3
s3.download_file('your-project-dev-datasets', 'raw/data.csv', '/tmp/data.csv')

# Upload to S3
s3.upload_file('/tmp/model.pkl', 'your-project-dev-models', 'production/model.pkl')
```

### Install gsutil and Migrate from GCS

In your notebook:

```python
# Install gsutil
!pip install gsutil

# Download from Google Cloud Storage
!gsutil -m cp gs://your-gcs-bucket/dataset.csv /tmp/

# Upload to S3
!aws s3 cp /tmp/dataset.csv s3://your-project-dev-datasets/raw/

# Or use the migration script
from gcs_to_s3_migration import GCStoS3Migrator

migrator = GCStoS3Migrator()
migrator.migrate('gs://your-gcs-bucket/data', s3_prefix='raw/')
```

## Key Benefits

### 1. **Cost Optimization**
- Lifecycle policies automatically move old data to cheaper storage
- Old versions → Glacier after 30 days (75% cost savings)
- Deleted after 90 days
- Parquet format = 10-100x smaller than CSV

### 2. **Data Protection**
- Versioning protects against accidental deletion
- Encryption at rest (AES256 or KMS)
- Public access blocked by default
- Backup and recovery capabilities

### 3. **Best Practices**
- Follows AWS S3 security best practices
- Automatic IAM permissions
- Organized directory structure
- Integration with SageMaker workflows

### 4. **Developer Productivity**
- Direct pandas/boto3 integration
- No manual bucket creation needed
- Automatic credential management
- Migration tools for GCS data

## Directory Structure Recommendation

Organize your S3 data like this:

```
your-project-dev-datasets/
├── raw/                    # Original data from GCS
│   ├── dataset1.csv
│   └── dataset2.parquet
├── processed/              # Cleaned data
│   ├── train.csv
│   └── test.csv
├── features/              # Feature engineering
│   └── features.parquet
└── archive/               # Old data (lifecycle rules)

your-project-dev-models/
├── experiments/           # Experimental models
│   └── exp-001/
├── production/            # Production models
│   └── model-v1.0/
└── checkpoints/           # Training checkpoints
```

## Cost Estimate

For a typical ML project:

**Storage Costs** (per month):
- 100 GB datasets: ~$2.30 (S3 Standard)
- 50 GB processed data: ~$1.15
- 10 GB models: ~$0.23
- **Total: ~$3.68/month**

With lifecycle policies:
- After 30 days, old versions → Glacier: ~$1.50/month
- **Savings: ~50-60%**

**Data Transfer**:
- GCS → AWS (one-time): ~$12 per 100 GB
- Within AWS: Free
- S3 → Internet: $9 per 100 GB (if needed)

## Security Features

All buckets include:
- ✅ Encryption at rest (AES256 or KMS)
- ✅ Versioning enabled
- ✅ Public access blocked
- ✅ IAM-based access control
- ✅ VPC endpoint compatible
- ✅ CloudTrail logging compatible

## Troubleshooting

### Issue: "Bucket not found"

```bash
# Verify bucket was created
terraform output datasets_bucket_name

# Check AWS console
aws s3 ls
```

### Issue: "Access Denied"

```python
# Verify IAM permissions
import boto3
s3 = boto3.client('s3')
try:
    s3.head_bucket(Bucket='your-bucket-name')
    print("✅ Access granted")
except Exception as e:
    print(f"❌ Error: {e}")
```

### Issue: "gsutil not found"

```python
# Install in notebook
!pip install gsutil
```

## Next Steps

1. **Deploy the infrastructure**: `terraform apply`

2. **Get bucket names**: `terraform output`

3. **Install gsutil in notebook**: See [GSUTIL_QUICKSTART.md](GSUTIL_QUICKSTART.md)

4. **Migrate your data**: Use the migration script

5. **Start ML workflow**: See [S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md) for examples

6. **Monitor costs**: Check AWS Cost Explorer for S3 usage

## Files Changed/Added

```
✅ s3.tf                          # New: S3 bucket resources
✅ iam.tf                         # Updated: IAM permissions for S3
✅ variables.tf                   # Updated: S3 configuration variables
✅ outputs.tf                     # Updated: S3 bucket outputs
✅ S3_USAGE_GUIDE.md             # New: Comprehensive S3 usage guide
✅ GSUTIL_QUICKSTART.md          # New: Quick start for gsutil
✅ gcs_to_s3_migration.py        # New: Migration automation script
✅ terraform.tfvars.s3-example   # New: Example configuration
✅ S3_SETUP_SUMMARY.md           # New: This file
✅ README.md                      # Updated: Added S3 features
```

## Questions?

- **S3 usage**: See [S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md)
- **gsutil setup**: See [GSUTIL_QUICKSTART.md](GSUTIL_QUICKSTART.md)
- **Configuration**: See [terraform.tfvars.s3-example](terraform.tfvars.s3-example)
- **General setup**: See [README.md](README.md)

---

**Ready to deploy!** 🚀

Simply run:
```bash
terraform apply
```

Then start using S3 from your notebooks!

```

Perfect! Let me verify all the changes are correctly formatted:

Excellent! I've successfully added S3 bucket management to your Terraform infrastructure and created comprehensive guides for using gsutil in your notebooks. Here's what I've implemented:

## 🎉 What's Been Added

### **1. S3 Bucket Infrastructure** (`s3.tf`)
- **Datasets Bucket**: For ML training/testing data
- **Models Bucket**: For trained model artifacts
- **Features**:
  - ✅ Versioning enabled (protects against accidental deletion)
  - ✅ Encryption at rest (AES256 or KMS)
  - ✅ Public access blocked
  - ✅ Lifecycle policies (archive old data to Glacier, auto-cleanup)
  - ✅ Automatic IAM permissions for your notebook

### **2. Automatic IAM Configuration** (Updated `iam.tf`)
Your SageMaker notebook now automatically has permissions to access the created S3 buckets for read/write operations.

### **3. Configuration Variables** (Updated `variables.tf`)
Added 12+ new variables for customizing S3 buckets:
- Bucket names, versioning, encryption, lifecycle policies, etc.

### **4. Terraform Outputs** (Updated `outputs.tf`)
Get bucket names and ARNs after deployment:
```bash
terraform output datasets_bucket_name
terraform output models_bucket_name
```

### **5. Comprehensive Documentation**

Created 5 new documentation files:

1. **[S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md)** - Complete guide covering:
   - Using S3 from notebooks (pandas, boto3, SageMaker SDK)
   - Migrating data from Google Cloud Storage to S3
   - Working with large datasets
   - Cost optimization and best practices

2. **[GSUTIL_QUICKSTART.md](GSUTIL_QUICKSTART.md)** - Quick start for installing and using gsutil:
   - Installing gsutil in your notebook
   - Downloading from Google Cloud Storage
   - Uploading to S3
   - Common commands and troubleshooting

3. **[gcs_to_s3_migration.py](gcs_to_s3_migration.py)** - Python automation script:
   - Automated GCS → S3 migration
   - Auto-discovers your S3 buckets
   - Handles downloads, uploads, and cleanup

4. **[terraform.tfvars.s3-example](terraform.tfvars.s3-example)** - Example configuration file

5. **[S3_SETUP_SUMMARY.md](S3_SETUP_SUMMARY.md)** - Complete overview of the setup

## 🚀 Quick Start

### **Deploy the Infrastructure**

```bash
# 1. Copy example configuration
cp terraform.tfvars.s3-example terraform.tfvars

# 2. Edit terraform.tfvars with your VPC/subnet IDs

# 3. Deploy
terraform init
terraform apply

# 4. Get your bucket names
terraform output datasets_bucket_name
terraform output models_bucket_name
```

### **Install gsutil in Your Notebook**

Open a Jupyter notebook cell and run:

```python
# Install gsutil
!pip install gsutil

# Download from Google Cloud Storage
!gsutil -m cp gs://your-gcs-bucket/dataset.csv /tmp/

# Upload to S3 (replace with your bucket name from terraform output)
!aws s3 cp /tmp/dataset.csv s3://your-project-dev-datasets/raw/

# Read from S3
import pandas as pd
df = pd.read_csv('s3://your-project-dev-datasets/raw/dataset.csv')
```

### **Or Use the Migration Script**

```python
from gcs_to_s3_migration import GCStoS3Migrator

# Auto-discovers your S3 buckets
migrator = GCStoS3Migrator()

# Migrate data (downloads, uploads, cleans up automatically)
migrator.migrate(
    gcs_uri='gs://your-gcs-bucket/path/to/data',
    s3_prefix='raw/'
)
```

## 📊 Key Benefits

1. **Automatic Setup**: Buckets are created and configured automatically with best practices
2. **Cost Optimization**: Lifecycle policies move old data to cheaper storage (save ~60%)
3. **Data Protection**: Versioning protects against accidental deletion
4. **Easy Migration**: Tools provided for moving data from Google Cloud Storage
5. **Direct Integration**: Use pandas/boto3 to read/write S3 directly

## 📁 Files Modified

```
✅ s3.tf                          # NEW - S3 bucket resources
✅ iam.tf                         # UPDATED - IAM permissions
✅ variables.tf                   # UPDATED - Configuration variables
✅ outputs.tf                     # UPDATED - Bucket outputs
✅ S3_USAGE_GUIDE.md             # NEW - Comprehensive usage guide
✅ GSUTIL_QUICKSTART.md          # NEW - gsutil quick start
✅ gcs_to_s3_migration.py        # NEW - Migration automation
✅ terraform.tfvars.s3-example   # NEW - Example configuration
✅ S3_SETUP_SUMMARY.md           # NEW - Setup overview
✅ README.md                      # UPDATED - Added S3 features
```

## 🔍 Next Steps

1. **Deploy the infrastructure**: Run `terraform apply`
2. **Open your SageMaker notebook**
3. **Install gsutil**: Run `!pip install gsutil` in a notebook cell
4. **Download your datasets from GCS and upload to S3**
5. **Start your ML workflows using S3**

## 📚 Documentation

- **[GSUTIL_QUICKSTART.md](GSUTIL_QUICKSTART.md)** - Start here for installing gsutil
- **[S3_USAGE_GUIDE.md](S3_USAGE_GUIDE.md)** - Comprehensive S3 usage examples
- **[gcs_to_s3_migration.py](gcs_to_s3_migration.py)** - Automated migration script
- **[S3_SETUP_SUMMARY.md](S3_SETUP_SUMMARY.md)** - Complete setup overview

All set! Your infrastructure now includes managed S3 buckets, and you have all the tools and documentation needed to install gsutil and migrate your datasets from Google Cloud Storage to S3. 🎉

```shellscript
terraform output datasets_bucket_name
terraform output models_bucket_name
```

```shellscript
# 1. Copy example configuration
cp terraform.tfvars.s3-example terraform.tfvars

# 2. Edit terraform.tfvars with your VPC/subnet IDs

# 3. Deploy
terraform init
terraform apply

# 4. Get your bucket names
terraform output datasets_bucket_name
terraform output models_bucket_name
```

```python
# Install gsutil
!pip install gsutil

# Download from Google Cloud Storage
!gsutil -m cp gs://your-gcs-bucket/dataset.csv /tmp/

# Upload to S3 (replace with your bucket name from terraform output)
!aws s3 cp /tmp/dataset.csv s3://your-project-dev-datasets/raw/

# Read from S3
import pandas as pd
df = pd.read_csv('s3://your-project-dev-datasets/raw/dataset.csv')
```

```python
from gcs_to_s3_migration import GCStoS3Migrator

# Auto-discovers your S3 buckets
migrator = GCStoS3Migrator()

# Migrate data (downloads, uploads, cleans up automatically)
migrator.migrate(
    gcs_uri='gs://your-gcs-bucket/path/to/data',
    s3_prefix='raw/'
)
```

```plaintext
✅ s3.tf                          # NEW - S3 bucket resources
✅ iam.tf                         # UPDATED - IAM permissions
✅ variables.tf                   # UPDATED - Configuration variables
✅ outputs.tf                     # UPDATED - Bucket outputs
✅ S3_USAGE_GUIDE.md             # NEW - Comprehensive usage guide
✅ GSUTIL_QUICKSTART.md          # NEW - gsutil quick start
✅ gcs_to_s3_migration.py        # NEW - Migration automation
✅ terraform.tfvars.s3-example   # NEW - Example configuration
✅ S3_SETUP_SUMMARY.md           # NEW - Setup overview
✅ README.md                      # UPDATED - Added S3 features
```

---

**User**

since my plan is to create multiple notebooks in the account is it possible to refactor the code so as the iam role, security group, s3 buckets, vpc endpoints to be in subfolders ? 



Do not change the current code, just add a new folder ML_NEW_STRUCTURE and put everything inside there like it was a new repo.

---

**Cursor**

```plaintext
ML_NEW_STRUCTURE/
├── README.md                    # Main documentation
├── shared-infra/               # Shared resources (IAM, S3, VPC endpoints)
│   ├── iam/                   # IAM roles and policies
│   ├── s3/                    # S3 buckets
│   ├── vpc-endpoints/         # VPC endpoints
│   └── security-groups/       # Security groups
├── notebooks/                  # Individual notebook instances
│   ├── notebook-1/
│   └── notebook-2/
└── modules/                    # Reusable Terraform modules
    └── sagemaker-notebook/    # Notebook instance module
```

I'll create a new refactored structure in `ML_NEW_STRUCTURE` that separates shared resources (IAM roles, S3 buckets, VPC endpoints, security groups) from individual notebook instances. This is perfect for managing multiple notebooks efficiently!

Now let me create the refactored structure. I'll start with the main README:

```markdown
# Multi-Notebook SageMaker Infrastructure

This is a refactored structure designed for managing **multiple SageMaker notebook instances** that share common resources like IAM roles, S3 buckets, VPC endpoints, and security groups.

## Architecture Overview

```
ML_NEW_STRUCTURE/
├── shared-infra/              # Shared resources (deploy once)
│   ├── iam/                  # IAM roles for notebooks
│   ├── s3/                   # S3 buckets (datasets, models)
│   ├── vpc-endpoints/        # VPC endpoints for private subnets
│   └── security-groups/      # Security groups
│
├── modules/                   # Reusable Terraform modules
│   └── sagemaker-notebook/   # Notebook instance module
│
└── notebooks/                 # Individual notebook instances
    ├── notebook-dev/         # Development notebook
    └── notebook-prod/        # Production notebook
```

## Key Benefits

### 1. **Resource Sharing**
- ✅ One IAM role for all notebooks
- ✅ Shared S3 buckets for datasets and models
- ✅ Single set of VPC endpoints
- ✅ Reusable security groups

### 2. **Cost Optimization**
- No duplicate VPC endpoints ($0.01/hour each × saved endpoints)
- Shared S3 buckets (no data duplication)
- Single NAT gateway if needed

### 3. **Easier Management**
- Update permissions in one place
- Consistent security configuration
- Centralized data storage
- Simple notebook provisioning

### 4. **Scalability**
- Add new notebooks in minutes
- Each notebook can have different instance types
- Independent lifecycle management

## Quick Start

### Step 1: Deploy Shared Infrastructure (Once)

Deploy these in order:

```bash
# 1. S3 Buckets
cd shared-infra/s3
terraform init
terraform apply

# 2. IAM Roles
cd ../iam
terraform init
terraform apply

# 3. Security Groups
cd ../security-groups
terraform init
terraform apply

# 4. VPC Endpoints (if using private subnets)
cd ../vpc-endpoints
terraform init
terraform apply
```

### Step 2: Deploy Notebook Instances

Deploy as many notebooks as you need:

```bash
# Development notebook
cd notebooks/notebook-dev
terraform init
terraform apply

# Production notebook
cd notebooks/notebook-prod
terraform init
terraform apply
```

### Step 3: Get Outputs

```bash
# Get shared resource information
cd shared-infra/s3
terraform output

cd shared-infra/iam
terraform output

# Get notebook URLs
cd notebooks/notebook-dev
terraform output notebook_url
```

## Deployment Order

**Important**: Deploy in this order to avoid dependency issues:

1. ✅ **S3 buckets** (no dependencies)
2. ✅ **IAM roles** (depends on S3 bucket ARNs)
3. ✅ **Security groups** (minimal dependencies)
4. ✅ **VPC endpoints** (depends on security groups)
5. ✅ **Notebooks** (depends on IAM, security groups)

## Configuration

### Shared Infrastructure

Each shared-infra module has a `terraform.tfvars.example` file. Copy and customize:

```bash
cd shared-infra/s3
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings
```

### Notebook Instances

Each notebook has its own configuration:

```bash
cd notebooks/notebook-dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
```

## Adding a New Notebook

To add a new notebook (e.g., for a new team member or project):

```bash
# 1. Copy an existing notebook configuration
cp -r notebooks/notebook-dev notebooks/notebook-data-science

# 2. Update the configuration
cd notebooks/notebook-data-science
nano terraform.tfvars

# 3. Deploy
terraform init
terraform apply
```

That's it! The new notebook automatically uses the shared IAM role, S3 buckets, and security groups.

## Shared Resources Details

### IAM Role (`shared-infra/iam/`)
- Created once, used by all notebooks
- Permissions for:
  - SageMaker operations
  - S3 access (all shared buckets)
  - ECR access
  - CloudWatch Logs
  - VPC operations
  - Git/CodeCommit access
  - Secrets Manager

### S3 Buckets (`shared-infra/s3/`)
- **Datasets bucket**: Shared datasets across all notebooks
- **Models bucket**: Centralized model storage
- Features:
  - Versioning enabled
  - Encryption at rest
  - Lifecycle policies
  - Public access blocked

### VPC Endpoints (`shared-infra/vpc-endpoints/`)
- S3 gateway endpoint (free)
- SageMaker API interface endpoint
- SageMaker Runtime interface endpoint
- EC2 interface endpoint
- Shared across all notebooks in the VPC

### Security Groups (`shared-infra/security-groups/`)
- Notebook security group
- VPC endpoints security group
- Configured for private subnet access

## Cost Comparison

### Old Structure (Separate Resources per Notebook)
- 3 notebooks × $7/month (VPC endpoints) = **$21/month**
- 3 notebooks × $2.30/month (S3 buckets) = **$6.90/month**
- 3 notebooks × ML instance cost
- **Total overhead: ~$28/month**

### New Structure (Shared Resources)
- 1 set of VPC endpoints = **$7/month**
- 1 set of S3 buckets = **$2.30/month**
- Multiple notebooks × ML instance cost
- **Total overhead: ~$9.30/month**

**Savings: ~67% on infrastructure overhead!**

## Example Use Cases

### Use Case 1: Team Collaboration
```
shared-infra/           # Shared by entire team
notebooks/
  ├── alice-notebook/   # Data scientist Alice
  ├── bob-notebook/     # ML engineer Bob
  └── charlie-notebook/ # Data analyst Charlie
```

All team members share:
- Same datasets in S3
- Same IAM permissions
- Same model repository
- Same VPC configuration

### Use Case 2: Environment Separation
```
shared-infra/           # Shared resources
notebooks/
  ├── dev-notebook/     # Development (ml.t3.medium)
  ├── staging-notebook/ # Staging (ml.m5.xlarge)
  └── prod-notebook/    # Production (ml.m5.2xlarge)
```

### Use Case 3: Project-Based
```
shared-infra/           # Shared resources
notebooks/
  ├── nlp-project/      # NLP team
  ├── cv-project/       # Computer Vision team
  └── timeseries-proj/  # Time series team
```

## Remote State (Recommended)

For team collaboration, use remote state:

### 1. Create S3 Backend Bucket

```bash
aws s3 mb s3://my-terraform-state-bucket
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled
```

### 2. Configure Backend in Each Module

Add to each module's `versions.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "ml-infra/shared-infra/s3/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

Use different keys for each module:
- `ml-infra/shared-infra/s3/terraform.tfstate`
- `ml-infra/shared-infra/iam/terraform.tfstate`
- `ml-infra/notebooks/notebook-dev/terraform.tfstate`
- etc.

## Data Sharing Between Notebooks

All notebooks can access the same data:

```python
# In any notebook
import pandas as pd

# Read shared dataset
df = pd.read_csv('s3://your-project-datasets/raw/dataset.csv')

# Save results for others
df_processed.to_parquet('s3://your-project-datasets/processed/my_output.parquet')

# Share models
import joblib
joblib.dump(model, 's3://your-project-models/experiments/alice/model-v1.pkl')
```

## Security Considerations

### IAM Role
- Single role = easier to audit
- Update permissions in one place
- Use IAM policies to restrict sensitive data if needed

### S3 Buckets
- Use prefix-based permissions for isolation:
  ```python
  # Alice can only write to her prefix
  s3://datasets/users/alice/*
  
  # Everyone can read from shared
  s3://datasets/shared/*
  ```

### Network Isolation
- All notebooks in same VPC/subnet share security group
- For more isolation, create separate security groups per notebook
- Or use separate subnets

## Monitoring

View all notebooks:

```bash
# List all notebooks
aws sagemaker list-notebook-instances

# Get status of specific notebook
aws sagemaker describe-notebook-instance \
  --notebook-instance-name my-notebook
```

## Cleanup

To destroy everything:

```bash
# 1. Destroy all notebooks first
cd notebooks/notebook-dev && terraform destroy
cd ../notebook-prod && terraform destroy

# 2. Destroy shared infrastructure (in reverse order)
cd ../../shared-infra/vpc-endpoints && terraform destroy
cd ../security-groups && terraform destroy
cd ../iam && terraform destroy
cd ../s3 && terraform destroy
```

## Migration from Old Structure

If you're migrating from the single-module structure:

1. **Deploy shared infrastructure** using existing settings
2. **Import existing resources** (optional):
   ```bash
   terraform import aws_s3_bucket.datasets your-existing-bucket
   ```
3. **Create new notebooks** using the module
4. **Destroy old monolithic deployment** after verification

## Documentation

- **[shared-infra/s3/README.md](shared-infra/s3/README.md)** - S3 buckets setup
- **[shared-infra/iam/README.md](shared-infra/iam/README.md)** - IAM roles and policies
- **[shared-infra/vpc-endpoints/README.md](shared-infra/vpc-endpoints/README.md)** - VPC endpoints
- **[shared-infra/security-groups/README.md](shared-infra/security-groups/README.md)** - Security groups
- **[modules/sagemaker-notebook/README.md](modules/sagemaker-notebook/README.md)** - Notebook module
- **[notebooks/README.md](notebooks/README.md)** - Notebook instances

## Support

For issues or questions:
1. Check module-specific README files
2. Review AWS SageMaker documentation
3. Check Terraform AWS provider documentation

## Best Practices

1. ✅ **Deploy shared infrastructure first**
2. ✅ **Use remote state for team collaboration**
3. ✅ **Tag all resources consistently**
4. ✅ **Document notebook purposes**
5. ✅ **Use lifecycle policies on S3 to manage costs**
6. ✅ **Stop notebooks when not in use**
7. ✅ **Regular backups of important data to S3**
8. ✅ **Monitor costs with AWS Cost Explorer**

## Version Requirements

- Terraform >= 1.0
- AWS Provider >= 5.0
- AWS CLI >= 2.0 (for manual operations)

---

**Ready to deploy your multi-notebook infrastructure!** 🚀

Start with `shared-infra/` modules, then deploy as many notebooks as you need.

```

Now let me create the shared infrastructure modules, starting with S3:

```plaintext
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

```

```plaintext
variable "datasets_bucket_name" {
  description = "Name for the datasets S3 bucket"
  type        = string
}

variable "models_bucket_name" {
  description = "Name for the models S3 bucket"
  type        = string
}

variable "enable_versioning" {
  description = "Whether to enable versioning for S3 buckets"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for bucket encryption (if null, uses AES256)"
  type        = string
  default     = null
}

variable "enable_lifecycle_policies" {
  description = "Whether to enable lifecycle policies for cost optimization"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

```

```plaintext
output "datasets_bucket_name" {
  description = "Name of the datasets S3 bucket"
  value       = aws_s3_bucket.datasets.id
}

output "datasets_bucket_arn" {
  description = "ARN of the datasets S3 bucket"
  value       = aws_s3_bucket.datasets.arn
}

output "models_bucket_name" {
  description = "Name of the models S3 bucket"
  value       = aws_s3_bucket.models.id
}

output "models_bucket_arn" {
  description = "ARN of the models S3 bucket"
  value       = aws_s3_bucket.models.arn
}

output "all_bucket_arns" {
  description = "List of all S3 bucket ARNs"
  value = [
    aws_s3_bucket.datasets.arn,
    aws_s3_bucket.models.arn
  ]
}

```

```plaintext
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

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

```

```plaintext
# AWS Region
aws_region = "us-east-1"

# S3 Bucket Names (must be globally unique)
datasets_bucket_name = "my-company-ml-datasets"
models_bucket_name   = "my-company-ml-models"

# Versioning (recommended for data protection)
enable_versioning = true

# Lifecycle Policies (recommended for cost optimization)
enable_lifecycle_policies = true

# Optional: KMS Key for encryption
# kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

# Common Tags
common_tags = {
  Project     = "ML Infrastructure"
  Environment = "Shared"
  ManagedBy   = "Terraform"
  Team        = "Data Science"
}

```

Now let me create the IAM module:

```plaintext
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

```

```plaintext
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "iam_role_name" {
  description = "Name for the shared IAM role"
  type        = string
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs to grant access to"
  type        = list(string)
}

variable "enable_git_access" {
  description = "Whether to enable Git/CodeCommit access"
  type        = bool
  default     = true
}

variable "enable_secrets_manager_access" {
  description = "Whether to enable Secrets Manager access"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for encryption (optional)"
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

```

```plaintext
output "iam_role_arn" {
  description = "ARN of the shared IAM role"
  value       = aws_iam_role.sagemaker_shared.arn
}

output "iam_role_name" {
  description = "Name of the shared IAM role"
  value       = aws_iam_role.sagemaker_shared.name
}

output "iam_role_id" {
  description = "ID of the shared IAM role"
  value       = aws_iam_role.sagemaker_shared.id
}

```

```plaintext
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

```

```plaintext
# AWS Region
aws_region = "us-east-1"

# IAM Role Name
iam_role_name = "sagemaker-notebooks-shared-role"

# S3 Bucket ARNs (from shared-infra/s3 outputs)
# Get these from: cd ../s3 && terraform output all_bucket_arns
s3_bucket_arns = [
  "arn:aws:s3:::my-company-ml-datasets",
  "arn:aws:s3:::my-company-ml-models"
]

# Git Access
enable_git_access = true

# Secrets Manager Access
enable_secrets_manager_access = true

# Optional: KMS Key
# kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

# Common Tags
common_tags = {
  Project     = "ML Infrastructure"
  Environment = "Shared"
  ManagedBy   = "Terraform"
  Team        = "Data Science"
}

```

Now let me create the Security Groups module files in a batch to speed up:

```plaintext
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

```

```plaintext
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

variable "notebook_sg_name" {
  description = "Name for the notebook security group"
  type        = string
  default     = "sagemaker-notebooks-sg"
}

variable "vpc_endpoint_sg_name" {
  description = "Name for the VPC endpoint security group"
  type        = string
  default     = "sagemaker-vpc-endpoints-sg"
}

variable "create_vpc_endpoint_sg" {
  description = "Whether to create security group for VPC endpoints"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

```

```plaintext
output "notebook_security_group_id" {
  description = "ID of the notebook security group"
  value       = aws_security_group.sagemaker_notebook.id
}

output "notebook_security_group_arn" {
  description = "ARN of the notebook security group"
  value       = aws_security_group.sagemaker_notebook.arn
}

output "vpc_endpoint_security_group_id" {
  description = "ID of the VPC endpoint security group"
  value       = var.create_vpc_endpoint_sg ? aws_security_group.vpc_endpoints[0].id : null
}

output "vpc_endpoint_security_group_arn" {
  description = "ARN of the VPC endpoint security group"
  value       = var.create_vpc_endpoint_sg ? aws_security_group.vpc_endpoints[0].arn : null
}

```

```plaintext
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

```

```plaintext
# AWS Region
aws_region = "us-east-1"

# VPC Configuration
vpc_id         = "vpc-0123456789abcdef0"
vpc_cidr_block = "10.0.0.0/16"

# Security Group Names
notebook_sg_name      = "sagemaker-notebooks-sg"
vpc_endpoint_sg_name  = "sagemaker-vpc-endpoints-sg"

# Create VPC Endpoint Security Group
create_vpc_endpoint_sg = true

# Common Tags
common_tags = {
  Project     = "ML Infrastructure"
  Environment = "Shared"
  ManagedBy   = "Terraform"
  Team        = "Data Science"
}

```

Now let me create the VPC endpoints module. I'll batch these files together:

```plaintext
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

```

```plaintext
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID where VPC endpoints will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for interface endpoints (use multiple for HA)"
  type        = list(string)
}

variable "route_table_ids" {
  description = "List of route table IDs for S3 gateway endpoint"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for interface endpoints"
  type        = list(string)
}

variable "create_s3_endpoint" {
  description = "Whether to create S3 gateway endpoint"
  type        = bool
  default     = true
}

variable "create_sagemaker_api_endpoint" {
  description = "Whether to create SageMaker API endpoint"
  type        = bool
  default     = true
}

variable "create_sagemaker_runtime_endpoint" {
  description = "Whether to create SageMaker Runtime endpoint"
  type        = bool
  default     = true
}

variable "create_ec2_endpoint" {
  description = "Whether to create EC2 endpoint"
  type        = bool
  default     = true
}

variable "create_logs_endpoint" {
  description = "Whether to create CloudWatch Logs endpoint"
  type        = bool
  default     = false
}

variable "create_ecr_endpoints" {
  description = "Whether to create ECR endpoints (API and DKR)"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

```

```plaintext
output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = var.create_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}

output "sagemaker_api_endpoint_id" {
  description = "ID of the SageMaker API VPC endpoint"
  value       = var.create_sagemaker_api_endpoint ? aws_vpc_endpoint.sagemaker_api[0].id : null
}

output "sagemaker_runtime_endpoint_id" {
  description = "ID of the SageMaker Runtime VPC endpoint"
  value       = var.create_sagemaker_runtime_endpoint ? aws_vpc_endpoint.sagemaker_runtime[0].id : null
}

output "ec2_endpoint_id" {
  description = "ID of the EC2 VPC endpoint"
  value       = var.create_ec2_endpoint ? aws_vpc_endpoint.ec2[0].id : null
}

output "logs_endpoint_id" {
  description = "ID of the CloudWatch Logs VPC endpoint"
  value       = var.create_logs_endpoint ? aws_vpc_endpoint.logs[0].id : null
}

output "ecr_api_endpoint_id" {
  description = "ID of the ECR API VPC endpoint"
  value       = var.create_ecr_endpoints ? aws_vpc_endpoint.ecr_api[0].id : null
}

output "ecr_dkr_endpoint_id" {
  description = "ID of the ECR DKR VPC endpoint"
  value       = var.create_ecr_endpoints ? aws_vpc_endpoint.ecr_dkr[0].id : null
}

```

```plaintext
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

```

```plaintext
# AWS Region
aws_region = "us-east-1"

# VPC Configuration
vpc_id = "vpc-0123456789abcdef0"

# Subnet IDs for interface endpoints (use multiple for HA)
subnet_ids = [
  "subnet-0123456789abcdef0",
  "subnet-0123456789abcdef1"
]

# Route table IDs for S3 gateway endpoint
route_table_ids = [
  "rtb-0123456789abcdef0"
]

# Security group IDs (from shared-infra/security-groups)
# Get from: cd ../security-groups && terraform output vpc_endpoint_security_group_id
security_group_ids = [
  "sg-0123456789abcdef0"
]

# Which endpoints to create
create_s3_endpoint                = true   # Free
create_sagemaker_api_endpoint     = true   # $0.01/hour
create_sagemaker_runtime_endpoint = true   # $0.01/hour
create_ec2_endpoint               = true   # $0.01/hour
create_logs_endpoint              = false  # $0.01/hour (optional)
create_ecr_endpoints              = false  # $0.01/hour each (optional)

# Common Tags
common_tags = {
  Project     = "ML Infrastructure"
  Environment = "Shared"
  ManagedBy   = "Terraform"
  Team        = "Data Science"
}

```

Now let me create the reusable SageMaker notebook module:

```plaintext
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

```

```plaintext
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "notebook_name" {
  description = "Name of the notebook instance (if null, auto-generated)"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type for the notebook"
  type        = string
  default     = "ml.t3.medium"
}

variable "volume_size" {
  description = "Size of the EBS volume in GB (min: 5, max: 16384)"
  type        = number
  default     = 5

  validation {
    condition     = var.volume_size >= 5 && var.volume_size <= 16384
    error_message = "Volume size must be between 5 GB and 16384 GB."
  }
}

variable "platform_identifier" {
  description = "Platform identifier (notebook-al2-v2, notebook-al1-v1, etc.)"
  type        = string
  default     = "notebook-al2-v2"
}

variable "root_access" {
  description = "Whether root access is enabled (Enabled or Disabled)"
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.root_access)
    error_message = "Root access must be either 'Enabled' or 'Disabled'."
  }
}

variable "direct_internet_access" {
  description = "Whether direct internet access is enabled (Enabled or Disabled)"
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.direct_internet_access)
    error_message = "Direct internet access must be either 'Enabled' or 'Disabled'."
  }
}

# Network Configuration
variable "subnet_id" {
  description = "Subnet ID for the notebook instance"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

# IAM Configuration
variable "iam_role_arn" {
  description = "ARN of the IAM role for the notebook"
  type        = string
}

# Encryption
variable "kms_key_id" {
  description = "KMS key ID for encrypting the EBS volume"
  type        = string
  default     = null
}

# Lifecycle Configuration
variable "create_lifecycle_config" {
  description = "Whether to create a lifecycle configuration"
  type        = bool
  default     = false
}

variable "lifecycle_config_name" {
  description = "Name of existing lifecycle configuration to attach"
  type        = string
  default     = null
}

variable "lifecycle_config_on_create" {
  description = "Base64-encoded shell script to run on notebook creation"
  type        = string
  default     = null
}

variable "lifecycle_config_on_start" {
  description = "Base64-encoded shell script to run on notebook start"
  type        = string
  default     = null
}

# Code Repository
variable "default_code_repository" {
  description = "Default Git repository for the notebook"
  type        = string
  default     = null
}

variable "additional_code_repositories" {
  description = "Additional Git repositories (max 3)"
  type        = list(string)
  default     = []
}

# Monitoring
variable "enable_cloudwatch_logs" {
  description = "Whether to enable CloudWatch logs"
  type        = bool
  default     = true
}

variable "cloudwatch_logs_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

# Instance Metadata
variable "instance_metadata_service_version" {
  description = "Minimum instance metadata service version (1 or 2)"
  type        = string
  default     = "2"
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

```

```plaintext
output "notebook_instance_name" {
  description = "Name of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.this.name
}

output "notebook_instance_arn" {
  description = "ARN of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.this.arn
}

output "notebook_instance_url" {
  description = "URL of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.this.url
}

output "notebook_instance_id" {
  description = "ID of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.this.id
}

output "network_interface_id" {
  description = "Network interface ID of the notebook instance"
  value       = aws_sagemaker_notebook_instance.this.network_interface_id
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.notebook[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.notebook[0].arn : null
}

```

```plaintext
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

```

Now let me create the example notebook configurations. First, notebook-dev:

```plaintext
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
  project_name = var.project_name
  environment  = var.environment
  notebook_name = var.notebook_name

  # Instance Configuration
  instance_type           = var.instance_type
  volume_size             = var.volume_size
  root_access             = var.root_access
  direct_internet_access  = var.direct_internet_access
  platform_identifier     = var.platform_identifier

  # Network Configuration
  subnet_id          = var.subnet_id
  security_group_ids = var.security_group_ids

  # IAM Configuration (from shared-infra/iam)
  iam_role_arn = var.iam_role_arn

  # Encryption
  kms_key_id = var.kms_key_id

  # Lifecycle Configuration
  create_lifecycle_config     = var.create_lifecycle_config
  lifecycle_config_on_create  = var.lifecycle_config_on_create
  lifecycle_config_on_start   = var.lifecycle_config_on_start

  # Git Repository
  default_code_repository     = var.default_code_repository
  additional_code_repositories = var.additional_code_repositories

  # Monitoring
  enable_cloudwatch_logs         = var.enable_cloudwatch_logs
  cloudwatch_logs_retention_days = var.cloudwatch_logs_retention_days

  # Tags
  common_tags = var.common_tags
}

```

```plaintext
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "notebook_name" {
  description = "Notebook instance name"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "ml.t3.medium"
}

variable "volume_size" {
  description = "EBS volume size in GB"
  type        = number
  default     = 10
}

variable "root_access" {
  description = "Root access (Enabled or Disabled)"
  type        = string
  default     = "Enabled"
}

variable "direct_internet_access" {
  description = "Direct internet access (Enabled or Disabled)"
  type        = string
  default     = "Disabled"
}

variable "platform_identifier" {
  description = "Platform identifier"
  type        = string
  default     = "notebook-al2-v2"
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
}

variable "iam_role_arn" {
  description = "IAM role ARN (from shared-infra/iam)"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
}

variable "create_lifecycle_config" {
  description = "Create lifecycle configuration"
  type        = bool
  default     = false
}

variable "lifecycle_config_on_create" {
  description = "Lifecycle config on create"
  type        = string
  default     = null
}

variable "lifecycle_config_on_start" {
  description = "Lifecycle config on start"
  type        = string
  default     = null
}

variable "default_code_repository" {
  description = "Default code repository"
  type        = string
  default     = null
}

variable "additional_code_repositories" {
  description = "Additional code repositories"
  type        = list(string)
  default     = []
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs"
  type        = bool
  default     = true
}

variable "cloudwatch_logs_retention_days" {
  description = "CloudWatch logs retention days"
  type        = number
  default     = 30
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

```

```plaintext
output "notebook_name" {
  description = "Name of the notebook instance"
  value       = module.notebook.notebook_instance_name
}

output "notebook_arn" {
  description = "ARN of the notebook instance"
  value       = module.notebook.notebook_instance_arn
}

output "notebook_url" {
  description = "URL to access the notebook"
  value       = module.notebook.notebook_instance_url
}

output "notebook_id" {
  description = "ID of the notebook instance"
  value       = module.notebook.notebook_instance_id
}

```

```plaintext
# AWS Configuration
aws_region = "us-east-1"

# Project Configuration
project_name = "ml-project"
environment  = "dev"

# Notebook Configuration
notebook_name = null  # Auto-generated: ml-project-dev-notebook
instance_type = "ml.t3.medium"
volume_size   = 10
root_access   = "Enabled"  # Allow pip installs for development

# Network Configuration
direct_internet_access = "Disabled"  # Use VPC endpoints
subnet_id              = "subnet-0123456789abcdef0"  # Private subnet

# Security Group IDs (from shared-infra/security-groups)
# Get from: cd ../../shared-infra/security-groups && terraform output notebook_security_group_id
security_group_ids = [
  "sg-0123456789abcdef0"
]

# IAM Role ARN (from shared-infra/iam)
# Get from: cd ../../shared-infra/iam && terraform output iam_role_arn
iam_role_arn = "arn:aws:iam::123456789012:role/sagemaker-notebooks-shared-role"

# Optional: Lifecycle Configuration
# create_lifecycle_config = true
# lifecycle_config_on_start = base64encode(<<-EOF
#   #!/bin/bash
#   set -e
#   echo "Notebook started at $(date)"
# EOF
# )

# Optional: Git Repository
# default_code_repository = "https://github.com/yourorg/ml-notebooks"

# Monitoring
enable_cloudwatch_logs         = true
cloudwatch_logs_retention_days = 30

# Tags
common_tags = {
  Project     = "ML Project"
  Environment = "Development"
  Owner       = "Data Science Team"
  ManagedBy   = "Terraform"
}

```

Now let me create the production notebook configuration:

```plaintext
# Production Notebook Instance

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

```

```plaintext
# AWS Configuration
aws_region = "us-east-1"

# Project Configuration
project_name = "ml-project"
environment  = "prod"

# Notebook Configuration
notebook_name = null  # Auto-generated: ml-project-prod-notebook
instance_type = "ml.m5.xlarge"  # Larger instance for production
volume_size   = 50              # More storage for production data
root_access   = "Disabled"      # Restricted for production security

# Network Configuration
direct_internet_access = "Disabled"  # Use VPC endpoints
subnet_id              = "subnet-0123456789abcdef0"  # Private subnet

# Security Group IDs (from shared-infra/security-groups)
# Get from: cd ../../shared-infra/security-groups && terraform output notebook_security_group_id
security_group_ids = [
  "sg-0123456789abcdef0"
]

# IAM Role ARN (from shared-infra/iam)
# Get from: cd ../../shared-infra/iam && terraform output iam_role_arn
iam_role_arn = "arn:aws:iam::123456789012:role/sagemaker-notebooks-shared-role"

# Optional: KMS Encryption for production
# kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

# Optional: Lifecycle Configuration
# create_lifecycle_config = true
# lifecycle_config_on_start = base64encode(<<-EOF
#   #!/bin/bash
#   set -e
#   echo "Production notebook started at $(date)"
#   # Add production-specific startup scripts
# EOF
# )

# Optional: Git Repository
# default_code_repository = "https://github.com/yourorg/ml-notebooks-prod"

# Monitoring (longer retention for production)
enable_cloudwatch_logs         = true
cloudwatch_logs_retention_days = 90

# Tags
common_tags = {
  Project     = "ML Project"
  Environment = "Production"
  Owner       = "Data Science Team"
  ManagedBy   = "Terraform"
  Compliance  = "Required"
}

```

Now let me create a comprehensive deployment guide:

```markdown
# Multi-Notebook Infrastructure Deployment Guide

This guide walks you through deploying the multi-notebook SageMaker infrastructure step-by-step.

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. VPC with private subnets already created
4. Route table IDs for your private subnets

## Architecture Overview

The infrastructure is split into:

1. **Shared Infrastructure** (deploy once, used by all notebooks):
   - S3 buckets (datasets, models)
   - IAM role (shared by all notebooks)
   - Security groups
   - VPC endpoints

2. **Notebook Instances** (deploy multiple):
   - Individual SageMaker notebook instances
   - Each can have different configurations
   - All use shared infrastructure

## Deployment Steps

### Step 1: Deploy S3 Buckets

```bash
cd shared-infra/s3

# Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# Update these values:
# - datasets_bucket_name (must be globally unique)
# - models_bucket_name (must be globally unique)
# - common_tags

# Deploy
terraform init
terraform plan
terraform apply

# Save the outputs
terraform output datasets_bucket_arn
terraform output models_bucket_arn
```

**Expected outputs:**
- `datasets_bucket_name`: Your datasets bucket name
- `datasets_bucket_arn`: ARN to use in IAM configuration
- `models_bucket_name`: Your models bucket name
- `models_bucket_arn`: ARN to use in IAM configuration

### Step 2: Deploy IAM Role

```bash
cd ../iam

# Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# Update these values:
# - iam_role_name
# - s3_bucket_arns (use ARNs from Step 1)
# - common_tags

# Deploy
terraform init
terraform plan
terraform apply

# Save the output
terraform output iam_role_arn
```

**Expected outputs:**
- `iam_role_arn`: ARN to use in notebook configurations
- `iam_role_name`: Name of the shared IAM role

### Step 3: Deploy Security Groups

```bash
cd ../security-groups

# Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# Update these values:
# - vpc_id
# - vpc_cidr_block
# - common_tags

# Deploy
terraform init
terraform plan
terraform apply

# Save the outputs
terraform output notebook_security_group_id
terraform output vpc_endpoint_security_group_id
```

**Expected outputs:**
- `notebook_security_group_id`: For notebook instances
- `vpc_endpoint_security_group_id`: For VPC endpoints

### Step 4: Deploy VPC Endpoints

```bash
cd ../vpc-endpoints

# Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# Update these values:
# - vpc_id
# - subnet_ids (multiple subnets for HA)
# - route_table_ids (for S3 gateway endpoint)
# - security_group_ids (from Step 3)
# - common_tags

# Deploy
terraform init
terraform plan
terraform apply
```

**Expected outputs:**
- Various VPC endpoint IDs

**Note:** This step costs ~$0.03/hour (~$22/month) for interface endpoints.

### Step 5: Deploy Development Notebook

```bash
cd ../../notebooks/notebook-dev

# Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# Update these values:
# - subnet_id (your private subnet)
# - security_group_ids (from Step 3)
# - iam_role_arn (from Step 2)
# - instance_type (e.g., ml.t3.medium)
# - common_tags

# Deploy
terraform init
terraform plan
terraform apply

# Get notebook URL
terraform output notebook_url
```

**Expected outputs:**
- `notebook_name`: Name of your notebook
- `notebook_url`: URL to access the notebook

### Step 6: Deploy Additional Notebooks (Optional)

For production or additional notebooks:

```bash
cd ../notebook-prod

# Same process as Step 5
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
terraform init
terraform apply
```

Or create new notebook directories:

```bash
# Copy an existing notebook configuration
cp -r notebook-dev notebook-datascience

# Update configuration
cd notebook-datascience
nano terraform.tfvars
terraform init
terraform apply
```

## Verification

### 1. Verify S3 Buckets

```bash
aws s3 ls
# Should see your datasets and models buckets

aws s3 ls s3://your-datasets-bucket/
# Should work without errors
```

### 2. Verify IAM Role

```bash
aws iam get-role --role-name sagemaker-notebooks-shared-role
# Should return role details
```

### 3. Verify Security Groups

```bash
aws ec2 describe-security-groups --group-ids sg-xxxxx
# Should show your security group
```

### 4. Verify VPC Endpoints

```bash
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=vpc-xxxxx"
# Should list your VPC endpoints
```

### 5. Verify Notebooks

```bash
aws sagemaker list-notebook-instances
# Should list your notebooks

aws sagemaker describe-notebook-instance --notebook-instance-name your-notebook-name
# Should show "InService" status
```

## Accessing Your Notebooks

### Option 1: AWS Console

1. Open AWS Console
2. Navigate to SageMaker
3. Click "Notebook instances"
4. Find your notebook
5. Click "Open JupyterLab" or "Open Jupyter"

### Option 2: Presigned URL (CLI)

```bash
aws sagemaker create-presigned-notebook-instance-url \
  --notebook-instance-name your-notebook-name
```

## Testing S3 Access from Notebook

Once you're in a notebook, test S3 access:

```python
import boto3
import pandas as pd

# List buckets
s3 = boto3.client('s3')
response = s3.list_buckets()
for bucket in response['Buckets']:
    print(f"  {bucket['Name']}")

# Test write
df = pd.DataFrame({'test': [1, 2, 3]})
df.to_csv('s3://your-datasets-bucket/test/test.csv', index=False)

# Test read
df_read = pd.read_csv('s3://your-datasets-bucket/test/test.csv')
print(df_read)
```

## Common Issues and Solutions

### Issue 1: Bucket name already exists

**Error:** `BucketAlreadyExists`

**Solution:** S3 bucket names must be globally unique. Choose a different name in `shared-infra/s3/terraform.tfvars`:

```hcl
datasets_bucket_name = "my-company-ml-datasets-12345"
models_bucket_name   = "my-company-ml-models-12345"
```

### Issue 2: Notebook stuck in "Pending"

**Error:** Notebook won't start

**Possible causes:**
1. VPC endpoints not created
2. Security group blocks VPC endpoint access
3. IAM role doesn't have VPC permissions

**Solution:**
```bash
# Check VPC endpoints exist
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=vpc-xxxxx"

# Check CloudWatch logs
aws logs tail /aws/sagemaker/NotebookInstances/your-notebook-name --follow
```

### Issue 3: Can't access S3 from notebook

**Error:** `AccessDenied` when accessing S3

**Solutions:**
1. Verify IAM role has S3 bucket ARNs:
   ```bash
   cd shared-infra/iam
   terraform output iam_role_arn
   # Check the role has correct S3 permissions
   ```

2. Verify S3 VPC endpoint exists:
   ```bash
   aws ec2 describe-vpc-endpoints --filters "Name=service-name,Values=com.amazonaws.us-east-1.s3"
   ```

3. Verify route table has S3 endpoint:
   ```bash
   aws ec2 describe-route-tables --route-table-ids rtb-xxxxx
   ```

### Issue 4: Terraform state lock

**Error:** `Error locking state`

**Solution:** If using remote state with DynamoDB locking:
```bash
# Force unlock (only if you're sure no one else is using it)
terraform force-unlock <lock-id>
```

## Cost Breakdown

### One-Time Costs
- None (infrastructure only)

### Monthly Costs (Approximate)

**Shared Infrastructure:**
- S3 storage: $0.023/GB/month
  - 100 GB datasets: ~$2.30/month
  - 10 GB models: ~$0.23/month
- VPC Endpoints (interface): $0.01/hour each
  - 3 endpoints × $7/month = ~$21/month
- IAM roles: Free
- Security groups: Free

**Per Notebook:**
- ml.t3.medium: $0.0582/hour (~$42/month if running 24/7)
- ml.t3.xlarge: $0.233/hour (~$170/month if running 24/7)
- ml.m5.xlarge: $0.276/hour (~$200/month if running 24/7)
- EBS storage: $0.10/GB/month

**Example: 3 Notebooks (dev, staging, prod)**
- Shared infrastructure: ~$24/month
- 3× ml.t3.medium (running 8h/day): ~$42/month
- Total: ~$66/month

**Cost Savings Tips:**
1. Stop notebooks when not in use
2. Use smaller instances for development
3. Enable S3 lifecycle policies (already configured)
4. Use S3 Intelligent-Tiering for unpredictable access patterns

## Updating Infrastructure

### Update Shared Infrastructure

```bash
cd shared-infra/<module>
nano terraform.tfvars
terraform plan
terraform apply
```

Changes to shared infrastructure affect all notebooks.

### Update Individual Notebooks

```bash
cd notebooks/notebook-dev
nano terraform.tfvars
terraform plan
terraform apply
```

**Note:** Changing instance type requires stopping the notebook.

### Adding New S3 Bucket Access

1. Update IAM role:
   ```bash
   cd shared-infra/iam
   nano terraform.tfvars
   # Add new bucket ARN to s3_bucket_arns
   terraform apply
   ```

2. Changes are immediately available to all notebooks.

## Cleanup

To destroy everything (in reverse order):

```bash
# 1. Destroy all notebooks
cd notebooks/notebook-dev && terraform destroy
cd ../notebook-prod && terraform destroy

# 2. Destroy VPC endpoints
cd ../../shared-infra/vpc-endpoints && terraform destroy

# 3. Destroy security groups
cd ../security-groups && terraform destroy

# 4. Destroy IAM role
cd ../iam && terraform destroy

# 5. Destroy S3 buckets (WARNING: data loss!)
cd ../s3 && terraform destroy
```

**⚠️ Warning:** Destroying S3 buckets will delete all your data! Make backups first.

## Next Steps

After deployment:

1. **Test S3 access** from your notebook
2. **Install gsutil** if migrating from GCS (see [../GSUTIL_QUICKSTART.md](../GSUTIL_QUICKSTART.md))
3. **Set up Git repositories** for your code
4. **Configure lifecycle scripts** for package installations
5. **Review S3 usage patterns** and optimize costs

## Remote State Setup (Team Collaboration)

For team environments, use remote state:

### 1. Create S3 Backend

```bash
# Create S3 bucket for state
aws s3 mb s3://my-terraform-state
aws s3api put-bucket-versioning \
  --bucket my-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### 2. Configure Backend in Each Module

Add to each module's `versions.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "ml-infra/MODULE_PATH/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

Replace `MODULE_PATH` with the actual path (e.g., `shared-infra/s3`).

### 3. Initialize with Backend

```bash
terraform init -reconfigure
```

## Support

For issues:
- Check [README.md](README.md) for architecture overview
- See module-specific README files in each directory
- Review AWS SageMaker documentation
- Check Terraform AWS provider documentation

---

**Congratulations!** You now have a scalable multi-notebook infrastructure. Add as many notebooks as you need—they'll all share the same IAM role, S3 buckets, and VPC endpoints.

```

Let me format all the Terraform files and create a final summary document:

Let me create a quick reference guide:

```markdown
# Quick Reference Guide

## Directory Structure

```
ML_NEW_STRUCTURE/
├── shared-infra/          # Shared resources (deploy once)
│   ├── s3/               # S3 buckets for datasets & models
│   ├── iam/              # Shared IAM role
│   ├── security-groups/  # Security groups
│   └── vpc-endpoints/    # VPC endpoints
├── modules/
│   └── sagemaker-notebook/  # Reusable notebook module
└── notebooks/            # Individual notebook instances
    ├── notebook-dev/
    └── notebook-prod/
```

## Quick Deploy Commands

### Deploy Shared Infrastructure

```bash
# S3 Buckets
cd shared-infra/s3
terraform init && terraform apply

# IAM Role  
cd ../iam
terraform init && terraform apply

# Security Groups
cd ../security-groups
terraform init && terraform apply

# VPC Endpoints
cd ../vpc-endpoints
terraform init && terraform apply
```

### Deploy Notebooks

```bash
# Development
cd notebooks/notebook-dev
terraform init && terraform apply

# Production
cd ../notebook-prod
terraform init && terraform apply
```

## Get Outputs

```bash
# S3 buckets
cd shared-infra/s3
terraform output datasets_bucket_name
terraform output models_bucket_name

# IAM role
cd shared-infra/iam
terraform output iam_role_arn

# Security groups
cd shared-infra/security-groups
terraform output notebook_security_group_id

# Notebook URL
cd notebooks/notebook-dev
terraform output notebook_url
```

## Common Operations

### Add a New Notebook

```bash
# Copy existing configuration
cp -r notebooks/notebook-dev notebooks/notebook-alice

# Update configuration
cd notebooks/notebook-alice
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# Deploy
terraform init
terraform apply
```

### Start/Stop Notebooks

```bash
# Stop notebook
aws sagemaker stop-notebook-instance \
  --notebook-instance-name your-notebook-name

# Start notebook
aws sagemaker start-notebook-instance \
  --notebook-instance-name your-notebook-name

# Check status
aws sagemaker describe-notebook-instance \
  --notebook-instance-name your-notebook-name
```

### Access Notebooks

```bash
# Get presigned URL
aws sagemaker create-presigned-notebook-instance-url \
  --notebook-instance-name your-notebook-name

# Or use AWS Console:
# SageMaker → Notebook instances → Open JupyterLab
```

### S3 Operations from Notebook

```python
import pandas as pd
import boto3

# Read from S3
df = pd.read_csv('s3://your-datasets-bucket/data.csv')

# Write to S3
df.to_parquet('s3://your-datasets-bucket/processed/data.parquet')

# List files
s3 = boto3.client('s3')
response = s3.list_objects_v2(Bucket='your-datasets-bucket', Prefix='raw/')
for obj in response.get('Contents', []):
    print(obj['Key'])
```

### Install gsutil in Notebook

```python
# In a notebook cell
!pip install gsutil

# Download from GCS
!gsutil cp gs://gcs-bucket/dataset.csv /tmp/

# Upload to S3
!aws s3 cp /tmp/dataset.csv s3://your-datasets-bucket/raw/
```

## Update Operations

### Update IAM Permissions

```bash
cd shared-infra/iam
nano terraform.tfvars  # Edit s3_bucket_arns or other settings
terraform apply
# Changes apply to all notebooks immediately
```

### Update Notebook Configuration

```bash
cd notebooks/notebook-dev
nano terraform.tfvars  # Change instance_type, volume_size, etc.
terraform apply
# May require notebook restart
```

### Add S3 Bucket Access

```bash
# 1. Add bucket ARN to IAM config
cd shared-infra/iam
nano terraform.tfvars
# Add to s3_bucket_arns list
terraform apply

# 2. Access from any notebook immediately
```

## Troubleshooting

### Notebook Won't Start

```bash
# Check status
aws sagemaker describe-notebook-instance \
  --notebook-instance-name your-notebook

# Check logs
aws logs tail /aws/sagemaker/NotebookInstances/your-notebook --follow

# Common fixes:
# 1. Verify VPC endpoints exist
# 2. Check security group rules
# 3. Verify IAM role permissions
```

### S3 Access Denied

```bash
# Verify IAM role has bucket access
cd shared-infra/iam
terraform output iam_role_arn
aws iam get-role-policy \
  --role-name sagemaker-notebooks-shared-role \
  --policy-name sagemaker-notebooks-shared-role-s3-access

# Verify S3 VPC endpoint
aws ec2 describe-vpc-endpoints \
  --filters "Name=service-name,Values=com.amazonaws.us-east-1.s3"
```

### State Locked

```bash
# If using remote state
terraform force-unlock <lock-id>
```

## Cleanup

```bash
# Destroy all (in order!)
cd notebooks/notebook-dev && terraform destroy
cd ../notebook-prod && terraform destroy
cd ../../shared-infra/vpc-endpoints && terraform destroy
cd ../security-groups && terraform destroy
cd ../iam && terraform destroy
cd ../s3 && terraform destroy  # ⚠️  Deletes all data!
```

## Cost Optimization

```bash
# Stop notebooks when not in use
aws sagemaker stop-notebook-instance \
  --notebook-instance-name your-notebook

# Check current costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --filter file://filter.json

# S3 storage costs
aws s3 ls s3://your-bucket --recursive --summarize --human-readable
```

## Monitoring

```bash
# List all notebooks
aws sagemaker list-notebook-instances

# Get notebook metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/SageMaker \
  --metric-name CPUUtilization \
  --dimensions Name=NotebookInstanceName,Value=your-notebook \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Average

# Check S3 bucket size
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name BucketSizeBytes \
  --dimensions Name=BucketName,Value=your-bucket Name=StorageType,Value=StandardStorage \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 86400 \
  --statistics Average
```

## Useful AWS CLI Commands

```bash
# SageMaker
aws sagemaker list-notebook-instances
aws sagemaker describe-notebook-instance --notebook-instance-name NAME
aws sagemaker start-notebook-instance --notebook-instance-name NAME
aws sagemaker stop-notebook-instance --notebook-instance-name NAME

# S3
aws s3 ls s3://bucket-name/
aws s3 cp file.txt s3://bucket-name/
aws s3 sync ./local-dir s3://bucket-name/remote-dir/

# IAM
aws iam list-roles --query 'Roles[?contains(RoleName, `sagemaker`)]'
aws iam get-role --role-name ROLE_NAME
aws iam list-attached-role-policies --role-name ROLE_NAME

# VPC
aws ec2 describe-vpcs
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxx"
aws ec2 describe-security-groups
aws ec2 describe-vpc-endpoints

# CloudWatch Logs
aws logs describe-log-groups --log-group-name-prefix /aws/sagemaker
aws logs tail /aws/sagemaker/NotebookInstances/NAME --follow
```

## Configuration Values Reference

### Instance Types

| Type | vCPU | Memory | Cost/hr | Use Case |
|------|------|--------|---------|----------|
| ml.t3.medium | 2 | 4 GB | $0.058 | Development |
| ml.t3.xlarge | 4 | 16 GB | $0.233 | General |
| ml.m5.xlarge | 4 | 16 GB | $0.276 | Production |
| ml.m5.2xlarge | 8 | 32 GB | $0.552 | Large data |
| ml.p3.2xlarge | 8 | 61 GB | $3.825 | GPU workloads |

### Root Access

- `Enabled`: Can install system packages (dev)
- `Disabled`: Restricted (prod)

### Direct Internet Access

- `Enabled`: Direct internet via IGW
- `Disabled`: Use VPC endpoints (recommended)

### Platform Identifier

- `notebook-al2-v2`: Amazon Linux 2 (recommended)
- `notebook-al1-v1`: Amazon Linux 1 (legacy)

## File Locations

### Configuration Files

```
shared-infra/MODULE/terraform.tfvars     # Module configuration
notebooks/NAME/terraform.tfvars           # Notebook configuration
```

### State Files (Local)

```
shared-infra/MODULE/terraform.tfstate    # Module state
notebooks/NAME/terraform.tfstate          # Notebook state
```

### Logs

```
/aws/sagemaker/NotebookInstances/NAME    # CloudWatch logs
```

## Environment Variables

```bash
# AWS Configuration
export AWS_REGION=us-east-1
export AWS_PROFILE=default

# Terraform
export TF_LOG=DEBUG  # Enable debug logging
export TF_LOG_PATH=./terraform.log
```

## Best Practices

1. ✅ Deploy shared infrastructure first
2. ✅ Stop notebooks when not in use
3. ✅ Use smallest instance type that meets needs
4. ✅ Enable CloudWatch logs for debugging
5. ✅ Tag all resources consistently
6. ✅ Use version control for .tfvars files
7. ✅ Back up important data to S3
8. ✅ Use remote state for team collaboration
9. ✅ Document notebook purposes
10. ✅ Review costs regularly

## Getting Help

- **Architecture**: [README.md](README.md)
- **Deployment**: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **GCS Migration**: [../GSUTIL_QUICKSTART.md](../GSUTIL_QUICKSTART.md)
- **S3 Usage**: [../S3_USAGE_GUIDE.md](../S3_USAGE_GUIDE.md)
- **AWS Docs**: https://docs.aws.amazon.com/sagemaker/
- **Terraform Docs**: https://registry.terraform.io/providers/hashicorp/aws/

---

**Quick Start Summary:**

```bash
# 1. Deploy shared infra
cd shared-infra/s3 && terraform init && terraform apply
cd ../iam && terraform init && terraform apply
cd ../security-groups && terraform init && terraform apply
cd ../vpc-endpoints && terraform init && terraform apply

# 2. Deploy notebook
cd ../../notebooks/notebook-dev && terraform init && terraform apply

# 3. Get notebook URL
terraform output notebook_url
```

Done! 🚀

```

Now let me create a final summary document:

```markdown
# ML Infrastructure Structure Overview

## 🎯 Purpose

This refactored structure is designed for **managing multiple SageMaker notebook instances** efficiently. Instead of deploying separate infrastructure for each notebook, shared resources (IAM roles, S3 buckets, VPC endpoints, security groups) are deployed once and reused by all notebooks.

## 📁 Complete Directory Structure

```
ML_NEW_STRUCTURE/
│
├── README.md                       # Architecture and overview
├── DEPLOYMENT_GUIDE.md            # Step-by-step deployment instructions
├── QUICK_REFERENCE.md             # Quick commands and reference
├── STRUCTURE_OVERVIEW.md          # This file
│
├── shared-infra/                  # Shared infrastructure (deploy once)
│   │
│   ├── s3/                        # S3 buckets for datasets & models
│   │   ├── main.tf               # Bucket resources
│   │   ├── variables.tf          # Configuration variables
│   │   ├── outputs.tf            # Bucket ARNs and names
│   │   ├── versions.tf           # Terraform & provider versions
│   │   └── terraform.tfvars.example
│   │
│   ├── iam/                       # Shared IAM role for all notebooks
│   │   ├── main.tf               # IAM role and policies
│   │   ├── variables.tf          # Configuration variables
│   │   ├── outputs.tf            # Role ARN
│   │   ├── versions.tf           # Terraform & provider versions
│   │   └── terraform.tfvars.example
│   │
│   ├── security-groups/           # Shared security groups
│   │   ├── main.tf               # Security group rules
│   │   ├── variables.tf          # Configuration variables
│   │   ├── outputs.tf            # Security group IDs
│   │   ├── versions.tf           # Terraform & provider versions
│   │   └── terraform.tfvars.example
│   │
│   └── vpc-endpoints/             # VPC endpoints for private subnets
│       ├── main.tf               # VPC endpoint resources
│       ├── variables.tf          # Configuration variables
│       ├── outputs.tf            # Endpoint IDs
│       ├── versions.tf           # Terraform & provider versions
│       └── terraform.tfvars.example
│
├── modules/                       # Reusable Terraform modules
│   └── sagemaker-notebook/       # Notebook instance module
│       ├── main.tf               # Notebook instance resource
│       ├── variables.tf          # Module input variables
│       ├── outputs.tf            # Notebook details
│       └── versions.tf           # Required versions
│
└── notebooks/                     # Individual notebook instances
    │
    ├── notebook-dev/              # Development notebook
    │   ├── main.tf               # Uses sagemaker-notebook module
    │   ├── variables.tf          # Configuration variables
    │   ├── outputs.tf            # Notebook URL and details
    │   └── terraform.tfvars.example
    │
    └── notebook-prod/             # Production notebook
        ├── main.tf               # Uses sagemaker-notebook module
        ├── variables.tf          # Configuration variables
        ├── outputs.tf            # Notebook URL and details
        └── terraform.tfvars.example
```

## 🏗️ Architecture Components

### Shared Infrastructure (1 deployment)

#### 1. S3 Buckets (`shared-infra/s3/`)
- **Datasets bucket**: Shared storage for all ML datasets
- **Models bucket**: Centralized model artifact storage
- **Features**:
  - Versioning enabled (data protection)
  - Encryption at rest (AES256 or KMS)
  - Lifecycle policies (cost optimization)
  - Public access blocked

#### 2. IAM Role (`shared-infra/iam/`)
- **Single role** used by all notebook instances
- **Permissions**:
  - Full SageMaker operations
  - S3 read/write (all managed buckets)
  - ECR access (for custom containers)
  - CloudWatch Logs
  - VPC operations
  - Git/CodeCommit access
  - Secrets Manager (for Git credentials)

#### 3. Security Groups (`shared-infra/security-groups/`)
- **Notebook security group**: Attached to all notebook instances
- **VPC endpoint security group**: For interface endpoints
- **Rules configured for**:
  - Private subnet communication
  - VPC endpoint access
  - Inter-notebook communication

#### 4. VPC Endpoints (`shared-infra/vpc-endpoints/`)
- **S3 gateway endpoint** (free)
- **SageMaker API endpoint**
- **SageMaker Runtime endpoint**
- **EC2 endpoint** (for ENI management)
- **Optional**: CloudWatch Logs, ECR endpoints

### Reusable Module (`modules/sagemaker-notebook/`)

A Terraform module that creates a SageMaker notebook instance with:
- Configurable instance type, storage, platform
- Network configuration
- Lifecycle scripts (optional)
- CloudWatch Logs integration
- Git repository integration

### Individual Notebooks (`notebooks/`)

Each notebook directory:
- Uses the reusable module
- References shared infrastructure
- Has independent configuration
- Can be deployed/destroyed independently

## 🔄 Deployment Flow

```
1. Deploy S3 Buckets
   ↓
2. Deploy IAM Role (references S3 ARNs)
   ↓
3. Deploy Security Groups
   ↓
4. Deploy VPC Endpoints (references Security Groups)
   ↓
5. Deploy Notebook(s) (references IAM, Security Groups)
```

## 💰 Cost Comparison

### Traditional Structure (per notebook)
```
Notebook 1:
  - VPC Endpoints: $21/month
  - S3 Buckets: $2/month
  - IAM Role: $0
  - Notebook Instance: $42/month (ml.t3.medium, 24/7)
  Total: $65/month

Notebook 2:
  - VPC Endpoints: $21/month
  - S3 Buckets: $2/month
  - IAM Role: $0
  - Notebook Instance: $42/month
  Total: $65/month

Notebook 3:
  - VPC Endpoints: $21/month
  - S3 Buckets: $2/month
  - IAM Role: $0
  - Notebook Instance: $42/month
  Total: $65/month

Total: $195/month
```

### New Structure (shared resources)
```
Shared Infrastructure:
  - VPC Endpoints: $21/month (shared by all)
  - S3 Buckets: $2/month (shared by all)
  - IAM Role: $0 (shared by all)
  Subtotal: $23/month

Notebooks:
  - Notebook 1: $42/month
  - Notebook 2: $42/month
  - Notebook 3: $42/month
  Subtotal: $126/month

Total: $149/month
Savings: $46/month (24%)
```

With more notebooks, savings increase!

## ✨ Key Benefits

### 1. Resource Efficiency
- ✅ Single set of VPC endpoints (save ~$14/month per additional notebook)
- ✅ Shared S3 buckets (no data duplication)
- ✅ One IAM role to manage (easier auditing)

### 2. Simplified Management
- ✅ Update IAM permissions once, affects all notebooks
- ✅ Centralized data storage and access
- ✅ Consistent security configuration
- ✅ Easy to add new notebooks (< 5 minutes)

### 3. Team Collaboration
- ✅ All team members access same datasets
- ✅ Share models and results via S3
- ✅ Consistent permissions and security
- ✅ Independent notebook environments

### 4. Scalability
- ✅ Add unlimited notebooks without infrastructure overhead
- ✅ Each notebook can have different configurations
- ✅ Independent lifecycle management per notebook

## 🚀 Quick Start

```bash
# Clone and navigate
cd ML_NEW_STRUCTURE

# Deploy shared infrastructure (once)
cd shared-infra/s3 && terraform init && terraform apply
cd ../iam && terraform init && terraform apply
cd ../security-groups && terraform init && terraform apply
cd ../vpc-endpoints && terraform init && terraform apply

# Deploy notebook (repeat for each user/environment)
cd ../../notebooks/notebook-dev && terraform init && terraform apply

# Get notebook URL
terraform output notebook_url
```

## 📊 Use Cases

### Use Case 1: Data Science Team
```
Team of 5 data scientists:

notebooks/
├── alice-notebook/     (ml.t3.medium, dev)
├── bob-notebook/       (ml.t3.xlarge, experimentation)
├── charlie-notebook/   (ml.m5.xlarge, training)
├── diana-notebook/     (ml.t3.medium, dev)
└── eve-notebook/       (ml.t3.medium, dev)

All share:
- Same datasets in S3
- Same IAM permissions
- Same VPC configuration
- Same model repository

Savings: ~$56/month compared to separate infrastructure
```

### Use Case 2: Environment Separation
```
Different environments for ML pipeline:

notebooks/
├── dev-notebook/       (ml.t3.medium)
├── staging-notebook/   (ml.m5.xlarge)
└── prod-notebook/      (ml.m5.2xlarge)

All share infrastructure but have:
- Different instance sizes
- Different configurations
- Independent deployments
```

### Use Case 3: Project-Based
```
Multiple ML projects:

notebooks/
├── nlp-project/        (for NLP team)
├── cv-project/         (for Computer Vision)
├── timeseries-proj/    (for forecasting)
└── recommendation/     (for rec systems)

Each project has dedicated notebook but shares:
- Central data lake (S3)
- Security configuration
- Cost-effective infrastructure
```

## 🔧 Common Operations

### Add a New Notebook

```bash
# Option 1: Copy existing
cp -r notebooks/notebook-dev notebooks/new-notebook
cd notebooks/new-notebook
nano terraform.tfvars
terraform init && terraform apply

# Option 2: Create from scratch
mkdir notebooks/new-notebook
# Copy module usage from notebook-dev/main.tf
terraform init && terraform apply
```

### Share Data Between Notebooks

```python
# In Notebook A - save data
import pandas as pd
df.to_parquet('s3://datasets-bucket/shared/processed-data.parquet')

# In Notebook B - load data
df = pd.read_parquet('s3://datasets-bucket/shared/processed-data.parquet')
```

### Update All Notebooks' Permissions

```bash
# Update IAM role once
cd shared-infra/iam
nano terraform.tfvars  # Add new permissions
terraform apply

# Change immediately affects all notebooks!
```

## 📝 Configuration Files

### Required Files per Module/Notebook

Each deployable unit needs:
1. **main.tf**: Resource definitions
2. **variables.tf**: Input variables
3. **outputs.tf**: Output values
4. **versions.tf**: Terraform/provider versions
5. **terraform.tfvars**: Actual configuration values (gitignored)
6. **terraform.tfvars.example**: Example configuration

### Dependency Chain

```
S3 Buckets (no dependencies)
    ↓
IAM Role (needs S3 bucket ARNs)
    ↓
Security Groups (needs VPC ID)
    ↓
VPC Endpoints (needs Security Group IDs)
    ↓
Notebooks (needs IAM Role ARN, Security Group IDs)
```

## 🛡️ Security Features

### Network Security
- All notebooks in private subnets
- Communication via VPC endpoints (no internet)
- Security groups restrict traffic
- Optional: Direct internet access disabled

### Data Security
- S3 buckets encrypted at rest
- Versioning enabled (protect against deletion)
- Public access blocked
- IAM-based access control

### Audit & Compliance
- CloudWatch Logs for all notebooks
- IAM role provides centralized permission audit
- Tags for cost tracking and compliance
- Optional: KMS encryption

## 📚 Documentation Structure

1. **README.md**: Architecture overview, benefits, getting started
2. **DEPLOYMENT_GUIDE.md**: Detailed step-by-step deployment
3. **QUICK_REFERENCE.md**: Common commands and operations
4. **STRUCTURE_OVERVIEW.md**: This file - complete structure explanation

## 🔍 Comparison: Old vs New

### Old Structure (Monolithic)
```
/
├── main.tf              # Everything in one file
├── iam.tf              # IAM for one notebook
├── s3.tf               # S3 for one notebook
├── security_groups.tf  # Security groups for one
├── vpc_endpoints.tf    # VPC endpoints for one
└── variables.tf        # All variables mixed

Problem: Need to duplicate everything for each notebook!
```

### New Structure (Modular)
```
/
├── shared-infra/       # Deploy once, use everywhere
│   ├── s3/            # Shared by all
│   ├── iam/           # Shared by all
│   ├── security-groups/ # Shared by all
│   └── vpc-endpoints/  # Shared by all
├── modules/           # Reusable components
└── notebooks/         # Easy to replicate

Benefit: Add notebooks without duplicating infrastructure!
```

## 🎓 Learning Path

1. **Start here**: Read [README.md](README.md)
2. **Deploy**: Follow [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
3. **Reference**: Use [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
4. **Understand**: Read this file
5. **Customize**: Modify for your needs

## 🤔 FAQ

**Q: Can I use different IAM roles for different notebooks?**
A: Yes, modify the notebook configuration to use `iam_role_arn` from a different IAM module.

**Q: How do I isolate data between notebooks?**
A: Use S3 prefixes and IAM policies. Example: Alice can only write to `s3://bucket/users/alice/*`

**Q: Can notebooks be in different VPCs?**
A: Yes, but you'd need separate VPC endpoints for each VPC.

**Q: What if I need a notebook without S3 access?**
A: Create a separate IAM role with limited permissions.

**Q: Can I mix instance types?**
A: Yes! Each notebook can have different instance_type in its terraform.tfvars.

## 🚦 Next Steps

After understanding the structure:

1. ✅ Review example configurations in `terraform.tfvars.example` files
2. ✅ Plan your notebook instances (how many, what types)
3. ✅ Follow [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
4. ✅ Test S3 access from deployed notebooks
5. ✅ Add more notebooks as needed
6. ✅ Set up remote state for team collaboration

## 📞 Support

- **Deployment issues**: See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Quick commands**: See [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **Architecture questions**: See [README.md](README.md)
- **AWS Documentation**: https://docs.aws.amazon.com/sagemaker/
- **Terraform Documentation**: https://registry.terraform.io/

---

**This structure is production-ready and scalable.** Start with shared infrastructure, then add as many notebooks as you need! 🚀

```

Perfect! Let me create one final comparison document and then provide you with a complete summary:

```markdown
# Migration Guide: Old Structure → New Structure

This guide helps you migrate from the monolithic structure (single module) to the new modular structure (shared infrastructure + multiple notebooks).

## Comparison

### Old Structure (Monolithic)
```
ml-test/
├── main.tf                 # Single notebook instance
├── iam.tf                  # IAM role for one notebook
├── s3.tf                   # S3 buckets for one notebook
├── security_groups.tf      # Security group for one notebook
├── vpc_endpoints_example.tf
├── variables.tf            # All variables
├── outputs.tf              # All outputs
└── terraform.tfvars        # Configuration for one notebook

Problem: To add a second notebook, you need to:
- Duplicate all files
- Manage separate S3 buckets
- Pay for duplicate VPC endpoints
- Manage separate IAM roles
```

### New Structure (Modular)
```
ML_NEW_STRUCTURE/
├── shared-infra/          # Deploy once
│   ├── s3/               # Shared S3 buckets
│   ├── iam/              # Shared IAM role
│   ├── security-groups/  # Shared security groups
│   └── vpc-endpoints/    # Shared VPC endpoints
└── notebooks/             # Deploy many
    ├── notebook-dev/
    ├── notebook-prod/
    └── notebook-X/        # Easy to add more!

Benefit: Add notebooks without duplicating infrastructure!
```

## Key Differences

| Aspect | Old Structure | New Structure |
|--------|--------------|---------------|
| **S3 Buckets** | Per notebook | Shared by all |
| **IAM Role** | Per notebook | Shared by all |
| **VPC Endpoints** | Per notebook | Shared by all |
| **Security Groups** | Per notebook | Shared by all |
| **Add Notebook** | Copy & modify all files | Copy one directory |
| **Update Permissions** | Update each notebook | Update once, affects all |
| **Cost (3 notebooks)** | ~$195/month | ~$149/month |
| **Scalability** | Poor | Excellent |

## Migration Options

### Option 1: Fresh Deployment (Recommended)

**Best for**: New projects or when you can recreate notebooks

1. **Deploy new structure** (see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md))
2. **Migrate data from old S3 to new S3**:
   ```bash
   aws s3 sync s3://old-bucket s3://new-bucket
   ```
3. **Destroy old infrastructure**:
   ```bash
   cd ../old-structure
   terraform destroy
   ```

**Pros:**
- Clean start
- No state migration complexity
- Test before switching

**Cons:**
- Brief downtime during migration
- Need to recreate notebooks

### Option 2: Import Existing Resources

**Best for**: When you must avoid recreation

1. **Deploy new structure but don't create resources**
2. **Import existing resources**:
   ```bash
   # Import S3 buckets
   cd shared-infra/s3
   terraform import aws_s3_bucket.datasets your-existing-bucket-name
   
   # Import IAM role
   cd ../iam
   terraform import aws_iam_role.sagemaker_shared your-existing-role-name
   
   # Import security groups
   cd ../security-groups
   terraform import aws_security_group.sagemaker_notebook sg-xxxxx
   
   # Import notebooks
   cd ../../notebooks/notebook-dev
   terraform import module.notebook.aws_sagemaker_notebook_instance.this your-notebook-name
   ```

**Pros:**
- No recreation
- No downtime
- Keep existing notebooks

**Cons:**
- Complex
- Requires careful state management
- Risk of errors

### Option 3: Parallel Deployment

**Best for**: Testing before full migration

1. **Deploy new structure alongside old**
2. **Test with new notebooks**
3. **Migrate data gradually**
4. **Destroy old structure when ready**

**Pros:**
- No downtime
- Test thoroughly
- Gradual migration

**Cons:**
- Temporary duplicate costs
- Data synchronization needed

## Step-by-Step: Fresh Deployment Migration

### Phase 1: Prepare (No Changes Yet)

1. **Document current setup**:
   ```bash
   cd old-structure
   terraform output > old-outputs.txt
   ```

2. **Backup S3 data**:
   ```bash
   aws s3 sync s3://old-datasets-bucket ./backup-datasets/
   aws s3 sync s3://old-models-bucket ./backup-models/
   ```

3. **Export notebook configurations** (instance type, volume size, etc.)

### Phase 2: Deploy New Infrastructure

1. **Deploy shared infrastructure**:
   ```bash
   cd ML_NEW_STRUCTURE/shared-infra/s3
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with NEW bucket names
   terraform init && terraform apply
   
   cd ../iam
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars
   terraform init && terraform apply
   
   cd ../security-groups
   cp terraform.tfvars.example terraform.tfvars
   # Use SAME vpc_id as old structure
   terraform init && terraform apply
   
   cd ../vpc-endpoints
   cp terraform.tfvars.example terraform.tfvars
   # Use SAME vpc_id and subnets as old structure
   terraform init && terraform apply
   ```

2. **Migrate S3 data**:
   ```bash
   # Get new bucket names
   cd shared-infra/s3
   terraform output datasets_bucket_name  # Get new bucket name
   
   # Sync data from old to new
   aws s3 sync s3://old-datasets-bucket s3://new-datasets-bucket
   aws s3 sync s3://old-models-bucket s3://new-models-bucket
   ```

3. **Verify data migration**:
   ```bash
   aws s3 ls s3://new-datasets-bucket --recursive | wc -l
   aws s3 ls s3://old-datasets-bucket --recursive | wc -l
   # Count should match
   ```

### Phase 3: Deploy New Notebooks

1. **Stop old notebooks** (to avoid conflicts):
   ```bash
   aws sagemaker stop-notebook-instance \
     --notebook-instance-name old-notebook-name
   ```

2. **Deploy new notebooks**:
   ```bash
   cd notebooks/notebook-dev
   cp terraform.tfvars.example terraform.tfvars
   # Use SAME subnet_id, instance_type as old notebook
   # Use NEW iam_role_arn from shared-infra/iam
   # Use NEW security_group_ids from shared-infra/security-groups
   terraform init && terraform apply
   ```

3. **Test new notebook**:
   - Open notebook in AWS Console
   - Test S3 access
   - Test Git access (if configured)
   - Run test workload

### Phase 4: Cleanup Old Infrastructure

1. **Verify everything works** in new structure

2. **Destroy old infrastructure**:
   ```bash
   cd old-structure
   
   # Optional: Keep old S3 buckets for a while
   # Comment out S3 bucket resources in s3.tf
   
   terraform destroy
   ```

3. **Verify cleanup**:
   ```bash
   aws sagemaker list-notebook-instances
   # Should only show new notebooks
   
   aws ec2 describe-vpc-endpoints
   # Should show new VPC endpoints
   ```

## Mapping Old to New

### Variables Mapping

| Old Variable | New Location |
|--------------|--------------|
| `datasets_bucket_name` | `shared-infra/s3/terraform.tfvars` |
| `models_bucket_name` | `shared-infra/s3/terraform.tfvars` |
| `iam_role_name` | `shared-infra/iam/terraform.tfvars` |
| `notebook_sg_name` | `shared-infra/security-groups/terraform.tfvars` |
| `instance_type` | `notebooks/notebook-X/terraform.tfvars` |
| `subnet_id` | `notebooks/notebook-X/terraform.tfvars` |

### Outputs Mapping

| Old Output | New Location |
|------------|--------------|
| `datasets_bucket_name` | `cd shared-infra/s3 && terraform output` |
| `iam_role_arn` | `cd shared-infra/iam && terraform output` |
| `security_group_id` | `cd shared-infra/security-groups && terraform output` |
| `notebook_url` | `cd notebooks/notebook-X && terraform output` |

### Files Mapping

| Old File | New Location |
|----------|--------------|
| `s3.tf` | `shared-infra/s3/main.tf` |
| `iam.tf` | `shared-infra/iam/main.tf` |
| `security_groups.tf` | `shared-infra/security-groups/main.tf` |
| `vpc_endpoints_example.tf` | `shared-infra/vpc-endpoints/main.tf` |
| `main.tf` (notebook) | `modules/sagemaker-notebook/main.tf` |

## Conversion Example

### Old: Single terraform.tfvars
```hcl
# Old structure - everything in one file
project_name = "ml-project"
environment  = "dev"
vpc_id       = "vpc-xxxxx"
subnet_id    = "subnet-xxxxx"

# S3 buckets
create_datasets_bucket = true
datasets_bucket_name = "ml-project-dev-datasets"

# Notebook
instance_type = "ml.t3.medium"
volume_size   = 10
```

### New: Split Across Multiple Files

**shared-infra/s3/terraform.tfvars:**
```hcl
datasets_bucket_name = "ml-project-datasets"  # No env suffix - shared!
models_bucket_name = "ml-project-models"
```

**shared-infra/iam/terraform.tfvars:**
```hcl
iam_role_name = "ml-project-notebooks-role"  # Shared role
s3_bucket_arns = [
  "arn:aws:s3:::ml-project-datasets",
  "arn:aws:s3:::ml-project-models"
]
```

**notebooks/notebook-dev/terraform.tfvars:**
```hcl
project_name = "ml-project"
environment  = "dev"
subnet_id    = "subnet-xxxxx"
instance_type = "ml.t3.medium"
volume_size   = 10

# Reference shared infrastructure (from outputs)
iam_role_arn = "arn:aws:iam::123456789012:role/ml-project-notebooks-role"
security_group_ids = ["sg-xxxxx"]
```

## Common Issues During Migration

### Issue 1: State Conflicts

**Problem**: "Resource already exists"

**Solution**: 
```bash
# Option A: Import
terraform import aws_s3_bucket.datasets existing-bucket-name

# Option B: Remove from old state
cd old-structure
terraform state rm aws_s3_bucket.datasets
```

### Issue 2: Bucket Name Already Exists

**Problem**: S3 bucket names are globally unique

**Solution**: Use different bucket names in new structure:
```hcl
# Old
datasets_bucket_name = "ml-project-dev-datasets"

# New
datasets_bucket_name = "ml-project-shared-datasets"
```

### Issue 3: VPC Endpoint Conflicts

**Problem**: Can't have duplicate VPC endpoints

**Solution**: Destroy old VPC endpoints first:
```bash
cd old-structure
terraform destroy -target=aws_vpc_endpoint.s3
terraform destroy -target=aws_vpc_endpoint.sagemaker_api
```

### Issue 4: IAM Role Name Conflict

**Problem**: IAM role names must be unique

**Solution**: Use different role name:
```hcl
# Old
iam_role_name = "sagemaker-dev-role"

# New
iam_role_name = "sagemaker-notebooks-shared-role"
```

## Testing Checklist

After migration, verify:

- [ ] Can access new notebook via AWS Console
- [ ] Can read from new S3 datasets bucket
- [ ] Can write to new S3 datasets bucket
- [ ] Can read/write to models bucket
- [ ] CloudWatch logs are working
- [ ] Git repository access works (if configured)
- [ ] Can import common ML libraries
- [ ] Can run sample ML workflow
- [ ] All team members have access

## Rollback Plan

If migration fails:

1. **Keep old infrastructure running** during migration
2. **Document any issues** encountered
3. **To rollback**:
   ```bash
   # Start old notebooks
   aws sagemaker start-notebook-instance \
     --notebook-instance-name old-notebook
   
   # Destroy new infrastructure
   cd ML_NEW_STRUCTURE
   # Destroy notebooks
   cd notebooks/notebook-dev && terraform destroy
   # Destroy shared infra
   cd ../../shared-infra/vpc-endpoints && terraform destroy
   cd ../security-groups && terraform destroy
   cd ../iam && terraform destroy
   cd ../s3 && terraform destroy
   ```

## Timeline Estimate

| Phase | Time | Downtime |
|-------|------|----------|
| Preparation | 1 hour | None |
| Deploy shared infra | 30 mins | None |
| Migrate S3 data | 1-4 hours* | None |
| Deploy new notebooks | 15 mins each | Yes** |
| Testing | 1 hour | None |
| Cleanup | 30 mins | None |

*Depends on data size  
**Only for notebooks being replaced

## Cost During Migration

**Parallel deployment** (both old and new running):
- Duration: 1 day
- Extra cost: ~$5-10 (temporary duplicate VPC endpoints and notebooks)

**Fresh deployment** (destroy old, create new):
- Duration: Few hours
- Extra cost: $0 (brief downtime)

## Post-Migration Benefits

After migration, you'll have:

1. ✅ **Lower costs**: ~24% savings with 3 notebooks, more with additional notebooks
2. ✅ **Easier management**: Update permissions once, affects all
3. ✅ **Faster deployment**: Add new notebooks in < 5 minutes
4. ✅ **Better collaboration**: Shared data, consistent environment
5. ✅ **Scalability**: Add unlimited notebooks without infrastructure overhead

## Next Steps

1. Choose migration option (Fresh Deployment recommended)
2. Follow phase-by-phase guide above
3. Test thoroughly before cleanup
4. Document any customizations
5. Train team on new structure

## Support

- **Migration issues**: Contact your team lead or AWS support
- **Terraform questions**: See Terraform documentation
- **Architecture questions**: See [README.md](README.md)
- **Deployment help**: See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

**Recommendation**: Use **Fresh Deployment** for clean migration. Total time: ~4-6 hours including testing.

```

Perfect! Now let me create a final summary document for you:

```markdown
# 🚀 Start Here: Multi-Notebook SageMaker Infrastructure

Welcome! This is a **production-ready, modular infrastructure** for deploying multiple SageMaker notebook instances that share common resources.

## ⚡ Quick Overview

**Problem this solves**: You want to create multiple notebooks in your AWS account, but don't want to:
- Pay for duplicate VPC endpoints ($21/month each)
- Manage separate S3 buckets for each notebook
- Maintain multiple IAM roles
- Duplicate security configurations

**Solution**: This structure deploys shared infrastructure once, then lets you add unlimited notebooks that reuse it.

## 📊 Cost Comparison

| Setup | 1 Notebook | 3 Notebooks | 10 Notebooks |
|-------|-----------|-------------|--------------|
| **Old Way** | $65/mo | $195/mo | $650/mo |
| **New Way** | $65/mo | $149/mo | $443/mo |
| **Savings** | $0 | $46/mo (24%) | $207/mo (32%) |

*Assumes ml.t3.medium running 24/7, actual costs vary*

## 🎯 What You Get

### Shared Infrastructure (Deploy Once)
- ✅ **S3 Buckets**: Datasets & models storage with versioning
- ✅ **IAM Role**: Shared permissions for all notebooks
- ✅ **Security Groups**: Pre-configured for private subnets
- ✅ **VPC Endpoints**: Cost-effective shared endpoints

### Individual Notebooks (Deploy Many)
- ✅ **Easy to deploy**: < 5 minutes each
- ✅ **Independent configuration**: Different sizes, settings
- ✅ **Automatic access**: To shared S3, IAM, networking

## 📚 Documentation

Start with what you need:

### 🆕 First Time Users
1. **[STRUCTURE_OVERVIEW.md](STRUCTURE_OVERVIEW.md)** - Understand the architecture
2. **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Step-by-step deployment
3. **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Common commands

### 🔄 Migrating from Old Structure
- **[MIGRATION_FROM_OLD.md](MIGRATION_FROM_OLD.md)** - Migration guide

### 📖 Reference Docs
- **[README.md](README.md)** - Complete architecture documentation

## 🏃 Quick Start (5 Minutes)

### 1. Deploy Shared Infrastructure

```bash
cd ML_NEW_STRUCTURE/shared-infra

# S3 Buckets (2 min)
cd s3
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit bucket names
terraform init && terraform apply

# IAM Role (1 min)
cd ../iam
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit role name & bucket ARNs
terraform init && terraform apply

# Security Groups (1 min)
cd ../security-groups
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit VPC ID
terraform init && terraform apply

# VPC Endpoints (2 min)
cd ../vpc-endpoints
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit VPC, subnets, security groups
terraform init && terraform apply
```

### 2. Deploy Your First Notebook

```bash
cd ../../notebooks/notebook-dev

cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit notebook configuration
terraform init && terraform apply

# Get notebook URL
terraform output notebook_url
```

### 3. Access Your Notebook

```bash
# Option 1: AWS Console
# Navigate to: SageMaker → Notebook instances → Open JupyterLab

# Option 2: CLI
aws sagemaker create-presigned-notebook-instance-url \
  --notebook-instance-name $(terraform output -raw notebook_name)
```

## 📁 Directory Structure

```
ML_NEW_STRUCTURE/
├── 00_START_HERE.md          ← You are here!
├── README.md                  ← Architecture overview
├── DEPLOYMENT_GUIDE.md        ← Detailed deployment steps
├── QUICK_REFERENCE.md         ← Command reference
├── STRUCTURE_OVERVIEW.md      ← Complete structure explanation
├── MIGRATION_FROM_OLD.md      ← Migration guide
│
├── shared-infra/              ← Deploy once
│   ├── s3/                   ← S3 buckets
│   ├── iam/                  ← IAM role
│   ├── security-groups/      ← Security groups
│   └── vpc-endpoints/        ← VPC endpoints
│
├── modules/                   ← Reusable components
│   └── sagemaker-notebook/   ← Notebook module
│
└── notebooks/                 ← Deploy many
    ├── notebook-dev/         ← Development notebook
    └── notebook-prod/        ← Production notebook
```

## 🎓 Learning Path

**Level 1: Understanding** (15 minutes)
1. Read this file (you're doing it!)
2. Skim [STRUCTURE_OVERVIEW.md](STRUCTURE_OVERVIEW.md)

**Level 2: Deployment** (1 hour)
3. Follow [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
4. Deploy shared infrastructure
5. Deploy first notebook

**Level 3: Mastery** (ongoing)
6. Use [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for daily operations
7. Add more notebooks as needed
8. Customize for your organization

## 🔑 Key Concepts

### Shared vs Individual Resources

**Shared Resources** (cost-effective, deploy once):
- S3 buckets (everyone reads/writes same data)
- IAM role (same permissions for all notebooks)
- VPC endpoints (shared network access)
- Security groups (consistent security)

**Individual Resources** (flexible, deploy many):
- Notebook instances (different sizes, users)
- CloudWatch log groups (separate logs)
- Lifecycle configs (custom startup scripts)

### Why This Works

```
Traditional:
Notebook 1 → Own IAM + Own S3 + Own VPC Endpoints = $65/month
Notebook 2 → Own IAM + Own S3 + Own VPC Endpoints = $65/month
Notebook 3 → Own IAM + Own S3 + Own VPC Endpoints = $65/month
Total: $195/month

New Structure:
Shared IAM + Shared S3 + Shared VPC Endpoints = $23/month
Notebook 1 = $42/month
Notebook 2 = $42/month  
Notebook 3 = $42/month
Total: $149/month (24% savings!)
```

## 💡 Use Cases

### Use Case 1: Data Science Team
```
Team of 5 data scientists, each needs their own notebook:

notebooks/
├── alice-notebook/
├── bob-notebook/
├── charlie-notebook/
├── diana-notebook/
└── eve-notebook/

All share: Same data, same permissions, same infrastructure
Each has: Own environment, own instance size, own configs
```

### Use Case 2: Environment Separation
```
Different environments for your ML pipeline:

notebooks/
├── dev-notebook/      (ml.t3.medium, for development)
├── staging-notebook/  (ml.m5.xlarge, for testing)
└── prod-notebook/     (ml.m5.2xlarge, for production)
```

### Use Case 3: Project-Based
```
Different projects, different notebooks:

notebooks/
├── nlp-project/
├── computer-vision/
├── recommendation/
└── forecasting/
```

## 🛠️ Prerequisites

Before you start:

- [ ] AWS CLI configured (`aws configure`)
- [ ] Terraform >= 1.0 installed
- [ ] Existing VPC with private subnets
- [ ] VPC Route table IDs
- [ ] Basic understanding of AWS (VPC, IAM, S3)

## 🚨 Important Notes

1. **Bucket names must be globally unique**: Change them in `terraform.tfvars`
2. **Deploy in order**: S3 → IAM → Security Groups → VPC Endpoints → Notebooks
3. **Private subnets**: VPC endpoints are required
4. **Costs**: VPC endpoints cost ~$21/month, notebooks vary by instance type
5. **Shared data**: All notebooks can access all data in S3 (use IAM policies for restrictions)

## ✅ What to Do First

**Step 1**: Read [STRUCTURE_OVERVIEW.md](STRUCTURE_OVERVIEW.md) (10 min)
- Understand the architecture
- See how resources are organized
- Learn about cost savings

**Step 2**: Review configurations
- Look at `shared-infra/*/terraform.tfvars.example`
- Look at `notebooks/*/terraform.tfvars.example`
- Plan your bucket names, IAM role names

**Step 3**: Deploy
- Follow [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- Start with shared infrastructure
- Then deploy your first notebook

**Step 4**: Test
- Access your notebook
- Test S3 access
- Install packages (if root access enabled)

**Step 5**: Scale
- Add more notebooks as needed
- Reference [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

## 💰 Cost Breakdown

### Shared Infrastructure (~$23/month)
- S3 storage: ~$2/month (100GB datasets)
- VPC Endpoints: ~$21/month (3 interface endpoints)
- IAM Role: Free
- Security Groups: Free

### Per Notebook (varies)
- ml.t3.medium: $0.058/hour (~$42/month if 24/7)
- ml.t3.xlarge: $0.233/hour (~$170/month if 24/7)
- ml.m5.xlarge: $0.276/hour (~$200/month if 24/7)
- EBS storage: $0.10/GB/month

**Pro Tip**: Stop notebooks when not in use to save ~70% on notebook costs!

## 🆘 Getting Help

### Quick Help
- **Commands**: See [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **Deployment issues**: See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Architecture questions**: See [STRUCTURE_OVERVIEW.md](STRUCTURE_OVERVIEW.md)

### Common Issues
- **Bucket already exists**: Use a different bucket name
- **Notebook stuck "Pending"**: Check VPC endpoints and security groups
- **S3 access denied**: Verify IAM role has bucket ARNs
- **State locked**: Run `terraform force-unlock <lock-id>`

### Resources
- [AWS SageMaker Docs](https://docs.aws.amazon.com/sagemaker/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)
- [S3 Usage Guide](../S3_USAGE_GUIDE.md)
- [gsutil Quick Start](../GSUTIL_QUICKSTART.md)

## 🎉 Success Looks Like

After deployment, you'll have:

1. ✅ Shared S3 buckets for datasets and models
2. ✅ Shared IAM role with appropriate permissions
3. ✅ Security groups configured for private subnets
4. ✅ VPC endpoints for AWS service access
5. ✅ One or more notebook instances running
6. ✅ Ability to add notebooks in < 5 minutes
7. ✅ Cost savings compared to separate infrastructure

## 🚀 Next Steps

**Immediate** (now):
1. Read [STRUCTURE_OVERVIEW.md](STRUCTURE_OVERVIEW.md)
2. Review terraform.tfvars.example files
3. Plan your deployment

**Short-term** (this week):
4. Deploy shared infrastructure
5. Deploy first notebook
6. Test S3 access and workflows

**Long-term** (ongoing):
7. Add notebooks for team members
8. Set up Git repository integration
9. Configure lifecycle scripts
10. Optimize costs (stop unused notebooks)

---

## 📝 Summary

This structure gives you:
- **Cost savings**: 24-32% compared to separate infrastructure
- **Easy management**: Update permissions once, affects all notebooks
- **Fast deployment**: Add new notebooks in < 5 minutes
- **Team collaboration**: Shared data and consistent environments
- **Scalability**: Add unlimited notebooks without infrastructure overhead

**Ready to start?** → Read [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

**Questions about structure?** → Read [STRUCTURE_OVERVIEW.md](STRUCTURE_OVERVIEW.md)

**Need quick commands?** → See [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

---

**Welcome to efficient multi-notebook management!** 🎊

```

Excellent! I've successfully created a complete refactored structure for managing multiple SageMaker notebooks. Let me provide you with a comprehensive summary:

## 🎉 Complete Summary

I've created a **production-ready, modular infrastructure** in the `ML_NEW_STRUCTURE` folder that allows you to efficiently manage multiple SageMaker notebook instances while sharing common resources.

### 📁 What Was Created

```
ML_NEW_STRUCTURE/
├── 📘 Documentation (6 files)
│   ├── 00_START_HERE.md           # Start here! Quick overview
│   ├── README.md                   # Architecture & features
│   ├── DEPLOYMENT_GUIDE.md         # Step-by-step deployment
│   ├── QUICK_REFERENCE.md          # Command reference
│   ├── STRUCTURE_OVERVIEW.md       # Complete structure explanation
│   └── MIGRATION_FROM_OLD.md       # Migration from old structure
│
├── 🔧 Shared Infrastructure (Deploy Once)
│   ├── s3/                        # S3 buckets (datasets & models)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── terraform.tfvars.example
│   │
│   ├── iam/                       # Shared IAM role
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── terraform.tfvars.example
│   │
│   ├── security-groups/           # Shared security groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── terraform.tfvars.example
│   │
│   └── vpc-endpoints/             # Shared VPC endpoints
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── terraform.tfvars.example
│
├── 📦 Reusable Module
│   └── sagemaker-notebook/        # Notebook instance module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
│
└── 💻 Notebook Instances (Deploy Many)
    ├── notebook-dev/              # Development notebook example
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars.example
    │
    └── notebook-prod/             # Production notebook example
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars.example

Total: 42 files created
```

### 🎯 Key Benefits

1. **💰 Cost Savings**: 24-32% savings with multiple notebooks
   - 1 notebook: Same cost as before
   - 3 notebooks: Save $46/month (24%)
   - 10 notebooks: Save $207/month (32%)

2. **⚡ Easy Management**:
   - Update IAM permissions once → affects all notebooks
   - Shared S3 buckets → no data duplication
   - Add new notebook in < 5 minutes

3. **🔒 Security**:
   - Centralized IAM role management
   - Consistent security group configuration
   - Shared VPC endpoints for private subnets

4. **📈 Scalability**:
   - Add unlimited notebooks without infrastructure overhead
   - Each notebook can have different configurations
   - Independent lifecycle management

### 🚀 Quick Start

```bash
# Navigate to new structure
cd ML_NEW_STRUCTURE

# Read the overview
cat 00_START_HERE.md

# Deploy shared infrastructure (once)
cd shared-infra/s3 && terraform init && terraform apply
cd ../iam && terraform init && terraform apply
cd ../security-groups && terraform init && terraform apply
cd ../vpc-endpoints && terraform init && terraform apply

# Deploy your first notebook
cd ../../notebooks/notebook-dev && terraform init && terraform apply

# Get notebook URL
terraform output notebook_url
```

### 📊 Cost Comparison

| Setup | Old Way | New Way | Savings |
|-------|---------|---------|---------|
| **1 Notebook** | $65/mo | $65/mo | $0 |
| **3 Notebooks** | $195/mo | $149/mo | $46/mo (24%) |
| **5 Notebooks** | $325/mo | $233/mo | $92/mo (28%) |
| **10 Notebooks** | $650/mo | $443/mo | $207/mo (32%) |

### 🎓 Documentation Guide

1. **Start Here**: `00_START_HERE.md` - Quick overview and getting started
2. **Understand**: `STRUCTURE_OVERVIEW.md` - Complete architecture explanation
3. **Deploy**: `DEPLOYMENT_GUIDE.md` - Step-by-step deployment instructions
4. **Reference**: `QUICK_REFERENCE.md` - Common commands and operations
5. **Migrate**: `MIGRATION_FROM_OLD.md` - If migrating from old structure
6. **Architecture**: `README.md` - Detailed architecture documentation

### 🔥 Features Included

#### Shared Infrastructure
- ✅ S3 buckets with versioning, encryption, lifecycle policies
- ✅ IAM role with comprehensive permissions
- ✅ Security groups for notebooks and VPC endpoints
- ✅ VPC endpoints (S3, SageMaker API/Runtime, EC2)

#### Notebook Module
- ✅ Configurable instance types and storage
- ✅ Lifecycle configuration support
- ✅ CloudWatch Logs integration
- ✅ Git repository integration
- ✅ Network isolation options

#### Documentation
- ✅ Complete deployment guide
- ✅ Quick reference for common operations
- ✅ Migration guide from old structure
- ✅ Cost analysis and optimization tips
- ✅ Troubleshooting guides

### 💡 Use Cases

**Use Case 1: Data Science Team**
- Each team member gets their own notebook
- All share same datasets and models in S3
- Consistent permissions and security

**Use Case 2: Environment Separation**
- Dev, staging, and production notebooks
- Different instance sizes per environment
- Shared data and models

**Use Case 3: Project-Based**
- Separate notebooks per ML project
- Centralized data storage
- Easy to add new projects

### 🎁 What Makes This Special

1. **Production-Ready**: All best practices included (encryption, versioning, logging)
2. **Well-Documented**: 6 comprehensive documentation files
3. **Cost-Optimized**: Shared resources reduce overhead significantly
4. **Scalable**: Add unlimited notebooks easily
5. **Flexible**: Each notebook can be configured independently
6. **Secure**: Private subnets, VPC endpoints, IAM-based access
7. **Team-Friendly**: Multiple users can work simultaneously

### 🚀 Next Steps

1. **Read** `00_START_HERE.md` (5 minutes)
2. **Review** `STRUCTURE_OVERVIEW.md` (15 minutes)
3. **Deploy** following `DEPLOYMENT_GUIDE.md` (1 hour)
4. **Use** `QUICK_REFERENCE.md` for daily operations

### 📝 Important Notes

- ✅ Current code remains untouched (as requested)
- ✅ Everything is in the new `ML_NEW_STRUCTURE` folder
- ✅ Can be used independently or alongside existing code
- ✅ Fully compatible with your existing gsutil/S3 setup
- ✅ Works with the S3 buckets and guides we created earlier

---

**You now have a complete, production-ready infrastructure for managing multiple SageMaker notebooks efficiently!** 🎊

Start by reading `ML_NEW_STRUCTURE/00_START_HERE.md` and then follow the deployment guide. The structure will save you significant costs and management overhead when working with multiple notebooks.

```plaintext
ML_NEW_STRUCTURE/
├── 📘 Documentation (6 files)
│   ├── 00_START_HERE.md           # Start here! Quick overview
│   ├── README.md                   # Architecture & features
│   ├── DEPLOYMENT_GUIDE.md         # Step-by-step deployment
│   ├── QUICK_REFERENCE.md          # Command reference
│   ├── STRUCTURE_OVERVIEW.md       # Complete structure explanation
│   └── MIGRATION_FROM_OLD.md       # Migration from old structure
│
├── 🔧 Shared Infrastructure (Deploy Once)
│   ├── s3/                        # S3 buckets (datasets & models)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── terraform.tfvars.example
│   │
│   ├── iam/                       # Shared IAM role
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── terraform.tfvars.example
│   │
│   ├── security-groups/           # Shared security groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── terraform.tfvars.example
│   │
│   └── vpc-endpoints/             # Shared VPC endpoints
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── terraform.tfvars.example
│
├── 📦 Reusable Module
│   └── sagemaker-notebook/        # Notebook instance module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
│
└── 💻 Notebook Instances (Deploy Many)
    ├── notebook-dev/              # Development notebook example
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars.example
    │
    └── notebook-prod/             # Production notebook example
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars.example

Total: 42 files created
```

```shellscript
# Navigate to new structure
cd ML_NEW_STRUCTURE

# Read the overview
cat 00_START_HERE.md

# Deploy shared infrastructure (once)
cd shared-infra/s3 && terraform init && terraform apply
cd ../iam && terraform init && terraform apply
cd ../security-groups && terraform init && terraform apply
cd ../vpc-endpoints && terraform init && terraform apply

# Deploy your first notebook
cd ../../notebooks/notebook-dev && terraform init && terraform apply

# Get notebook URL
terraform output notebook_url
```

