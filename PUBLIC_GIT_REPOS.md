# Cloning Public Git Repositories - Requirements Guide

This guide clarifies what's **actually required** to clone public Git repositories (GitHub, GitLab, Bitbucket) from your SageMaker notebook.

## TL;DR

**For public repos, you only need:**
1. ✅ HTTPS egress (port 443) to the internet
2. ❌ NO CodeCommit IAM permissions needed
3. ❌ NO Secrets Manager permissions needed

## Network Configuration Options

### Option 1: Public Subnet (Simplest)

If your notebook is in a **public subnet** with an internet gateway:

```hcl
# terraform.tfvars
direct_internet_access = "Enabled"
subnet_id              = "subnet-public-xxx"

# Git permissions not needed for public repos
enable_git_access             = false
enable_secrets_manager_access = false
```

✅ **Works automatically** - Internet gateway provides connectivity
✅ **No additional IAM permissions needed**

### Option 2: Private Subnet with NAT Gateway

If your notebook is in a **private subnet** with a NAT gateway:

```hcl
# terraform.tfvars
direct_internet_access = "Disabled"
subnet_id              = "subnet-private-xxx"

# Git permissions not needed for public repos
enable_git_access             = false
enable_secrets_manager_access = false
```

✅ **Works automatically** - NAT gateway provides internet access
✅ **No additional IAM permissions needed**
⚠️  NAT gateway must be configured in your VPC (not part of this Terraform)

### Option 3: Private Subnet WITHOUT NAT Gateway

If your notebook is in a **private subnet** with **NO NAT gateway**, you need to allow HTTPS egress:

```hcl
# terraform.tfvars
direct_internet_access = "Disabled"
subnet_id              = "subnet-private-xxx"

# Need security group rule for HTTPS to internet
enable_git_access = true  # ⚠️ Needed for security group rule, NOT for IAM!

# But disable the IAM permissions (not needed for public repos)
enable_secrets_manager_access = false

# If only using GitHub/GitLab (not CodeCommit), you could also set:
# codecommit_repository_arns = []  # Restrict CodeCommit to no repos
```

⚠️ **Note:** `enable_git_access = true` creates both:
- Security group rule (HTTPS egress) ✅ Needed
- IAM permissions for CodeCommit ❌ Not needed for public repos

**Trade-off:** You get CodeCommit permissions you don't need, but it follows least-privilege and doesn't hurt.

## Minimal Configuration Examples

### Example 1: Public Subnet (Most Permissive)

```hcl
aws_region   = "us-east-1"
project_name = "ml-dev"
environment  = "dev"

instance_type = "ml.t3.medium"
volume_size   = 10

vpc_id         = "vpc-xxx"
subnet_id      = "subnet-public-xxx"
vpc_cidr_block = "10.0.0.0/16"

# Public subnet = internet access via IGW
direct_internet_access = "Enabled"

# No Git IAM permissions needed
enable_git_access             = false
enable_secrets_manager_access = false

# Auto-clone public repos
default_code_repository = "https://github.com/username/public-repo"

s3_bucket_arns = ["arn:aws:s3:::my-bucket"]
```

### Example 2: Private Subnet with NAT (Recommended for Production)

```hcl
aws_region   = "us-east-1"
project_name = "ml-prod"
environment  = "prod"

instance_type = "ml.m5.xlarge"
volume_size   = 50

vpc_id         = "vpc-xxx"
subnet_id      = "subnet-private-xxx"
vpc_cidr_block = "10.1.0.0/16"

# Private subnet, uses NAT gateway for internet
direct_internet_access = "Disabled"

# No Git IAM permissions needed (NAT handles connectivity)
enable_git_access             = false
enable_secrets_manager_access = false

# Auto-clone public repos
default_code_repository = "https://github.com/username/public-repo"

s3_bucket_arns = ["arn:aws:s3:::my-bucket"]
```

### Example 3: Private Subnet WITHOUT NAT

```hcl
aws_region   = "us-east-1"
project_name = "ml-dev"
environment  = "dev"

instance_type = "ml.t3.medium"
volume_size   = 10

vpc_id         = "vpc-xxx"
subnet_id      = "subnet-private-xxx"
vpc_cidr_block = "10.0.0.0/16"

# Private subnet, NO NAT gateway
direct_internet_access = "Disabled"

# Need HTTPS egress rule (created by enable_git_access)
enable_git_access = true  # Creates security group rule for HTTPS

# Don't need Secrets Manager for public repos
enable_secrets_manager_access = false

# Auto-clone public repos
default_code_repository = "https://github.com/username/public-repo"

s3_bucket_arns = ["arn:aws:s3:::my-bucket"]
```

## What Each Setting Does

### `enable_git_access = true`
**Creates:**
- ✅ Security group egress rule: HTTPS (443) to 0.0.0.0/0
- ✅ IAM permissions: CodeCommit operations

**Use when:**
- Private subnet without NAT gateway (need the security rule)
- Using AWS CodeCommit (need the IAM permissions)

### `enable_git_access = false`
**Skips:**
- ❌ Security group egress rule for Git
- ❌ IAM permissions for CodeCommit

**Use when:**
- Public subnet (has internet gateway)
- Private subnet with NAT gateway
- Only using public repos, never CodeCommit

### `enable_secrets_manager_access = true`
**Creates:**
- ✅ IAM permissions: Read secrets for Git credentials

**Use when:**
- Cloning private repositories from GitHub/GitLab
- Storing Git tokens in AWS Secrets Manager

### `enable_secrets_manager_access = false`
**Skips:**
- ❌ IAM permissions for Secrets Manager

**Use when:**
- Only cloning public repositories
- No private Git repos

### `direct_internet_access = "Enabled"`
**Creates:**
- ✅ Security group egress rule: All traffic to 0.0.0.0/0

**Use when:**
- Notebook is in public subnet with internet gateway
- Need full internet access

### `direct_internet_access = "Disabled"`
**Requires:**
- Private subnet configuration
- VPC endpoints OR NAT gateway OR specific egress rules

**Use when:**
- Production environments
- Security compliance requires private subnets
- Using VPC endpoints for AWS services

## Decision Matrix

| Setup | `direct_internet_access` | `enable_git_access` | `enable_secrets_manager_access` |
|-------|-------------------------|--------------------|---------------------------------|
| Public subnet + public repos | Enabled | false | false |
| Private subnet + NAT + public repos | Disabled | false | false |
| Private subnet + NO NAT + public repos | Disabled | **true** ⚠️ | false |
| Any setup + private GitHub/GitLab repos | Enabled/Disabled | true | **true** ✅ |
| Any setup + AWS CodeCommit | Disabled | **true** ✅ | false |

⚠️ = Needed for security group rule (IAM permissions are side effect)
✅ = Needed for IAM permissions

## Current Default Configuration

The current `terraform.tfvars.example` has:

```hcl
enable_git_access             = true   # Enabled (flexible, works for all scenarios)
enable_secrets_manager_access = true   # Enabled (in case you need private repos)
enable_git_ssh                = false  # Disabled (HTTPS is sufficient)
```

This is **intentionally permissive** to match AWS Console behavior and provide maximum flexibility.

## Recommendation

### For Development (Public Repos Only)
If you're certain you'll only use **public repositories**:

```hcl
# Minimal permissions
enable_git_access             = false  # If you have NAT or public subnet
enable_secrets_manager_access = false
```

### For Production (May Need Private Repos Later)
Keep the defaults (more permissive but flexible):

```hcl
# Default - flexible for future needs
enable_git_access             = true
enable_secrets_manager_access = true
```

The extra IAM permissions don't increase security risk since they're still scoped to:
- CodeCommit: Only Git operations on your repos
- Secrets Manager: Only secrets matching `*git*` or `*sagemaker*` patterns

## Testing

After deploying, test Git access:

```bash
# SSH into your notebook and open terminal

# Test 1: Check network connectivity
curl -I https://github.com

# Test 2: Clone a public repository
cd /home/ec2-user/SageMaker
git clone https://github.com/aws/amazon-sagemaker-examples.git

# Success! You should see the repository cloned.
```

## Summary

**The short answer to your question:**
- For **public Git repos**, you only need **HTTPS internet access** (via IGW, NAT, or security group rule)
- **CodeCommit and Secrets Manager permissions are NOT needed** for public repos
- I enabled them by default for flexibility, but you can disable them if you want minimal permissions

Use the configuration examples above based on your network setup! 🎯

