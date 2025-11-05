# Network Configuration Guide for SageMaker Notebooks

This guide explains the network configuration requirements and limitations for SageMaker notebook instances.

## Important: Single Subnet Limitation

⚠️ **SageMaker notebook instances only support a single subnet.**

Unlike services such as:
- Amazon RDS (Multi-AZ deployments)
- AWS Lambda (can span multiple subnets)
- Amazon ECS/EKS (tasks across multiple subnets)

A SageMaker notebook instance is a **single EC2 instance** that exists in **one subnet only**.

## What This Means

```hcl
# ✅ Correct - Single subnet
subnet_id = "subnet-xxxxxxxx"

# ❌ NOT SUPPORTED - Cannot use multiple subnets
# subnet_ids = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
```

## High Availability Strategies

Since notebooks can't span multiple subnets, here are strategies for reliability:

### 1. VPC Endpoints in Multiple Subnets (Recommended)

While the **notebook itself** is in one subnet, your **VPC endpoints** should be in multiple subnets for high availability:

```hcl
# terraform.tfvars

# Notebook is in ONE subnet
subnet_id = "subnet-private-us-east-1a"

# But VPC endpoints should be in MULTIPLE subnets for HA
vpc_endpoint_subnet_ids = [
  "subnet-private-us-east-1a",  # Same as notebook
  "subnet-private-us-east-1b",  # Different AZ
  "subnet-private-us-east-1c"   # Another AZ
]
```

**Why?** If one AZ has issues, your VPC endpoints in other AZs remain available.

### 2. Multiple Notebook Instances

For true high availability, deploy multiple notebook instances in different subnets:

```hcl
# Notebook 1 in us-east-1a
module "notebook_1" {
  source    = "./sagemaker-notebook"
  subnet_id = "subnet-private-us-east-1a"
  # ... other config
}

# Notebook 2 in us-east-1b
module "notebook_2" {
  source    = "sagemaker-notebook"
  subnet_id = "subnet-private-us-east-1b"
  # ... other config
}
```

### 3. Use Auto-Recovery Features

Enable CloudWatch alarms to monitor notebook health:

```hcl
resource "aws_cloudwatch_metric_alarm" "notebook_health" {
  alarm_name          = "${var.project_name}-notebook-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/SageMaker"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"

  dimensions = {
    NotebookInstanceName = aws_sagemaker_notebook_instance.this.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

## Multi-Subnet Configuration for VPC Endpoints

Let me create an enhanced VPC endpoints configuration:

### Update Variables

```hcl
# variables.tf (already updated)
variable "vpc_endpoint_subnet_ids" {
  description = "List of subnet IDs for VPC endpoints (use multiple for HA)"
  type        = list(string)
  default     = []
}
```

### Configuration Example

```hcl
# terraform.tfvars

# Network Configuration
vpc_id         = "vpc-12345678"
vpc_cidr_block = "10.0.0.0/16"

# Notebook instance - SINGLE subnet required
subnet_id = "subnet-private-1a"  # e.g., 10.0.1.0/24 in us-east-1a

# VPC Endpoints - MULTIPLE subnets recommended
vpc_endpoint_subnet_ids = [
  "subnet-private-1a",  # us-east-1a - 10.0.1.0/24
  "subnet-private-1b",  # us-east-1b - 10.0.2.0/24
  "subnet-private-1c"   # us-east-1c - 10.0.3.0/24
]
```

## Network Architecture Examples

### Example 1: Single AZ (Development)

```
VPC: 10.0.0.0/16
├── Availability Zone: us-east-1a
│   ├── Private Subnet: 10.0.1.0/24
│   │   ├── SageMaker Notebook ✓
│   │   └── VPC Endpoints ✓
│   └── Public Subnet: 10.0.11.0/24
│       └── NAT Gateway (if needed)
```

**Configuration:**
```hcl
subnet_id = "subnet-private-1a"
vpc_endpoint_subnet_ids = ["subnet-private-1a"]
```

**Pros:** Simple, lower cost
**Cons:** No AZ-level redundancy

### Example 2: Multi-AZ (Production - Recommended)

```
VPC: 10.0.0.0/16
├── Availability Zone: us-east-1a
│   ├── Private Subnet: 10.0.1.0/24
│   │   ├── SageMaker Notebook ✓
│   │   └── VPC Endpoints ✓
│   └── Public Subnet: 10.0.11.0/24
│       └── NAT Gateway A
├── Availability Zone: us-east-1b
│   ├── Private Subnet: 10.0.2.0/24
│   │   └── VPC Endpoints ✓
│   └── Public Subnet: 10.0.12.0/24
│       └── NAT Gateway B (optional)
└── Availability Zone: us-east-1c
    ├── Private Subnet: 10.0.3.0/24
    │   └── VPC Endpoints ✓
    └── Public Subnet: 10.0.13.0/24
        └── NAT Gateway C (optional)
```

**Configuration:**
```hcl
# Notebook is in one AZ
subnet_id = "subnet-private-1a"

# VPC endpoints span multiple AZs for redundancy
vpc_endpoint_subnet_ids = [
  "subnet-private-1a",
  "subnet-private-1b",
  "subnet-private-1c"
]
```

**Pros:** High availability for AWS service access
**Cons:** Higher cost (more VPC endpoint ENIs)

## What Can Use Multiple Subnets?

| Component | Multiple Subnets? | Why? |
|-----------|------------------|------|
| **SageMaker Notebook** | ❌ No | Single EC2 instance limitation |
| **VPC Endpoints (Interface)** | ✅ Yes | HA across availability zones |
| **VPC Endpoint (Gateway)** | N/A | Uses route tables, not subnets |
| **Security Groups** | ✅ Yes (multiple SGs) | Can attach multiple to notebook |
| **NAT Gateways** | ✅ Yes | One per AZ for redundancy |
| **SageMaker Training Jobs** | ✅ Yes | Can use multiple subnets |
| **SageMaker Endpoints** | ✅ Yes | Multi-AZ deployment |

## Security Groups (Multiple Supported!)

While you can't use multiple subnets, you **CAN** attach multiple security groups:

```hcl
# terraform.tfvars

# Create new security group
create_security_group = true

# ALSO attach additional existing security groups
additional_security_group_ids = [
  "sg-database-access",
  "sg-shared-services",
  "sg-monitoring-tools"
]
```

This is already supported in the current configuration!

## Best Practices

### 1. ✅ Deploy VPC Endpoints in Multiple Subnets

```hcl
# Even if notebook is in one subnet, spread VPC endpoints
vpc_endpoint_subnet_ids = [
  "subnet-private-1a",  # Notebook is here
  "subnet-private-1b",  # VPC endpoint redundancy
  "subnet-private-1c"   # More redundancy
]
```

### 2. ✅ Use Multiple NAT Gateways (if using NAT)

```hcl
# One NAT gateway per AZ for redundancy
# Configure in your VPC module
```

### 3. ✅ Backup Notebook Data to S3

```hcl
# Lifecycle config to backup automatically
lifecycle_config_on_stop = base64encode(<<-EOF
#!/bin/bash
set -e
sudo -u ec2-user -i <<'USEREOF'
# Backup notebooks to S3 on stop
aws s3 sync /home/ec2-user/SageMaker/ \
  s3://my-backup-bucket/notebooks/$(hostname)/ \
  --exclude ".git/*"
USEREOF
EOF
)
```

### 4. ✅ Use Infrastructure as Code

Keep your Terraform config so you can quickly recreate notebooks in different subnets if needed.

### 5. ✅ Consider SageMaker Studio Instead

If you need true multi-user, multi-AZ capabilities, consider:
- **SageMaker Studio** - Multi-user environment with better HA
- **JupyterHub on EKS** - Self-managed, full control

## Migration Between Subnets

If you need to move a notebook to a different subnet:

```bash
# 1. Backup your work
cd /home/ec2-user/SageMaker
git push  # or aws s3 sync

# 2. Update terraform.tfvars
# subnet_id = "subnet-new-one"

# 3. Apply changes
terraform apply

# Note: This will recreate the notebook instance
# The EBS volume persists, but verify your backups!
```

## Monitoring and Alerting

Since notebooks are single-AZ, monitor them closely:

```hcl
# CloudWatch alarm for instance health
resource "aws_cloudwatch_metric_alarm" "notebook_status" {
  alarm_name          = "${var.project_name}-notebook-status"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "NotebookInstanceStatus"
  namespace           = "AWS/SageMaker"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    NotebookInstanceName = aws_sagemaker_notebook_instance.this.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

## Disaster Recovery

Since notebooks are in a single subnet:

1. **Regular Backups**: Sync to S3 regularly
2. **Git Repositories**: Store all code in Git
3. **Infrastructure as Code**: Use Terraform for quick recreation
4. **Document Dependencies**: Keep track of installed packages
5. **Lifecycle Configs**: Automate environment setup

```hcl
# Automated backup lifecycle config
lifecycle_config_on_start = base64encode(<<-EOF
#!/bin/bash
set -e
sudo -u ec2-user -i <<'USEREOF'

# Restore from backup if directory is empty
if [ -z "$(ls -A /home/ec2-user/SageMaker)" ]; then
  aws s3 sync s3://my-backup-bucket/notebooks/latest/ \
    /home/ec2-user/SageMaker/
fi

# Setup periodic backups (every 6 hours)
(crontab -l 2>/dev/null; echo "0 */6 * * * aws s3 sync /home/ec2-user/SageMaker/ s3://my-backup-bucket/notebooks/latest/ --exclude '.git/*'") | crontab -

USEREOF
EOF
)
```

## FAQ

**Q: Can I change the subnet after creation?**
A: Yes, but it requires recreating the notebook instance. The EBS volume data persists.

**Q: What happens if my subnet's AZ goes down?**
A: Your notebook becomes unavailable until the AZ recovers. Use backups and Terraform to quickly spin up in another subnet.

**Q: Should I use multiple NAT gateways?**
A: Yes, for production. One per AZ for redundancy. If one AZ fails, notebooks in other AZs still have internet access.

**Q: Can I move a running notebook between subnets?**
A: No. You must stop it, update the configuration, and recreate it. This is why backups are critical.

**Q: How do I ensure my VPC endpoints are available?**
A: Deploy them across multiple subnets in different AZs (recommended 3 AZs).

## Summary

| Configuration | Single or Multiple? | Current Support |
|--------------|-------------------|-----------------|
| Notebook subnet | Single only ❌ | `subnet_id` |
| VPC endpoint subnets | Multiple recommended ✅ | `vpc_endpoint_subnet_ids` (coming) |
| Security groups | Multiple supported ✅ | `additional_security_group_ids` |
| Route tables | Multiple (for S3 endpoint) ✅ | Configure separately |

**Bottom line:** 
- Your notebook must be in **one subnet**
- Your VPC endpoints should be in **multiple subnets** for HA
- Use backups and IaC for quick recovery if needed

For true multi-AZ, high-availability ML environments, consider SageMaker Studio or self-managed JupyterHub on EKS.

