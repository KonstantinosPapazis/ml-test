#!/usr/bin/env python3
"""
Google Cloud Storage to S3 Migration Script
===========================================

This script demonstrates how to:
1. Install and use gsutil in your SageMaker notebook
2. Download datasets from Google Cloud Storage
3. Upload them to your S3 buckets

Prerequisites:
- Google Cloud credentials (if accessing private GCS buckets)
- AWS credentials (automatically configured in SageMaker notebooks)
- Deployed S3 buckets from Terraform

Usage:
    Run this in your Jupyter notebook or as a standalone script:
    
    In Jupyter:
    %run gcs_to_s3_migration.py
    
    From terminal:
    python gcs_to_s3_migration.py
"""

import os
import sys
import subprocess
import boto3
import shutil
from pathlib import Path


class GCStoS3Migrator:
    """Migrate data from Google Cloud Storage to AWS S3"""
    
    def __init__(self, datasets_bucket=None, models_bucket=None):
        """
        Initialize migrator
        
        Args:
            datasets_bucket (str): S3 datasets bucket name (from terraform output)
            models_bucket (str): S3 models bucket name (from terraform output)
        """
        self.s3_client = boto3.client('s3')
        self.datasets_bucket = datasets_bucket
        self.models_bucket = models_bucket
        
        # Auto-discover buckets if not provided
        if not datasets_bucket or not models_bucket:
            self._discover_buckets()
    
    def _discover_buckets(self):
        """Auto-discover S3 buckets created by Terraform"""
        response = self.s3_client.list_buckets()
        
        print("Discovering S3 buckets...")
        for bucket in response['Buckets']:
            name = bucket['Name']
            if 'dataset' in name.lower():
                self.datasets_bucket = self.datasets_bucket or name
                print(f"  Found datasets bucket: {name}")
            elif 'model' in name.lower():
                self.models_bucket = self.models_bucket or name
                print(f"  Found models bucket: {name}")
        
        if not self.datasets_bucket:
            print("⚠️  Warning: No datasets bucket found. Please specify manually.")
        if not self.models_bucket:
            print("⚠️  Warning: No models bucket found. Please specify manually.")
    
    def install_gsutil(self):
        """Install gsutil if not already installed"""
        print("Installing gsutil...")
        try:
            subprocess.run(['gsutil', 'version'], 
                         capture_output=True, check=True)
            print("✅ gsutil is already installed")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("Installing gsutil via pip...")
            subprocess.run([sys.executable, '-m', 'pip', 'install', 
                          'gsutil', '--quiet'], check=True)
            print("✅ gsutil installed successfully")
        
        # Verify installation
        result = subprocess.run(['gsutil', 'version'], 
                              capture_output=True, text=True)
        print(f"gsutil version: {result.stdout.strip()}")
    
    def download_from_gcs(self, gcs_uri, local_dir='/tmp/gcs_downloads'):
        """
        Download data from Google Cloud Storage
        
        Args:
            gcs_uri (str): GCS URI (e.g., 'gs://bucket-name/path/to/file')
            local_dir (str): Local directory to download to
            
        Returns:
            str: Path to downloaded directory
        """
        os.makedirs(local_dir, exist_ok=True)
        
        print(f"\n📥 Downloading from {gcs_uri}...")
        try:
            subprocess.run(
                ['gsutil', '-m', 'cp', '-r', gcs_uri, local_dir],
                check=True
            )
            print("✅ Download complete")
            
            # Show downloaded files
            print(f"\nDownloaded files in {local_dir}:")
            for file in os.listdir(local_dir):
                file_path = os.path.join(local_dir, file)
                size = os.path.getsize(file_path)
                print(f"  - {file} ({size:,} bytes)")
            
            return local_dir
        
        except subprocess.CalledProcessError as e:
            print(f"❌ Error downloading from GCS: {e}")
            raise
    
    def upload_to_s3(self, local_directory, s3_bucket, s3_prefix='raw/'):
        """
        Upload files from local directory to S3
        
        Args:
            local_directory (str): Local directory containing files
            s3_bucket (str): Target S3 bucket name
            s3_prefix (str): S3 key prefix (default: 'raw/')
        """
        if not s3_bucket:
            raise ValueError("S3 bucket not specified")
        
        print(f"\n📤 Uploading to s3://{s3_bucket}/{s3_prefix}...")
        
        uploaded_files = []
        for root, dirs, files in os.walk(local_directory):
            for file in files:
                local_path = os.path.join(root, file)
                relative_path = os.path.relpath(local_path, local_directory)
                s3_key = f"{s3_prefix}{relative_path}"
                
                print(f"  Uploading {relative_path}...")
                self.s3_client.upload_file(local_path, s3_bucket, s3_key)
                uploaded_files.append(s3_key)
        
        print(f"✅ Upload complete! {len(uploaded_files)} files uploaded")
        return uploaded_files
    
    def verify_s3_upload(self, bucket, prefix):
        """
        Verify files were uploaded to S3
        
        Args:
            bucket (str): S3 bucket name
            prefix (str): S3 key prefix
        """
        print(f"\n📋 Verifying files in s3://{bucket}/{prefix}:")
        
        response = self.s3_client.list_objects_v2(
            Bucket=bucket,
            Prefix=prefix
        )
        
        total_size = 0
        for obj in response.get('Contents', []):
            size = obj['Size']
            total_size += size
            print(f"  - {obj['Key']} ({size:,} bytes)")
        
        print(f"\nTotal: {len(response.get('Contents', []))} files, "
              f"{total_size:,} bytes ({total_size / 1024 / 1024:.2f} MB)")
    
    def migrate(self, gcs_uri, s3_prefix='raw/', 
                temp_dir='/tmp/gcs_migration', cleanup=True):
        """
        Complete migration from GCS to S3
        
        Args:
            gcs_uri (str): GCS URI to download from
            s3_prefix (str): S3 prefix to upload to (default: 'raw/')
            temp_dir (str): Temporary local directory
            cleanup (bool): Whether to clean up temp files after upload
            
        Returns:
            list: S3 keys of uploaded files
        """
        if not self.datasets_bucket:
            raise ValueError(
                "Datasets bucket not found. Please specify manually:\n"
                "  migrator = GCStoS3Migrator(datasets_bucket='your-bucket-name')"
            )
        
        try:
            # Download from GCS
            self.download_from_gcs(gcs_uri, temp_dir)
            
            # Upload to S3
            uploaded_files = self.upload_to_s3(
                temp_dir, 
                self.datasets_bucket, 
                s3_prefix
            )
            
            # Verify
            self.verify_s3_upload(self.datasets_bucket, s3_prefix)
            
            return uploaded_files
        
        finally:
            if cleanup and os.path.exists(temp_dir):
                shutil.rmtree(temp_dir)
                print(f"\n🧹 Cleaned up temporary directory: {temp_dir}")


def example_usage():
    """Example usage of the GCS to S3 migrator"""
    
    print("=" * 60)
    print("GCS to S3 Migration Example")
    print("=" * 60)
    
    # Initialize migrator (auto-discovers S3 buckets)
    migrator = GCStoS3Migrator()
    
    # Or specify buckets manually:
    # migrator = GCStoS3Migrator(
    #     datasets_bucket='my-project-dev-datasets',
    #     models_bucket='my-project-dev-models'
    # )
    
    # Install gsutil
    migrator.install_gsutil()
    
    # Example: Download and migrate a public dataset
    # Replace with your actual GCS URI
    gcs_uri = 'gs://your-gcs-bucket/path/to/dataset.csv'
    
    print(f"\n{'='*60}")
    print("To migrate data from GCS to S3, use:")
    print(f"{'='*60}")
    print(f"""
# Migrate a single file
migrator.migrate(
    gcs_uri='gs://your-gcs-bucket/path/to/dataset.csv',
    s3_prefix='raw/'
)

# Migrate an entire directory
migrator.migrate(
    gcs_uri='gs://your-gcs-bucket/datasets/*',
    s3_prefix='raw/datasets/'
)

# Migrate without cleanup (keep local copies)
migrator.migrate(
    gcs_uri='gs://your-gcs-bucket/data/',
    s3_prefix='raw/',
    cleanup=False
)
""")
    
    print(f"\n{'='*60}")
    print("After migration, access data from S3 using pandas:")
    print(f"{'='*60}")
    print(f"""
import pandas as pd

# Read from S3
df = pd.read_csv('s3://{migrator.datasets_bucket}/raw/dataset.csv')

# Or using boto3
import boto3
s3 = boto3.client('s3')
s3.download_file(
    Bucket='{migrator.datasets_bucket}',
    Key='raw/dataset.csv',
    Filename='/tmp/dataset.csv'
)
""")


def quick_install_gsutil():
    """Quick function to just install gsutil"""
    print("Installing gsutil...")
    try:
        subprocess.run(['gsutil', 'version'], 
                     capture_output=True, check=True)
        print("✅ gsutil is already installed")
    except (subprocess.CalledProcessError, FileNotFoundError):
        subprocess.run([sys.executable, '-m', 'pip', 'install', 
                      'gsutil', '--quiet'], check=True)
        print("✅ gsutil installed successfully")
    
    # Show version
    result = subprocess.run(['gsutil', 'version'], 
                          capture_output=True, text=True)
    print(f"\n{result.stdout}")


if __name__ == '__main__':
    # Run example usage
    example_usage()
    
    print(f"\n{'='*60}")
    print("Ready to migrate! Import this module in your notebook:")
    print(f"{'='*60}")
    print("""
from gcs_to_s3_migration import GCStoS3Migrator, quick_install_gsutil

# Quick install gsutil
quick_install_gsutil()

# Create migrator and migrate data
migrator = GCStoS3Migrator()
migrator.migrate('gs://your-gcs-bucket/path/to/data', s3_prefix='raw/')
""")

