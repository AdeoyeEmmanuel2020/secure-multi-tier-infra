# ================================================================
# NETWORK ACCESS CONTROL LISTS (Stateless subnet-level firewall)
# NACLs check EVERY packet (no memory of past packets).
# Security Groups remember connections — NACLs do not.
# You need BOTH for defence-in-depth.
# ================================================================

# ── PUBLIC NACL ─────────────────────────────────────────────────
resource "aws_network_acl" "public" {
  vpc_id     = var.vpc_id
  subnet_ids = var.public_subnet_ids
  tags       = { Name = "${var.project_name}-public-nacl" }
}

resource "aws_network_acl_rule" "pub_in_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "pub_in_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "pub_in_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "pub_out_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# ── PRIVATE NACL ────────────────────────────────────────────────
resource "aws_network_acl" "private" {
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids
  tags       = { Name = "${var.project_name}-private-nacl" }
}

resource "aws_network_acl_rule" "priv_in_pub1_http" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.public_subnet_cidrs[0]
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "priv_in_pub2_http" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.public_subnet_cidrs[1]
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "priv_in_https" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "priv_in_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 210
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "priv_out_all" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# ── DATABASE NACL ───────────────────────────────────────────────
resource "aws_network_acl" "database" {
  vpc_id     = var.vpc_id
  subnet_ids = var.database_subnet_ids
  tags       = { Name = "${var.project_name}-database-nacl" }
}

resource "aws_network_acl_rule" "db_in_mysql_priv1" {
  network_acl_id = aws_network_acl.database.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.private_subnet_cidrs[0]
  from_port      = 3306
  to_port        = 3306
}

resource "aws_network_acl_rule" "db_in_mysql_priv2" {
  network_acl_id = aws_network_acl.database.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.private_subnet_cidrs[1]
  from_port      = 3306
  to_port        = 3306
}

resource "aws_network_acl_rule" "db_in_ephemeral" {
  network_acl_id = aws_network_acl.database.id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "db_out_priv1" {
  network_acl_id = aws_network_acl.database.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.private_subnet_cidrs[0]
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "db_out_priv2" {
  network_acl_id = aws_network_acl.database.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.private_subnet_cidrs[1]
  from_port      = 1024
  to_port        = 65535
}
