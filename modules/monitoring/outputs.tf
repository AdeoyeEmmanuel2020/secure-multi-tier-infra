output "sns_topic_arn"        { value = aws_sns_topic.alarms.arn }
output "cloudtrail_arn"       { value = aws_cloudtrail.main.arn }
output "cloudtrail_s3_bucket" { value = aws_s3_bucket.cloudtrail.id }
