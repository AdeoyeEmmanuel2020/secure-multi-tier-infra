output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "Open this URL in your browser to see the live app"
  value       = module.alb.alb_dns_name
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.compute.asg_name
}

output "cloudtrail_s3_bucket" {
  description = "S3 bucket storing all CloudTrail audit logs"
  value       = module.monitoring.cloudtrail_s3_bucket
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = module.vpc.database_subnet_ids
}

output "flow_log_group" {
  description = "CloudWatch Log Group for VPC Flow Logs"
  value       = module.vpc.flow_log_group_name
}
