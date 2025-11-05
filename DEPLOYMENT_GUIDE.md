# SageMaker Notebook Deployment Guide

This guide will walk you through deploying a production-ready SageMaker notebook instance in a private subnet.

## Prerequisites Checklist

Before deploying, ensure you have:

- [ ] AWS CLI configured with appropriate credentials
- [ ] Terraform >= 1.0 installed
- [ ] VPC with private subnets created
- [ ] VPC endpoints configured (see VPC Endpoints section below)
- [ ] S3 buckets created for ML data/models
- [ ] Required subnet IDs and VPC information

## Step-by-Step Deployment

### Step 1: Clone or Initialize

```bash
cd /path/to/ml-test
```

### Step 2: Set Up VPC Endpoints (Critical for Private Subnets)

VPC endpoints are required for SageMaker notebook instances in private subnets. You can either:

**Option A: Use the provided example**
```bash
# Review and customize vpc_endpoints_example.tf
# Then uncomment the resources you need
```

**Option B: Use existing VPC endpoints**
- Ensure you have S3, SageMaker API, SageMaker Runtime, and EC2 endpoints
- Verify security groups allow traffic from your SageMaker notebook

**Option C: Create manually via AWS Console**
1. Go to VPC → Endpoints
2. Create the following endpoints:
   - `com.amazonaws.region.s3` (Gateway type)
   - `com.amazonaws.region.sagemaker.api` (Interface type)
   - `com.amazonaws.region.sagemaker.runtime` (Interface type)
   - `com.amazonaws.region.ec2` (Interface type)

### Step 3: Configure Variables

```bash
# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars
```

**Minimum Required Variables:**

```hcl
# Basic Configuration
aws_region   = "us-east-1"
project_name = "my-ml-project"
environment  = "dev"

# Network Configuration (REQUIRED)
vpc_id         = "vpc-xxxxxxxxx"      # Your VPC ID
subnet_id      = "subnet-xxxxxxxxx"   # Private subnet ID
vpc_cidr_block = "10.0.0.0/16"        # Your VPC CIDR

# S3 Access (REQUIRED)
s3_bucket_arns = [
  "arn:aws:s3:::your-ml-data-bucket",
  "arn:aws:s3:::your-ml-models-bucket"
]
```

### Step 4: Validate Configuration

```bash
# Initialize Terraform
terraform init

# Validate the configuration
terraform validate

# Format the files
terraform fmt

# Review the plan
terraform plan
```

### Step 5: Deploy

```bash
# Apply the configuration
terraform apply

# Review the changes and type 'yes' to confirm
```

### Step 6: Verify Deployment

```bash
# Check outputs
terraform output

# Get the notebook name
terraform output notebook_instance_name

# Check notebook status
aws sagemaker describe-notebook-instance \
  --notebook-instance-name $(terraform output -raw notebook_instance_name)
```

### Step 7: Access Your Notebook

1. **Via AWS Console:**
   - Navigate to Amazon SageMaker → Notebook instances
   - Find your notebook instance
   - Click "Open JupyterLab" or "Open Jupyter"

2. **Via AWS CLI (Get Presigned URL):**
   ```bash
   aws sagemaker create-presigned-notebook-instance-url \
     --notebook-instance-name $(terraform output -raw notebook_instance_name)
   ```

## Configuration Scenarios

### Scenario 1: Simple Development Environment

```hcl
# terraform.tfvars
aws_region   = "us-east-1"
project_name = "ml-dev"
environment  = "dev"

instance_type = "ml.t3.medium"  # Cost-effective
volume_size   = 10

vpc_id         = "vpc-xxx"
subnet_id      = "subnet-private-xxx"
vpc_cidr_block = "10.0.0.0/16"

direct_internet_access = "Disabled"
root_access            = "Disabled"

s3_bucket_arns = ["arn:aws:s3:::ml-dev-data"]
```

### Scenario 2: Production Environment with Encryption

```hcl
# terraform.tfvars
aws_region   = "us-east-1"
project_name = "ml-prod"
environment  = "prod"

instance_type = "ml.m5.xlarge"  # More powerful
volume_size   = 50

vpc_id         = "vpc-xxx"
subnet_id      = "subnet-private-xxx"
vpc_cidr_block = "10.1.0.0/16"

direct_internet_access = "Disabled"
root_access            = "Disabled"

# Encryption
kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/xxx"

# Compliance
iam_role_permissions_boundary = "arn:aws:iam::123456789012:policy/OrgBoundary"

# Extended logging
cloudwatch_logs_retention_days = 90

s3_bucket_arns = [
  "arn:aws:s3:::ml-prod-data",
  "arn:aws:s3:::ml-prod-models"
]

default_tags = {
  Environment = "Production"
  Compliance  = "Required"
  DataClass   = "Sensitive"
}
```

### Scenario 3: GPU Training Environment

```hcl
# terraform.tfvars
aws_region   = "us-east-1"
project_name = "ml-training"
environment  = "dev"

instance_type = "ml.p3.2xlarge"  # GPU instance
volume_size   = 100

vpc_id         = "vpc-xxx"
subnet_id      = "subnet-private-xxx"
vpc_cidr_block = "10.0.0.0/16"

# Lifecycle configuration for GPU setup
create_lifecycle_config = true
lifecycle_config_on_create = base64encode(<<-EOF
  #!/bin/bash
  set -e
  sudo -u ec2-user -i <<'USEREOF'
  source /home/ec2-user/anaconda3/bin/activate pytorch_p39
  pip install --upgrade pip
  pip install torch torchvision torchaudio transformers accelerate
  source /home/ec2-user/anaconda3/bin/deactivate
  USEREOF
EOF
)

s3_bucket_arns = [
  "arn:aws:s3:::ml-training-data",
  "arn:aws:s3:::ml-model-artifacts"
]
```

## VPC Endpoints Setup Guide

### Required VPC Endpoints for Private Subnets

#### 1. S3 Gateway Endpoint (Required)

```bash
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxx \
  --service-name com.amazonaws.us-east-1.s3 \
  --route-table-ids rtb-xxx
```

#### 2. SageMaker API Interface Endpoint (Required)

```bash
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxx \
  --vpc-endpoint-type Interface \
  --service-name com.amazonaws.us-east-1.sagemaker.api \
  --subnet-ids subnet-xxx \
  --security-group-ids sg-xxx
```

#### 3. SageMaker Runtime Interface Endpoint (Required)

```bash
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxx \
  --vpc-endpoint-type Interface \
  --service-name com.amazonaws.us-east-1.sagemaker.runtime \
  --subnet-ids subnet-xxx \
  --security-group-ids sg-xxx
```

#### 4. EC2 Interface Endpoint (Required)

```bash
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxx \
  --vpc-endpoint-type Interface \
  --service-name com.amazonaws.us-east-1.ec2 \
  --subnet-ids subnet-xxx \
  --security-group-ids sg-xxx
```

### Verify VPC Endpoints

```bash
# List all VPC endpoints
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=vpc-xxx"

# Check S3 endpoint
aws ec2 describe-vpc-endpoints \
  --filters "Name=service-name,Values=com.amazonaws.us-east-1.s3"

# Check SageMaker API endpoint
aws ec2 describe-vpc-endpoints \
  --filters "Name=service-name,Values=com.amazonaws.us-east-1.sagemaker.api"
```

## Common Issues and Solutions

### Issue 1: Notebook Instance Fails to Start

**Symptoms:**
- Instance stuck in "Pending" state
- Fails to create after several minutes

**Solutions:**

1. Check VPC endpoints exist:
   ```bash
   aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=YOUR_VPC_ID"
   ```

2. Verify security group rules:
   ```bash
   # Check the created security group
   terraform output security_group_id
   
   aws ec2 describe-security-groups --group-ids $(terraform output -raw security_group_id)
   ```

3. Check CloudWatch logs:
   ```bash
   aws logs tail /aws/sagemaker/NotebookInstances/$(terraform output -raw notebook_instance_name) --follow
   ```

4. Verify IAM role permissions:
   ```bash
   terraform output iam_role_arn
   ```

### Issue 2: Cannot Access S3 Buckets

**Symptoms:**
- S3 operations fail from notebook
- "Access Denied" errors

**Solutions:**

1. Verify S3 bucket ARNs in terraform.tfvars:
   ```hcl
   s3_bucket_arns = [
     "arn:aws:s3:::bucket-name",
     "arn:aws:s3:::bucket-name/*"  # Don't forget the /* suffix
   ]
   ```

2. Check S3 VPC endpoint:
   ```bash
   aws ec2 describe-vpc-endpoints \
     --filters "Name=service-name,Values=com.amazonaws.${REGION}.s3"
   ```

3. Test from notebook terminal:
   ```bash
   aws s3 ls s3://your-bucket-name/
   ```

### Issue 3: Lifecycle Configuration Fails

**Symptoms:**
- Notebook starts but lifecycle script fails
- Custom packages not installed

**Solutions:**

1. Check CloudWatch logs for script errors:
   ```bash
   aws logs tail /aws/sagemaker/NotebookInstances/$(terraform output -raw notebook_instance_name) --follow
   ```

2. Test script locally before base64 encoding:
   ```bash
   # Create test script
   cat > test_script.sh << 'EOF'
   #!/bin/bash
   set -e
   echo "Testing script..."
   EOF
   
   # Test it
   bash test_script.sh
   
   # Encode for Terraform
   base64 test_script.sh
   ```

3. Add debugging to lifecycle script:
   ```bash
   #!/bin/bash
   set -ex  # Enable debug output
   
   # Your commands here
   ```

### Issue 4: Cannot Connect to VPC Endpoints

**Symptoms:**
- Cannot reach AWS services
- Timeouts when calling AWS APIs

**Solutions:**

1. Verify private DNS is enabled:
   ```bash
   aws ec2 describe-vpc-endpoints --query 'VpcEndpoints[*].{ID:VpcEndpointId,Service:ServiceName,DNS:PrivateDnsEnabled}'
   ```

2. Check security group for VPC endpoints allows HTTPS (443) from notebook security group

3. Verify subnet has route to VPC endpoint

## Maintenance Operations

### Update Instance Type

```bash
# Edit terraform.tfvars
instance_type = "ml.m5.2xlarge"

# Apply changes
terraform apply
```

**Note:** This will stop and restart the notebook instance.

### Add S3 Bucket Access

```bash
# Edit terraform.tfvars - add bucket ARN
s3_bucket_arns = [
  "arn:aws:s3:::existing-bucket",
  "arn:aws:s3:::new-bucket"
]

# Apply changes
terraform apply
```

### Increase Volume Size

```bash
# Edit terraform.tfvars
volume_size = 50

# Apply changes
terraform apply
```

**Note:** Volume size can only be increased, not decreased.

### Update Lifecycle Configuration

```bash
# Edit terraform.tfvars with new lifecycle script
lifecycle_config_on_start = base64encode(<<-EOF
  #!/bin/bash
  # New script
EOF
)

# Apply changes
terraform apply
```

## Stopping and Starting the Notebook

### Stop Notebook (to save costs)

```bash
aws sagemaker stop-notebook-instance \
  --notebook-instance-name $(terraform output -raw notebook_instance_name)
```

### Start Notebook

```bash
aws sagemaker start-notebook-instance \
  --notebook-instance-name $(terraform output -raw notebook_instance_name)
```

### Check Status

```bash
aws sagemaker describe-notebook-instance \
  --notebook-instance-name $(terraform output -raw notebook_instance_name) \
  --query 'NotebookInstanceStatus'
```

## Clean Up

### Destroy All Resources

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy resources
terraform destroy
```

**Warning:** This will delete the notebook instance and all local data. Ensure important work is saved to S3.

## Cost Optimization Tips

1. **Stop instances when not in use:**
   - Use AWS Lambda to automatically stop instances after idle time
   - Manually stop during non-working hours

2. **Choose appropriate instance types:**
   - Start with smaller instances (ml.t3.medium)
   - Scale up only when needed

3. **Monitor costs:**
   ```bash
   # Estimate monthly cost
   # ml.t3.medium: ~$37/month (730 hours)
   # ml.m5.xlarge: ~$168/month
   # ml.p3.2xlarge: ~$2,235/month
   ```

4. **Use lifecycle configurations to clean up:**
   - Delete temporary files
   - Clear conda caches
   - Remove unused kernels

## Security Checklist

- [ ] Deployed in private subnet (no direct internet access)
- [ ] Root access disabled
- [ ] VPC endpoints configured
- [ ] Security groups follow least privilege
- [ ] IAM role has minimum required permissions
- [ ] KMS encryption enabled for sensitive data
- [ ] CloudWatch logging enabled
- [ ] Tags applied for cost tracking
- [ ] Permissions boundary applied (if required)
- [ ] IMDSv2 enforced

## Support and Resources

- **AWS SageMaker Documentation:** https://docs.aws.amazon.com/sagemaker/
- **Terraform AWS Provider:** https://registry.terraform.io/providers/hashicorp/aws/
- **VPC Endpoints Guide:** https://docs.aws.amazon.com/vpc/latest/privatelink/
- **CloudWatch Logs:** `/aws/sagemaker/NotebookInstances/[instance-name]`

## Next Steps

After deployment:

1. Access the notebook via AWS Console
2. Create a test notebook to verify S3 access
3. Install additional packages if needed
4. Configure Git integration for version control
5. Set up regular backups to S3
6. Create lifecycle configurations for your workflow
7. Configure IAM policies for team access

## Useful Commands

```bash
# Get all outputs
terraform output

# Get notebook URL
aws sagemaker create-presigned-notebook-instance-url \
  --notebook-instance-name $(terraform output -raw notebook_instance_name)

# View CloudWatch logs
aws logs tail /aws/sagemaker/NotebookInstances/$(terraform output -raw notebook_instance_name) --follow

# Check notebook status
aws sagemaker describe-notebook-instance \
  --notebook-instance-name $(terraform output -raw notebook_instance_name)

# List all SageMaker notebooks
aws sagemaker list-notebook-instances

# Update Terraform state
terraform refresh

# Show Terraform state
terraform show
```

