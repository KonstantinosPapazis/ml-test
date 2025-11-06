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

