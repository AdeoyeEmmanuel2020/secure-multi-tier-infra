variable "project_name"          { type = string }
variable "vpc_id"                { type = string }
variable "public_subnet_ids"     { type = list(string) }
variable "private_subnet_ids"    { type = list(string) }
variable "database_subnet_ids"   { type = list(string) }
variable "public_subnet_cidrs"   { type = list(string) }
variable "private_subnet_cidrs"  { type = list(string) }
variable "database_subnet_cidrs" { type = list(string) }
