# Git Repository Setup for SageMaker Notebooks

This guide explains how to configure Git access in your SageMaker notebook instance.

## What Changed

I've added the following features to enable Git repository access:

### 1. IAM Permissions
- **CodeCommit Access**: Full Git operations for AWS CodeCommit repositories
- **Secrets Manager Access**: Retrieve Git credentials stored in AWS Secrets Manager
- Both are **enabled by default** in the configuration

### 2. Security Group Rules
- **HTTPS Egress (443)**: Required for Git operations over HTTPS (GitHub, GitLab, Bitbucket, CodeCommit)
- **SSH Egress (22)**: Optional, for Git operations over SSH (disabled by default)

### 3. Configuration Variables
```hcl
enable_git_access             = true   # Enable Git permissions
enable_git_ssh                = false  # Enable SSH (port 22)
enable_secrets_manager_access = true   # Enable Secrets Manager for credentials
codecommit_repository_arns    = null   # Specific repos or null for all
secrets_manager_secret_arns   = null   # Specific secrets or null for auto-detect
```

## Why It Wasn't Working Before

Your Terraform-created notebook was missing:

1. ✅ **IAM permissions** for CodeCommit and Secrets Manager
2. ✅ **Security group egress rule** for HTTPS to Git servers (port 443 to internet)

The Console creates notebooks with a more permissive default IAM role that includes these permissions.

## Git Integration Options

### Option 1: Use SageMaker's Built-in Git Integration (Recommended)

Configure Git repositories directly in the Terraform configuration:

```hcl
# In terraform.tfvars:
default_code_repository = "https://github.com/username/repo-name"

# Or multiple repositories:
additional_code_repositories = [
  "https://github.com/username/repo1",
  "https://github.com/username/repo2"
]
```

This will automatically clone repositories to the notebook instance.

### Option 2: AWS CodeCommit (AWS Native)

For AWS CodeCommit repositories:

```hcl
# In terraform.tfvars:
enable_git_access = true

# Optional: Restrict to specific repositories
codecommit_repository_arns = [
  "arn:aws:codecommit:us-east-1:123456789012:my-ml-repo"
]

# Use the repository
default_code_repository = "https://git-codecommit.us-east-1.amazonaws.com/v1/repos/my-ml-repo"
```

**No credentials needed** - IAM role handles authentication automatically!

### Option 3: GitHub/GitLab with HTTPS (Using Secrets Manager)

For private repositories on GitHub, GitLab, or Bitbucket:

#### Step 1: Store credentials in Secrets Manager

```bash
# Create a secret for GitHub personal access token
aws secretsmanager create-secret \
  --name github-token-for-sagemaker \
  --description "GitHub PAT for SageMaker notebooks" \
  --secret-string '{"username":"your-username","password":"your-personal-access-token"}'
```

#### Step 2: Configure in Terraform

```hcl
# In terraform.tfvars:
enable_secrets_manager_access = true

# Optional: Specify exact secret ARN
secrets_manager_secret_arns = [
  "arn:aws:secretsmanager:us-east-1:123456789012:secret:github-token-for-sagemaker-xxxxx"
]
```

#### Step 3: Clone in Notebook

From the notebook terminal:

```bash
cd /home/ec2-user/SageMaker

# Get credentials from Secrets Manager
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id github-token-for-sagemaker \
  --query SecretString --output text)

USERNAME=$(echo $SECRET | jq -r .username)
TOKEN=$(echo $SECRET | jq -r .password)

# Clone with credentials
git clone https://${USERNAME}:${TOKEN}@github.com/username/repo-name.git
```

### Option 4: GitHub/GitLab with SSH

For SSH-based Git access:

#### Step 1: Enable SSH in Terraform

```hcl
# In terraform.tfvars:
enable_git_ssh = true  # Enables port 22 egress
```

#### Step 2: Set up SSH keys using Lifecycle Configuration

```hcl
# In terraform.tfvars:
create_lifecycle_config = true

lifecycle_config_on_create = base64encode(<<-EOF
#!/bin/bash
set -e

# Setup SSH keys for ec2-user
sudo -u ec2-user -i <<'USEREOF'

# Get SSH private key from Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id github-ssh-key \
  --query SecretString \
  --output text > /home/ec2-user/.ssh/id_rsa

chmod 600 /home/ec2-user/.ssh/id_rsa

# Add GitHub to known hosts
ssh-keyscan github.com >> /home/ec2-user/.ssh/known_hosts

# Configure git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

USEREOF
EOF
)
```

#### Step 3: Store SSH key in Secrets Manager

```bash
# Create a secret with your SSH private key
aws secretsmanager create-secret \
  --name github-ssh-key \
  --description "SSH private key for GitHub" \
  --secret-string file://~/.ssh/id_rsa
```

## Configuration Examples

### Example 1: Public GitHub Repository

```hcl
# terraform.tfvars
enable_git_access = true

# No authentication needed for public repos
default_code_repository = "https://github.com/username/public-repo"
```

Then apply:
```bash
terraform apply
```

### Example 2: Private GitHub Repository with Personal Access Token

**Step 1:** Create GitHub PAT
- Go to GitHub → Settings → Developer settings → Personal access tokens
- Generate new token with `repo` scope

**Step 2:** Store in Secrets Manager
```bash
aws secretsmanager create-secret \
  --name github-ml-notebooks \
  --secret-string '{"username":"myusername","password":"ghp_xxxxxxxxxxxx"}'
```

**Step 3:** Configure Terraform
```hcl
# terraform.tfvars
enable_git_access = true
enable_secrets_manager_access = true
secrets_manager_secret_arns = [
  "arn:aws:secretsmanager:us-east-1:123456789012:secret:github-ml-notebooks-xxxxx"
]
```

**Step 4:** Apply and clone
```bash
terraform apply
```

From notebook terminal:
```bash
# Helper function to clone with credentials
clone_private_repo() {
  REPO_URL=$1
  SECRET_NAME=$2
  
  SECRET=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query SecretString --output text)
  USERNAME=$(echo $SECRET | jq -r .username)
  TOKEN=$(echo $SECRET | jq -r .password)
  
  # Convert https://github.com/user/repo to https://TOKEN@github.com/user/repo
  AUTH_URL=$(echo $REPO_URL | sed "s|https://|https://${USERNAME}:${TOKEN}@|")
  git clone $AUTH_URL
}

# Usage
cd /home/ec2-user/SageMaker
clone_private_repo "https://github.com/myorg/private-ml-repo" "github-ml-notebooks"
```

### Example 3: AWS CodeCommit Repository

```hcl
# terraform.tfvars
enable_git_access = true

# CodeCommit repository
default_code_repository = "https://git-codecommit.us-east-1.amazonaws.com/v1/repos/ml-experiments"

# Optional: restrict to specific repos
codecommit_repository_arns = [
  "arn:aws:codecommit:us-east-1:123456789012:ml-experiments"
]
```

Apply and the repository will be automatically cloned to `/home/ec2-user/SageMaker/`

### Example 4: Multiple Repositories

```hcl
# terraform.tfvars
enable_git_access = true

default_code_repository = "https://github.com/myorg/ml-models"

additional_code_repositories = [
  "https://github.com/myorg/ml-datasets",
  "https://github.com/myorg/ml-utils"
]
```

All repositories will be cloned automatically on notebook start.

## Troubleshooting

### Issue 1: Cannot Clone GitHub Repository

**Error:** `fatal: could not read Username` or `403 Forbidden`

**Solution:**

1. Verify Git access is enabled:
```bash
terraform output iam_role_arn
aws iam get-role-policy \
  --role-name $(terraform output -raw iam_role_name) \
  --policy-name "*git*"
```

2. Check security group allows HTTPS egress:
```bash
aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=$(terraform output -raw security_group_id)" \
  --query 'SecurityGroupRules[?CidrIpv4==`0.0.0.0/0` && ToPort==`443`]'
```

3. Ensure you're using HTTPS (not SSH) or enable SSH:
```hcl
enable_git_ssh = true  # In terraform.tfvars
```

### Issue 2: CodeCommit Access Denied

**Error:** `fatal: unable to access 'https://git-codecommit...': The requested URL returned error: 403`

**Solution:**

1. Verify IAM permissions:
```bash
# From notebook terminal
aws sts get-caller-identity

# Check CodeCommit access
aws codecommit list-repositories
```

2. Ensure the repository ARN is included (or use `null` for all repos):
```hcl
codecommit_repository_arns = null  # Allow all repos
```

3. Verify AWS region matches:
```bash
# Repository URL must match your configured region
# If in us-east-1, use:
https://git-codecommit.us-east-1.amazonaws.com/v1/repos/your-repo
```

### Issue 3: Secrets Manager Access Denied

**Error:** `An error occurred (AccessDeniedException) when calling the GetSecretValue operation`

**Solution:**

1. Enable Secrets Manager access:
```hcl
enable_secrets_manager_access = true
```

2. Check the secret name/ARN matches:
```bash
# List secrets
aws secretsmanager list-secrets

# Test access
aws secretsmanager get-secret-value --secret-id your-secret-name
```

3. Verify secret naming pattern:
The default configuration allows secrets with `*git*` or `*sagemaker*` in the name.

### Issue 4: SSH Clone Fails

**Error:** `ssh: connect to host github.com port 22: Connection timed out`

**Solution:**

1. Enable SSH in security group:
```hcl
enable_git_ssh = true
```

2. Apply changes:
```bash
terraform apply
```

3. Verify SSH egress is allowed:
```bash
aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=$(terraform output -raw security_group_id)" \
  --query 'SecurityGroupRules[?ToPort==`22`]'
```

## Best Practices

### 1. Use HTTPS Instead of SSH
- Easier to manage credentials via Secrets Manager
- No need to manage SSH keys
- Works better with private subnets
- Recommended: Set `enable_git_ssh = false` (default)

### 2. Use CodeCommit for AWS-Native Workflows
- No credential management needed
- Automatic IAM authentication
- VPC endpoint support
- Best for private subnet deployments

### 3. Store Credentials in Secrets Manager
- Never hardcode credentials
- Use Secrets Manager for GitHub/GitLab tokens
- Rotate credentials regularly
- Use IAM to control access

### 4. Use Lifecycle Configuration for Git Setup
```hcl
lifecycle_config_on_start = base64encode(<<-EOF
#!/bin/bash
set -e

sudo -u ec2-user -i <<'USEREOF'
# Configure git on every start
git config --global user.name "ML Team"
git config --global user.email "ml@company.com"

# Pull latest changes in existing repos
cd /home/ec2-user/SageMaker
for dir in */; do
  if [ -d "$dir/.git" ]; then
    cd "$dir"
    git pull
    cd ..
  fi
done
USEREOF
EOF
)
```

### 5. Automate Repository Cloning
Create a helper script in lifecycle config:
```bash
#!/bin/bash
# Auto-clone script for lifecycle configuration

sudo -u ec2-user -i <<'USEREOF'
cd /home/ec2-user/SageMaker

# Function to clone if not exists
clone_if_needed() {
  REPO_URL=$1
  REPO_NAME=$(basename $REPO_URL .git)
  
  if [ ! -d "$REPO_NAME" ]; then
    git clone $REPO_URL
  else
    cd $REPO_NAME
    git pull
    cd ..
  fi
}

# Clone your repositories
clone_if_needed "https://github.com/myorg/ml-experiments"
clone_if_needed "https://github.com/myorg/ml-utils"

USEREOF
```

## Quick Reference

### Enable Git Access (Already Done!)
```hcl
enable_git_access = true  # ✅ Enabled by default
```

### Clone Public Repository
```bash
cd /home/ec2-user/SageMaker
git clone https://github.com/username/public-repo
```

### Clone Private Repository (with Secrets Manager)
```bash
SECRET=$(aws secretsmanager get-secret-value --secret-id my-git-secret --query SecretString --output text)
USERNAME=$(echo $SECRET | jq -r .username)
TOKEN=$(echo $SECRET | jq -r .password)
git clone https://${USERNAME}:${TOKEN}@github.com/username/private-repo
```

### Clone CodeCommit Repository
```bash
cd /home/ec2-user/SageMaker
git clone https://git-codecommit.us-east-1.amazonaws.com/v1/repos/my-repo
# No credentials needed - IAM handles it!
```

### Check Git Configuration
```bash
# Verify Git is installed
git --version

# Check Git config
git config --list

# Test network access to GitHub
curl -I https://github.com

# Test Secrets Manager access
aws secretsmanager list-secrets
```

## Next Steps

1. **Apply the updated configuration:**
```bash
terraform apply
```

2. **Test Git access from your notebook:**
- Open notebook instance
- Open terminal
- Try cloning a repository

3. **Set up credentials if needed:**
- For public repos: No setup needed
- For CodeCommit: Already configured via IAM
- For private GitHub/GitLab: Store credentials in Secrets Manager

4. **Optional: Configure automatic cloning:**
- Add repositories to `default_code_repository` or `additional_code_repositories`
- Create lifecycle configuration for auto-pull on start

## Summary of Changes

The updated Terraform configuration now includes:

✅ **CodeCommit permissions** - Full Git operations on AWS CodeCommit
✅ **Secrets Manager permissions** - Access credentials for private repos  
✅ **HTTPS egress** - Security group rule for Git over HTTPS (port 443)
✅ **Optional SSH egress** - Can be enabled for Git over SSH (port 22)
✅ **Configurable scope** - Restrict to specific repositories or secrets

Your notebooks can now clone Git repositories just like Console-created notebooks! 🎉

