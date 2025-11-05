# Pushing Docker Images to ECR from SageMaker Notebook

This guide explains how to build and push Docker images to Amazon ECR from your SageMaker notebook instance.

## Prerequisites

You have **two options** for network connectivity:

### Option 1: VPC Endpoints (Recommended ✅)

**Required VPC Endpoints:**
1. ✅ **ECR API** (`com.amazonaws.region.ecr.api`)
2. ✅ **ECR Docker** (`com.amazonaws.region.ecr.dkr`)
3. ✅ **S3** (`com.amazonaws.region.s3`)

**These are already configured in `vpc_endpoints_example.tf`!**

### Option 2: Internet Access

Enable via:
- NAT Gateway (for private subnets)
- `direct_internet_access = "Enabled"` (for public subnets)

## Comparison: VPC Endpoints vs Internet Access

| Aspect | VPC Endpoints | Internet Access (NAT) |
|--------|--------------|----------------------|
| **Security** | ✅ Traffic stays in AWS | ⚠️ Traffic via internet |
| **Speed** | ✅ Faster (AWS backbone) | Depends on NAT capacity |
| **Cost** | ~$22/month (3 endpoints) | ~$32/month + $0.045/GB transfer |
| **Compliance** | ✅ Often required | May not meet requirements |
| **Setup** | VPC endpoints needed | NAT gateway needed |
| **Recommended for** | Production | Development (if NAT exists) |

## Network Configuration

### Using VPC Endpoints (Recommended)

```hcl
# terraform.tfvars

# Private subnet configuration
direct_internet_access = "Disabled"
subnet_id              = "subnet-private-xxx"

# VPC endpoints across multiple AZs for high availability
vpc_endpoint_subnet_ids = [
  "subnet-private-1a",
  "subnet-private-1b",
  "subnet-private-1c"
]

# Enable VPC endpoint creation (in vpc_endpoints_example.tf)
# Uncomment the ECR API, ECR DKR, and S3 endpoint resources
```

### Using NAT Gateway

```hcl
# terraform.tfvars

# Private subnet with NAT gateway
direct_internet_access = "Disabled"
subnet_id              = "subnet-private-with-nat-xxx"

# No VPC endpoints needed
# Your VPC must have a NAT gateway configured
```

### Using Public Subnet (Not Recommended for Production)

```hcl
# terraform.tfvars

# Public subnet with internet gateway
direct_internet_access = "Enabled"
subnet_id              = "subnet-public-xxx"
```

## IAM Permissions

I've already configured **full ECR push/pull permissions** in the IAM role!

**Included Actions:**
- ✅ `ecr:GetAuthorizationToken` - Authenticate to ECR
- ✅ `ecr:PutImage` - Push images
- ✅ `ecr:InitiateLayerUpload` - Start upload
- ✅ `ecr:UploadLayerPart` - Upload layers
- ✅ `ecr:CompleteLayerUpload` - Finish upload
- ✅ `ecr:CreateRepository` - Create new repos
- ✅ `ecr:BatchGetImage` - Pull images
- ✅ `ecr:GetDownloadUrlForLayer` - Download layers

### Restrict to Specific Repositories (Optional)

```hcl
# terraform.tfvars

# Allow push to all ECR repos in your account
ecr_repository_arns = null  # Default

# Or restrict to specific repositories
ecr_repository_arns = [
  "arn:aws:ecr:us-east-1:123456789012:repository/my-ml-app",
  "arn:aws:ecr:us-east-1:123456789012:repository/my-training-image"
]
```

## Step-by-Step: Pushing Docker Images

### 1. Create ECR Repository (if needed)

From your notebook terminal:

```bash
# Set your region and repo name
REGION=us-east-1
REPO_NAME=my-ml-app

# Create ECR repository
aws ecr create-repository \
  --repository-name $REPO_NAME \
  --region $REGION \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256
```

### 2. Build Your Docker Image

```bash
# Navigate to your code directory
cd /home/ec2-user/SageMaker/my-project

# Build Docker image
docker build -t $REPO_NAME:latest .

# Verify image was built
docker images
```

### 3. Authenticate to ECR

```bash
# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Login to ECR
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
```

You should see: `Login Succeeded`

### 4. Tag and Push Image

```bash
# Tag image for ECR
docker tag $REPO_NAME:latest \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest

# Push to ECR
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest
```

### 5. Verify Upload

```bash
# List images in repository
aws ecr describe-images \
  --repository-name $REPO_NAME \
  --region $REGION
```

## Complete Example Script

Save this as `/home/ec2-user/SageMaker/push-to-ecr.sh`:

```bash
#!/bin/bash
set -e

# Configuration
REGION=${AWS_REGION:-us-east-1}
REPO_NAME=${1:-"my-ml-app"}
IMAGE_TAG=${2:-"latest"}

echo "================================================"
echo "Building and pushing Docker image to ECR"
echo "Repository: $REPO_NAME"
echo "Tag: $IMAGE_TAG"
echo "Region: $REGION"
echo "================================================"

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: $ACCOUNT_ID"

# Create repository if it doesn't exist
echo ""
echo "Creating ECR repository (if needed)..."
aws ecr create-repository \
  --repository-name $REPO_NAME \
  --region $REGION \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256 \
  2>/dev/null || echo "Repository already exists"

# Build Docker image
echo ""
echo "Building Docker image..."
docker build -t $REPO_NAME:$IMAGE_TAG .

# Login to ECR
echo ""
echo "Logging in to ECR..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Tag image
echo ""
echo "Tagging image..."
docker tag $REPO_NAME:$IMAGE_TAG \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG

# Push to ECR
echo ""
echo "Pushing image to ECR..."
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG

# Verify
echo ""
echo "Image pushed successfully!"
echo "Image URI: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG"
echo ""
echo "Verifying..."
aws ecr describe-images \
  --repository-name $REPO_NAME \
  --region $REGION \
  --query 'imageDetails[0].[imageTags[0],imageSizeInBytes,imagePushedAt]' \
  --output table

echo ""
echo "✅ Done!"
```

Make it executable:
```bash
chmod +x /home/ec2-user/SageMaker/push-to-ecr.sh
```

Usage:
```bash
# Push with defaults
./push-to-ecr.sh

# Specify repo name
./push-to-ecr.sh my-custom-app

# Specify repo name and tag
./push-to-ecr.sh my-custom-app v1.0.0
```

## Dockerfile Example

Here's a sample Dockerfile for ML applications:

```dockerfile
# Base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Run the application
CMD ["python", "app.py"]
```

## Troubleshooting

### Issue 1: Cannot Connect to ECR

**Error:** `dial tcp: lookup on xxx: no such host` or timeout

**Solutions:**

#### If using VPC endpoints:
```bash
# 1. Verify VPC endpoints exist
aws ec2 describe-vpc-endpoints \
  --filters "Name=service-name,Values=com.amazonaws.$REGION.ecr.api" \
  --query 'VpcEndpoints[*].VpcEndpointId'

aws ec2 describe-vpc-endpoints \
  --filters "Name=service-name,Values=com.amazonaws.$REGION.ecr.dkr" \
  --query 'VpcEndpoints[*].VpcEndpointId'

# 2. Verify private DNS is enabled
aws ec2 describe-vpc-endpoints \
  --filters "Name=service-name,Values=com.amazonaws.$REGION.ecr.api" \
  --query 'VpcEndpoints[*].PrivateDnsEnabled'

# Should return: true
```

#### If using NAT gateway:
```bash
# 1. Verify route table has route to NAT
aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=YOUR_SUBNET_ID"

# Should show a route to NAT gateway (nat-xxxxx) for 0.0.0.0/0
```

### Issue 2: Access Denied Pushing to ECR

**Error:** `denied: User: arn:aws:sts::xxx:assumed-role/xxx is not authorized to perform: ecr:PutImage`

**Solutions:**

```bash
# 1. Verify IAM role has permissions
aws iam get-role-policy \
  --role-name $(terraform output -raw iam_role_name) \
  --policy-name "*ecr*"

# 2. Try specific repository ARN
# In terraform.tfvars:
ecr_repository_arns = [
  "arn:aws:ecr:us-east-1:YOUR_ACCOUNT:repository/YOUR_REPO"
]

# 3. Apply changes
terraform apply
```

### Issue 3: Docker Not Installed

**Error:** `bash: docker: command not found`

**Solution:**

```bash
# Install Docker on the notebook instance
# Add to lifecycle configuration:

#!/bin/bash
set -e

# Install Docker
sudo yum update -y
sudo yum install -y docker

# Start Docker service
sudo service docker start

# Add ec2-user to docker group
sudo usermod -a -G docker ec2-user

# Enable Docker to start on boot
sudo chkconfig docker on
```

Add this to your lifecycle config:

```hcl
# In terraform.tfvars
create_lifecycle_config = true

lifecycle_config_on_create = base64encode(<<-EOF
#!/bin/bash
set -e

# Install Docker
sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo chkconfig docker on

echo "Docker installed successfully"
docker --version
EOF
)
```

### Issue 4: S3 Layer Upload Fails

**Error:** `error uploading layer: Put https://xxx.s3.amazonaws.com/...`

**Cause:** Missing S3 VPC endpoint or S3 access

**Solutions:**

```bash
# 1. Verify S3 endpoint exists (if using VPC endpoints)
aws ec2 describe-vpc-endpoints \
  --filters "Name=service-name,Values=com.amazonaws.$REGION.s3"

# 2. Verify security group allows HTTPS
aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=$(terraform output -raw security_group_id)" \
  --query 'SecurityGroupRules[?ToPort==`443`]'
```

## Cost Estimation

### VPC Endpoints (Recommended)
- **ECR API endpoint:** ~$7.50/month
- **ECR DKR endpoint:** ~$7.50/month
- **S3 Gateway endpoint:** FREE
- **Data processing:** $0.01/GB
- **Total:** ~$15-22/month depending on usage

### NAT Gateway
- **NAT Gateway:** ~$32/month (24/7)
- **Data transfer:** $0.045/GB
- **Total:** $32-50+/month depending on traffic

**Recommendation:** For production and regular Docker builds, VPC endpoints are more cost-effective and secure!

## Best Practices

### 1. Use VPC Endpoints in Production
```hcl
# Enable all required endpoints
# See vpc_endpoints_example.tf
```

### 2. Tag Images Properly
```bash
# Use semantic versioning
docker tag app:latest $ECR_URI:v1.2.3
docker tag app:latest $ECR_URI:latest

# Push both tags
docker push $ECR_URI:v1.2.3
docker push $ECR_URI:latest
```

### 3. Enable Image Scanning
```bash
aws ecr put-image-scanning-configuration \
  --repository-name $REPO_NAME \
  --image-scanning-configuration scanOnPush=true
```

### 4. Use Lifecycle Policies
```bash
# Keep only last 10 images
aws ecr put-lifecycle-policy \
  --repository-name $REPO_NAME \
  --lifecycle-policy-text '{
    "rules": [{
      "rulePriority": 1,
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }]
  }'
```

### 5. Automate Builds with Lifecycle Config
```hcl
lifecycle_config_on_start = base64encode(<<-EOF
#!/bin/bash
set -e
sudo -u ec2-user -i <<'USEREOF'

# Auto-build if Dockerfile changed
cd /home/ec2-user/SageMaker/my-project
if [ -f Dockerfile ]; then
  # Check if Dockerfile is newer than last image
  if [ Dockerfile -nt .last-build ]; then
    echo "Dockerfile changed, rebuilding..."
    ./push-to-ecr.sh
    touch .last-build
  fi
fi

USEREOF
EOF
)
```

## Summary

### What You Need

✅ **IAM Permissions** - Already configured!
✅ **Network Access** - Choose one:
   - **VPC Endpoints** (ECR API + ECR DKR + S3) ← Recommended
   - **NAT Gateway** or **Internet Gateway**

### Recommended Setup

```hcl
# terraform.tfvars

# Use private subnet
direct_internet_access = "Disabled"
subnet_id              = "subnet-private-xxx"

# Deploy VPC endpoints (use vpc_endpoints_example.tf)
vpc_endpoint_subnet_ids = [
  "subnet-private-1a",
  "subnet-private-1b",
  "subnet-private-1c"
]

# ECR access for all repos
ecr_repository_arns = null

# Install Docker on notebook creation
create_lifecycle_config = true
lifecycle_config_on_create = base64encode(<<-EOF
#!/bin/bash
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user
EOF
)
```

### Quick Start

1. **Deploy with VPC endpoints:**
```bash
terraform apply
```

2. **Test Docker and ECR:**
```bash
# SSH to notebook terminal
docker --version
aws ecr describe-repositories
```

3. **Build and push:**
```bash
./push-to-ecr.sh my-app
```

Done! 🎉

