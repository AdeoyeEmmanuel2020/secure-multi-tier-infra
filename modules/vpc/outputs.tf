output "vpc_id"              { value = aws_vpc.main.id }
output "vpc_cidr"            { value = aws_vpc.main.cidr_block }
output "internet_gateway_id" { value = aws_internet_gateway.main.id }
output "nat_gateway_id"      { value = aws_nat_gateway.main.id }
output "public_subnet_ids"   { value = [aws_subnet.public_1.id, aws_subnet.public_2.id] }
output "private_subnet_ids"  { value = [aws_subnet.private_1.id, aws_subnet.private_2.id] }
output "database_subnet_ids" { value = [aws_subnet.database_1.id, aws_subnet.database_2.id] }
output "flow_log_group_name" { value = aws_cloudwatch_log_group.vpc_flow_logs.name }
