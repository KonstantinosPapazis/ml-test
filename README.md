# Production-Ready SageMaker Notebook Terraform Module

This Terraform configuration provides a complete, production-ready deployment of an AWS SageMaker notebook instance with full support for private subnets, comprehensive IAM roles, and security groups.

## Features

- ✅ **Complete IAM Role Configuration** - Includes all necessary permissions for SageMaker operations
- ✅ **Private Subnet Support** - Designed for deployment in private subnets with VPC endpoints
- ✅ **Security Groups** - Pre-configured security groups with all necessary rules
- ✅ **Git Integration** - Full support for GitHub, GitLab, Bitbucket, and AWS CodeCommit (see [GIT_SETUP.md](GIT_SETUP.md))
- ✅ **Encryption Support** - Optional KMS encryption for EBS volumes
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
