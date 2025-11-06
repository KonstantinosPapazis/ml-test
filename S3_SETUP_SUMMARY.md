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

