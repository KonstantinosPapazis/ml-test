# Quick Reference Guide

## Quick Start (TL;DR)

```bash
# 1. Configure
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Edit with your values

# 2. Deploy
terraform init
terraform plan
terraform apply

# 3. Access
# Get notebook name: terraform output notebook_instance_name
# Open in AWS Console: SageMaker → Notebook Instances → Open JupyterLab
```

## Essential Variables

```hcl
# Minimum required in terraform.tfvars:
aws_region     = "us-east-1"
project_name   = "ml-project"
environment    = "dev"
vpc_id         = "vpc-xxx"
subnet_id      = "subnet-xxx"
vpc_cidr_block = "10.0.0.0/16"
s3_bucket_arns = ["arn:aws:s3:::bucket"]
```

## Common Commands

### Deployment
```bash
terraform init                    # Initialize
terraform validate               # Validate config
terraform plan                   # Preview changes
terraform apply                  # Deploy
terraform apply -auto-approve    # Deploy without confirmation
terraform destroy                # Delete all resources
```

### Notebook Operations
```bash
# Get notebook name
NB_NAME=$(terraform output -raw notebook_instance_name)

# Stop notebook
aws sagemaker stop-notebook-instance --notebook-instance-name $NB_NAME

# Start notebook
aws sagemaker start-notebook-instance --notebook-instance-name $NB_NAME

# Check status
aws sagemaker describe-notebook-instance --notebook-instance-name $NB_NAME

# Get presigned URL
aws sagemaker create-presigned-notebook-instance-url --notebook-instance-name $NB_NAME
```

### Monitoring
```bash
# View logs
aws logs tail /aws/sagemaker/NotebookInstances/$NB_NAME --follow

# List log streams
aws logs describe-log-streams \
  --log-group-name /aws/sagemaker/NotebookInstances/$NB_NAME
```

### Information
```bash
# View all outputs
terraform output

# Get specific output
terraform output notebook_instance_arn
terraform output security_group_id
terraform output iam_role_arn

# Show current state
terraform show

# List resources
terraform state list
```

## Instance Types Reference

| Type | vCPUs | Memory | GPU | $/hour* | Use Case |
|------|-------|--------|-----|---------|----------|
| ml.t3.medium | 2 | 4 GB | - | $0.05 | Development |
| ml.t3.xlarge | 4 | 16 GB | - | $0.19 | Light workloads |
| ml.m5.xlarge | 4 | 16 GB | - | $0.23 | Balanced |
| ml.m5.2xlarge | 8 | 32 GB | - | $0.46 | Medium datasets |
| ml.m5.4xlarge | 16 | 64 GB | - | $0.92 | Large datasets |
| ml.p3.2xlarge | 8 | 61 GB | 1 V100 | $3.06 | GPU training |
| ml.p3.8xlarge | 32 | 244 GB | 4 V100 | $12.24 | Heavy GPU |

*Approximate pricing - check AWS pricing for your region

## Variable Quick Reference

### Essential
```hcl
project_name           # Your project name
environment            # dev/staging/prod
vpc_id                 # VPC ID
subnet_id              # Private subnet ID
vpc_cidr_block         # VPC CIDR (e.g., 10.0.0.0/16)
```

### Instance Config
```hcl
instance_type          # ml.t3.medium, ml.m5.xlarge, etc.
volume_size            # 5-16384 GB
platform_identifier    # notebook-al2-v2 (recommended)
root_access            # "Enabled" or "Disabled"
direct_internet_access # "Enabled" or "Disabled"
```

### Security
```hcl
create_security_group  # true/false
allowed_cidr_blocks    # ["10.0.0.0/16"]
kms_key_id             # KMS key ARN for encryption
```

### IAM
```hcl
create_iam_role        # true/false
s3_bucket_arns         # ["arn:aws:s3:::bucket"]
additional_iam_policies # Additional policy ARNs
```

### Lifecycle
```hcl
create_lifecycle_config      # true/false
lifecycle_config_on_create   # base64 encoded script
lifecycle_config_on_start    # base64 encoded script
```

## Lifecycle Script Template

```bash
# Create script
cat > lifecycle.sh << 'EOF'
#!/bin/bash
set -e

sudo -u ec2-user -i <<'USEREOF'
source /home/ec2-user/anaconda3/bin/activate JupyterSystemEnv
pip install pandas numpy scikit-learn
source /home/ec2-user/anaconda3/bin/deactivate
USEREOF
EOF

# Encode for Terraform
base64 lifecycle.sh

# Use in terraform.tfvars:
# lifecycle_config_on_create = "BASE64_OUTPUT_HERE"
```

## VPC Endpoints Checklist

For private subnets, ensure these endpoints exist:

- [ ] **S3** (Gateway) - `com.amazonaws.REGION.s3`
- [ ] **SageMaker API** (Interface) - `com.amazonaws.REGION.sagemaker.api`
- [ ] **SageMaker Runtime** (Interface) - `com.amazonaws.REGION.sagemaker.runtime`
- [ ] **EC2** (Interface) - `com.amazonaws.REGION.ec2`
- [ ] **CloudWatch Logs** (Interface) - `com.amazonaws.REGION.logs` (optional)
- [ ] **ECR API** (Interface) - `com.amazonaws.REGION.ecr.api` (optional)
- [ ] **ECR Docker** (Interface) - `com.amazonaws.REGION.ecr.dkr` (optional)

## Quick Troubleshooting

### Notebook won't start
```bash
# 1. Check VPC endpoints
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=YOUR_VPC_ID"

# 2. Check logs
aws logs tail /aws/sagemaker/NotebookInstances/$NB_NAME --follow

# 3. Verify security group
terraform output security_group_id
```

### Can't access S3
```bash
# 1. Verify S3 bucket ARNs include both bucket and bucket/*
# 2. Check S3 VPC endpoint exists
# 3. Test from notebook terminal:
aws s3 ls s3://bucket-name/
```

### Lifecycle script fails
```bash
# 1. Check CloudWatch logs
# 2. Add debugging: set -ex
# 3. Test script locally before encoding
```

## File Structure

```
.
├── main.tf                     # SageMaker notebook resource
├── iam.tf                      # IAM roles and policies
├── security_groups.tf          # Security group configuration
├── variables.tf                # Input variables
├── outputs.tf                  # Output values
├── versions.tf                 # Terraform and provider versions
├── terraform.tfvars.example    # Example configuration
├── vpc_endpoints_example.tf    # VPC endpoints example (optional)
├── README.md                   # Full documentation
├── DEPLOYMENT_GUIDE.md         # Step-by-step deployment guide
└── QUICK_REFERENCE.md          # This file
```

## Security Best Practices Checklist

- [ ] Use private subnets (`direct_internet_access = "Disabled"`)
- [ ] Disable root access (`root_access = "Disabled"`)
- [ ] Enable KMS encryption (`kms_key_id = "arn:..."`)
- [ ] Use IMDSv2 (default in this config)
- [ ] Apply least privilege IAM permissions
- [ ] Enable CloudWatch logging
- [ ] Use VPC endpoints (no internet gateway)
- [ ] Apply security group restrictions
- [ ] Use permissions boundaries if required
- [ ] Tag all resources

## Common Modifications

### Change instance type
```hcl
# In terraform.tfvars:
instance_type = "ml.m5.xlarge"
```
```bash
terraform apply
```

### Add S3 bucket access
```hcl
# In terraform.tfvars:
s3_bucket_arns = [
  "arn:aws:s3:::bucket1",
  "arn:aws:s3:::bucket2"  # Add new bucket
]
```
```bash
terraform apply
```

### Increase volume size
```hcl
# In terraform.tfvars:
volume_size = 50  # Increase from 10 to 50
```
```bash
terraform apply
```

### Add lifecycle script
```hcl
# In terraform.tfvars:
create_lifecycle_config = true
lifecycle_config_on_start = base64encode(<<-EOF
  #!/bin/bash
  set -e
  echo "Starting notebook"
EOF
)
```
```bash
terraform apply
```

## Cost Estimates (Monthly*)

Based on 730 hours/month (24/7 operation):

- **ml.t3.medium**: ~$37/month
- **ml.t3.xlarge**: ~$139/month
- **ml.m5.xlarge**: ~$168/month
- **ml.m5.2xlarge**: ~$336/month
- **ml.p3.2xlarge**: ~$2,234/month

*Plus storage costs: ~$0.10/GB/month

**Save costs by stopping instances when not in use!**

## AWS CLI Configuration

```bash
# Configure AWS CLI
aws configure

# Set default region
export AWS_DEFAULT_REGION=us-east-1

# Use specific profile
export AWS_PROFILE=your-profile

# Test connection
aws sts get-caller-identity
```

## Terraform State Management

```bash
# View state
terraform show

# List resources
terraform state list

# Show specific resource
terraform state show aws_sagemaker_notebook_instance.this

# Import existing resource
terraform import aws_sagemaker_notebook_instance.this notebook-name

# Remove resource from state
terraform state rm aws_sagemaker_notebook_instance.this
```

## Tags Reference

```hcl
default_tags = {
  Project     = "ML Project"
  Environment = "Development"
  ManagedBy   = "Terraform"
  Owner       = "Data Science Team"
  CostCenter  = "ML-001"
}
```

## Environment-Specific Configs

### Development
```hcl
instance_type = "ml.t3.medium"
volume_size   = 10
root_access   = "Enabled"
cloudwatch_logs_retention_days = 7
```

### Production
```hcl
instance_type = "ml.m5.xlarge"
volume_size   = 50
root_access   = "Disabled"
kms_key_id    = "arn:aws:kms:..."
cloudwatch_logs_retention_days = 90
iam_role_permissions_boundary = "arn:aws:iam::..."
```

## Useful Snippets

### Get all notebook info
```bash
aws sagemaker describe-notebook-instance \
  --notebook-instance-name $NB_NAME \
  --output table
```

### Watch logs in real-time
```bash
aws logs tail \
  /aws/sagemaker/NotebookInstances/$NB_NAME \
  --follow \
  --format short
```

### List all SageMaker resources
```bash
aws sagemaker list-notebook-instances
aws sagemaker list-training-jobs
aws sagemaker list-models
aws sagemaker list-endpoints
```

### Export Terraform outputs to env vars
```bash
export NB_NAME=$(terraform output -raw notebook_instance_name)
export SG_ID=$(terraform output -raw security_group_id)
export ROLE_ARN=$(terraform output -raw iam_role_arn)
```

## Support Resources

- **AWS SageMaker Docs**: https://docs.aws.amazon.com/sagemaker/
- **Terraform Registry**: https://registry.terraform.io/providers/hashicorp/aws/
- **AWS CLI Reference**: https://awscli.amazonaws.com/v2/documentation/api/latest/reference/sagemaker/
- **VPC Endpoints**: https://docs.aws.amazon.com/vpc/latest/privatelink/

## Emergency Procedures

### Notebook is stuck/unresponsive
```bash
# 1. Stop the notebook
aws sagemaker stop-notebook-instance --notebook-instance-name $NB_NAME

# 2. Wait for it to stop
aws sagemaker wait notebook-instance-stopped --notebook-instance-name $NB_NAME

# 3. Start it again
aws sagemaker start-notebook-instance --notebook-instance-name $NB_NAME
```

### Need to recover data
```bash
# Data in /home/ec2-user/SageMaker is persisted
# Ensure you regularly backup to S3:
aws s3 sync /home/ec2-user/SageMaker/ s3://your-backup-bucket/notebooks/
```

### Complete rebuild
```bash
# Destroy and recreate
terraform destroy
terraform apply
```

**Note:** This will delete all local data. Ensure backups exist!

