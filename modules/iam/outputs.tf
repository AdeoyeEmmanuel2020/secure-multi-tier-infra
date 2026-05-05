output "instance_profile_name" { value = aws_iam_instance_profile.ec2_ssm.name }
output "instance_profile_arn"  { value = aws_iam_instance_profile.ec2_ssm.arn }
output "role_arn"              { value = aws_iam_role.ec2_ssm.arn }
