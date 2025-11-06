output "notebook_name" {
  description = "Name of the notebook instance"
  value       = module.notebook.notebook_instance_name
}

output "notebook_arn" {
  description = "ARN of the notebook instance"
  value       = module.notebook.notebook_instance_arn
}

output "notebook_url" {
  description = "URL to access the notebook"
  value       = module.notebook.notebook_instance_url
}

output "notebook_id" {
  description = "ID of the notebook instance"
  value       = module.notebook.notebook_instance_id
}

