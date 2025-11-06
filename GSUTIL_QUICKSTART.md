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

