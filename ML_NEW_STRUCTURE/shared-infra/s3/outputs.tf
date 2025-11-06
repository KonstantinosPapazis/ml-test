output "datasets_bucket_name" {
  description = "Name of the datasets S3 bucket"
  value       = aws_s3_bucket.datasets.id
}

output "datasets_bucket_arn" {
  description = "ARN of the datasets S3 bucket"
  value       = aws_s3_bucket.datasets.arn
}

output "models_bucket_name" {
  description = "Name of the models S3 bucket"
  value       = aws_s3_bucket.models.id
}

output "models_bucket_arn" {
  description = "ARN of the models S3 bucket"
  value       = aws_s3_bucket.models.arn
}

output "all_bucket_arns" {
  description = "List of all S3 bucket ARNs"
  value = [
    aws_s3_bucket.datasets.arn,
    aws_s3_bucket.models.arn
  ]
}

