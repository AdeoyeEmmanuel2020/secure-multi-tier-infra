output "asg_name"           { value = aws_autoscaling_group.app.name }
output "launch_template_id" { value = aws_launch_template.app.id }
output "ami_id"             { value = data.aws_ami.amazon_linux_2.id }
