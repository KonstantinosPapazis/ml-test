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

