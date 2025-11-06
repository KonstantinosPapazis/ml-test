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

