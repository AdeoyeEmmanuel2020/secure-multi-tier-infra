# ================================================================
# SECURITY GROUP CHAINING
# Internet -> ALB SG -> App SG -> DB SG
# Each tier only accepts traffic from the SG directly above it.
# ================================================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB: accepts HTTP and HTTPS from the internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg" }
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "App servers: only accepts traffic from the ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB SG only - security group chaining"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound for SSM endpoints and updates"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-app-sg" }
}

resource "aws_security_group" "database" {
  name        = "${var.project_name}-db-sg"
  description = "Database: only accepts MySQL from the App security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from App SG only - security group chaining"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Replies within VPC only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = { Name = "${var.project_name}-db-sg" }
}

resource "aws_security_group" "endpoint" {
  name        = "${var.project_name}-endpoint-sg"
  description = "VPC Endpoints: accepts HTTPS from App SG for SSM"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTPS from App SG for SSM Session Manager"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-endpoint-sg" }
}
