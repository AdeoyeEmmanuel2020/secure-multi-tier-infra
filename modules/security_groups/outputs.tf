output "alb_sg_id"      { value = aws_security_group.alb.id }
output "app_sg_id"      { value = aws_security_group.app.id }
output "database_sg_id" { value = aws_security_group.database.id }
output "endpoint_sg_id" { value = aws_security_group.endpoint.id }
