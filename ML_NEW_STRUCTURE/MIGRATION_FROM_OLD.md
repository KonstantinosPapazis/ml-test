# Migration Guide: Old Structure → New Structure

This guide helps you migrate from the monolithic structure (single module) to the new modular structure (shared infrastructure + multiple notebooks).

## Comparison

### Old Structure (Monolithic)
```
ml-test/
├── main.tf                 # Single notebook instance
├── iam.tf                  # IAM role for one notebook
├── s3.tf                   # S3 buckets for one notebook
├── security_groups.tf      # Security group for one notebook
├── vpc_endpoints_example.tf
├── variables.tf            # All variables
├── outputs.tf              # All outputs
└── terraform.tfvars        # Configuration for one notebook

Problem: To add a second notebook, you need to:
- Duplicate all files
- Manage separate S3 buckets
- Pay for duplicate VPC endpoints
- Manage separate IAM roles
```

### New Structure (Modular)
```
ML_NEW_STRUCTURE/
├── shared-infra/          # Deploy once
│   ├── s3/               # Shared S3 buckets
│   ├── iam/              # Shared IAM role
│   ├── security-groups/  # Shared security groups
│   └── vpc-endpoints/    # Shared VPC endpoints
└── notebooks/             # Deploy many
    ├── notebook-dev/
    ├── notebook-prod/
    └── notebook-X/        # Easy to add more!

Benefit: Add notebooks without duplicating infrastructure!
```

## Key Differences

| Aspect | Old Structure | New Structure |
|--------|--------------|---------------|
| **S3 Buckets** | Per notebook | Shared by all |
| **IAM Role** | Per notebook | Shared by all |
| **VPC Endpoints** | Per notebook | Shared by all |
| **Security Groups** | Per notebook | Shared by all |
| **Add Notebook** | Copy & modify all files | Copy one directory |
| **Update Permissions** | Update each notebook | Update once, affects all |
| **Cost (3 notebooks)** | ~$195/month | ~$149/month |
| **Scalability** | Poor | Excellent |

## Migration Options

### Option 1: Fresh Deployment (Recommended)

**Best for**: New projects or when you can recreate notebooks

1. **Deploy new structure** (see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md))
2. **Migrate data from old S3 to new S3**:
   ```bash
   aws s3 sync s3://old-bucket s3://new-bucket
   ```
3. **Destroy old infrastructure**:
   ```bash
   cd ../old-structure
   terraform destroy
   ```

**Pros:**
- Clean start
- No state migration complexity
- Test before switching

**Cons:**
- Brief downtime during migration
- Need to recreate notebooks

### Option 2: Import Existing Resources

**Best for**: When you must avoid recreation

1. **Deploy new structure but don't create resources**
2. **Import existing resources**:
   ```bash
   # Import S3 buckets
   cd shared-infra/s3
   terraform import aws_s3_bucket.datasets your-existing-bucket-name
   
   # Import IAM role
   cd ../iam
   terraform import aws_iam_role.sagemaker_shared your-existing-role-name
   
   # Import security groups
   cd ../security-groups
   terraform import aws_security_group.sagemaker_notebook sg-xxxxx
   
   # Import notebooks
   cd ../../notebooks/notebook-dev
   terraform import module.notebook.aws_sagemaker_notebook_instance.this your-notebook-name
   ```

**Pros:**
- No recreation
- No downtime
- Keep existing notebooks

**Cons:**
- Complex
- Requires careful state management
- Risk of errors

### Option 3: Parallel Deployment

**Best for**: Testing before full migration

1. **Deploy new structure alongside old**
2. **Test with new notebooks**
3. **Migrate data gradually**
4. **Destroy old structure when ready**

**Pros:**
- No downtime
- Test thoroughly
- Gradual migration

**Cons:**
- Temporary duplicate costs
- Data synchronization needed

## Step-by-Step: Fresh Deployment Migration

### Phase 1: Prepare (No Changes Yet)

1. **Document current setup**:
   ```bash
   cd old-structure
   terraform output > old-outputs.txt
   ```

2. **Backup S3 data**:
   ```bash
   aws s3 sync s3://old-datasets-bucket ./backup-datasets/
   aws s3 sync s3://old-models-bucket ./backup-models/
   ```

3. **Export notebook configurations** (instance type, volume size, etc.)

### Phase 2: Deploy New Infrastructure

1. **Deploy shared infrastructure**:
   ```bash
   cd ML_NEW_STRUCTURE/shared-infra/s3
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with NEW bucket names
   terraform init && terraform apply
   
   cd ../iam
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars
   terraform init && terraform apply
   
   cd ../security-groups
   cp terraform.tfvars.example terraform.tfvars
   # Use SAME vpc_id as old structure
   terraform init && terraform apply
   
   cd ../vpc-endpoints
   cp terraform.tfvars.example terraform.tfvars
   # Use SAME vpc_id and subnets as old structure
   terraform init && terraform apply
   ```

2. **Migrate S3 data**:
   ```bash
   # Get new bucket names
   cd shared-infra/s3
   terraform output datasets_bucket_name  # Get new bucket name
   
   # Sync data from old to new
   aws s3 sync s3://old-datasets-bucket s3://new-datasets-bucket
   aws s3 sync s3://old-models-bucket s3://new-models-bucket
   ```

3. **Verify data migration**:
   ```bash
   aws s3 ls s3://new-datasets-bucket --recursive | wc -l
   aws s3 ls s3://old-datasets-bucket --recursive | wc -l
   # Count should match
   ```

### Phase 3: Deploy New Notebooks

1. **Stop old notebooks** (to avoid conflicts):
   ```bash
   aws sagemaker stop-notebook-instance \
     --notebook-instance-name old-notebook-name
   ```

2. **Deploy new notebooks**:
   ```bash
   cd notebooks/notebook-dev
   cp terraform.tfvars.example terraform.tfvars
   # Use SAME subnet_id, instance_type as old notebook
   # Use NEW iam_role_arn from shared-infra/iam
   # Use NEW security_group_ids from shared-infra/security-groups
   terraform init && terraform apply
   ```

3. **Test new notebook**:
   - Open notebook in AWS Console
   - Test S3 access
   - Test Git access (if configured)
   - Run test workload

### Phase 4: Cleanup Old Infrastructure

1. **Verify everything works** in new structure

2. **Destroy old infrastructure**:
   ```bash
   cd old-structure
   
   # Optional: Keep old S3 buckets for a while
   # Comment out S3 bucket resources in s3.tf
   
   terraform destroy
   ```

3. **Verify cleanup**:
   ```bash
   aws sagemaker list-notebook-instances
   # Should only show new notebooks
   
   aws ec2 describe-vpc-endpoints
   # Should show new VPC endpoints
   ```

## Mapping Old to New

### Variables Mapping

| Old Variable | New Location |
|--------------|--------------|
| `datasets_bucket_name` | `shared-infra/s3/terraform.tfvars` |
| `models_bucket_name` | `shared-infra/s3/terraform.tfvars` |
| `iam_role_name` | `shared-infra/iam/terraform.tfvars` |
| `notebook_sg_name` | `shared-infra/security-groups/terraform.tfvars` |
| `instance_type` | `notebooks/notebook-X/terraform.tfvars` |
| `subnet_id` | `notebooks/notebook-X/terraform.tfvars` |

### Outputs Mapping

| Old Output | New Location |
|------------|--------------|
| `datasets_bucket_name` | `cd shared-infra/s3 && terraform output` |
| `iam_role_arn` | `cd shared-infra/iam && terraform output` |
| `security_group_id` | `cd shared-infra/security-groups && terraform output` |
| `notebook_url` | `cd notebooks/notebook-X && terraform output` |

### Files Mapping

| Old File | New Location |
|----------|--------------|
| `s3.tf` | `shared-infra/s3/main.tf` |
| `iam.tf` | `shared-infra/iam/main.tf` |
| `security_groups.tf` | `shared-infra/security-groups/main.tf` |
| `vpc_endpoints_example.tf` | `shared-infra/vpc-endpoints/main.tf` |
| `main.tf` (notebook) | `modules/sagemaker-notebook/main.tf` |

## Conversion Example

### Old: Single terraform.tfvars
```hcl
# Old structure - everything in one file
project_name = "ml-project"
environment  = "dev"
vpc_id       = "vpc-xxxxx"
subnet_id    = "subnet-xxxxx"

# S3 buckets
create_datasets_bucket = true
datasets_bucket_name = "ml-project-dev-datasets"

# Notebook
instance_type = "ml.t3.medium"
volume_size   = 10
```

### New: Split Across Multiple Files

**shared-infra/s3/terraform.tfvars:**
```hcl
datasets_bucket_name = "ml-project-datasets"  # No env suffix - shared!
models_bucket_name = "ml-project-models"
```

**shared-infra/iam/terraform.tfvars:**
```hcl
iam_role_name = "ml-project-notebooks-role"  # Shared role
s3_bucket_arns = [
  "arn:aws:s3:::ml-project-datasets",
  "arn:aws:s3:::ml-project-models"
]
```

**notebooks/notebook-dev/terraform.tfvars:**
```hcl
project_name = "ml-project"
environment  = "dev"
subnet_id    = "subnet-xxxxx"
instance_type = "ml.t3.medium"
volume_size   = 10

# Reference shared infrastructure (from outputs)
iam_role_arn = "arn:aws:iam::123456789012:role/ml-project-notebooks-role"
security_group_ids = ["sg-xxxxx"]
```

## Common Issues During Migration

### Issue 1: State Conflicts

**Problem**: "Resource already exists"

**Solution**: 
```bash
# Option A: Import
terraform import aws_s3_bucket.datasets existing-bucket-name

# Option B: Remove from old state
cd old-structure
terraform state rm aws_s3_bucket.datasets
```

### Issue 2: Bucket Name Already Exists

**Problem**: S3 bucket names are globally unique

**Solution**: Use different bucket names in new structure:
```hcl
# Old
datasets_bucket_name = "ml-project-dev-datasets"

# New
datasets_bucket_name = "ml-project-shared-datasets"
```

### Issue 3: VPC Endpoint Conflicts

**Problem**: Can't have duplicate VPC endpoints

**Solution**: Destroy old VPC endpoints first:
```bash
cd old-structure
terraform destroy -target=aws_vpc_endpoint.s3
terraform destroy -target=aws_vpc_endpoint.sagemaker_api
```

### Issue 4: IAM Role Name Conflict

**Problem**: IAM role names must be unique

**Solution**: Use different role name:
```hcl
# Old
iam_role_name = "sagemaker-dev-role"

# New
iam_role_name = "sagemaker-notebooks-shared-role"
```

## Testing Checklist

After migration, verify:

- [ ] Can access new notebook via AWS Console
- [ ] Can read from new S3 datasets bucket
- [ ] Can write to new S3 datasets bucket
- [ ] Can read/write to models bucket
- [ ] CloudWatch logs are working
- [ ] Git repository access works (if configured)
- [ ] Can import common ML libraries
- [ ] Can run sample ML workflow
- [ ] All team members have access

## Rollback Plan

If migration fails:

1. **Keep old infrastructure running** during migration
2. **Document any issues** encountered
3. **To rollback**:
   ```bash
   # Start old notebooks
   aws sagemaker start-notebook-instance \
     --notebook-instance-name old-notebook
   
   # Destroy new infrastructure
   cd ML_NEW_STRUCTURE
   # Destroy notebooks
   cd notebooks/notebook-dev && terraform destroy
   # Destroy shared infra
   cd ../../shared-infra/vpc-endpoints && terraform destroy
   cd ../security-groups && terraform destroy
   cd ../iam && terraform destroy
   cd ../s3 && terraform destroy
   ```

## Timeline Estimate

| Phase | Time | Downtime |
|-------|------|----------|
| Preparation | 1 hour | None |
| Deploy shared infra | 30 mins | None |
| Migrate S3 data | 1-4 hours* | None |
| Deploy new notebooks | 15 mins each | Yes** |
| Testing | 1 hour | None |
| Cleanup | 30 mins | None |

*Depends on data size  
**Only for notebooks being replaced

## Cost During Migration

**Parallel deployment** (both old and new running):
- Duration: 1 day
- Extra cost: ~$5-10 (temporary duplicate VPC endpoints and notebooks)

**Fresh deployment** (destroy old, create new):
- Duration: Few hours
- Extra cost: $0 (brief downtime)

## Post-Migration Benefits

After migration, you'll have:

1. ✅ **Lower costs**: ~24% savings with 3 notebooks, more with additional notebooks
2. ✅ **Easier management**: Update permissions once, affects all
3. ✅ **Faster deployment**: Add new notebooks in < 5 minutes
4. ✅ **Better collaboration**: Shared data, consistent environment
5. ✅ **Scalability**: Add unlimited notebooks without infrastructure overhead

## Next Steps

1. Choose migration option (Fresh Deployment recommended)
2. Follow phase-by-phase guide above
3. Test thoroughly before cleanup
4. Document any customizations
5. Train team on new structure

## Support

- **Migration issues**: Contact your team lead or AWS support
- **Terraform questions**: See Terraform documentation
- **Architecture questions**: See [README.md](README.md)
- **Deployment help**: See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

**Recommendation**: Use **Fresh Deployment** for clean migration. Total time: ~4-6 hours including testing.

