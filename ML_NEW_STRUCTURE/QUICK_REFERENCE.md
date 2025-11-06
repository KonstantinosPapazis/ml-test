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

