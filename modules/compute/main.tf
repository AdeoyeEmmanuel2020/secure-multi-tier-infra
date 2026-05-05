# ================================================================
# AUTO-FETCH LATEST AMAZON LINUX 2 AMI
# Never hardcode AMI IDs — they change per region and expire.
# ================================================================
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ================================================================
# LAUNCH TEMPLATE — blueprint for every EC2 instance
# Security hardening baked in:
#   1. IMDSv2 required (prevents SSRF credential theft)
#   2. EBS encrypted at rest (AES-256)
#   3. No SSH key pair (SSM only)
#   4. No public IP (private subnet)
# ================================================================
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  # IMDSv2 — requires a session token before returning any metadata.
  # Prevents SSRF attacks from reading http://169.254.169.254/
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Encrypted EBS root volume
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # IAM profile grants SSM access (no key pair needed)
  iam_instance_profile {
    name = var.iam_instance_profile
  }

  # Private network — no public IP
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.app_sg_id]
    delete_on_termination       = true
  }

  user_data = base64encode(<<-SCRIPT
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    echo "Bootstrap started: $(date)"

    yum update -y

    # SSM Agent (pre-installed on Amazon Linux 2 but ensure it's running)
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent

    # Apache
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd

    # Fetch metadata with IMDSv2 token (proves IMDSv2 is working)
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/instance-id)
    AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/placement/availability-zone)
    PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/local-ipv4)

    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>Secure Multi-Tier Infrastructure</title>
      <style>
        *{margin:0;padding:0;box-sizing:border-box}
        body{font-family:'Segoe UI',sans-serif;background:#0d1117;color:#c9d1d9;
             min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px}
        .wrap{width:100%;max-width:700px}
        .card{background:#161b22;border:1px solid #30363d;border-radius:12px;padding:36px;margin-bottom:16px}
        h1{color:#3fb950;font-size:1.6rem;margin-bottom:6px;text-align:center}
        .sub{color:#8b949e;text-align:center;margin-bottom:28px;font-size:.9rem}
        .grid{display:grid;grid-template-columns:1fr 1fr 1fr;gap:10px;margin-bottom:24px}
        .badge{background:#21262d;border:1px solid #30363d;border-radius:8px;
               padding:12px;font-size:.78rem;color:#8b949e}
        .badge strong{color:#3fb950;display:block;font-size:.7rem;margin-bottom:4px;
                      text-transform:uppercase;letter-spacing:.05em}
        .info{display:grid;grid-template-columns:1fr 1fr 1fr;gap:10px}
        .ibox{background:#0d1117;border:1px solid #30363d;border-radius:8px;
              padding:14px;text-align:center}
        .ibox .v{color:#58a6ff;font-family:monospace;font-size:.8rem;word-break:break-all}
        .ibox .k{color:#6e7681;font-size:.7rem;margin-top:6px}
        .foot{text-align:center;color:#6e7681;font-size:.78rem;margin-top:12px}
        .foot span{color:#3fb950}
      </style>
    </head>
    <body>
    <div class="wrap">
      <div class="card">
        <h1>&#9989; Secure Multi-Tier Infrastructure</h1>
        <p class="sub">Deployed with Terraform &mdash; All security controls active</p>
        <div class="grid">
          <div class="badge"><strong>Metadata</strong>&#128272; IMDSv2 Enforced</div>
          <div class="badge"><strong>Storage</strong>&#128274; EBS Encrypted</div>
          <div class="badge"><strong>Access</strong>&#128737; SSM Only &mdash; No SSH</div>
          <div class="badge"><strong>Network</strong>&#128279; SG Chaining</div>
          <div class="badge"><strong>Detection</strong>&#128269; GuardDuty Active</div>
          <div class="badge"><strong>Audit</strong>&#128203; CloudTrail On</div>
        </div>
        <div class="info">
          <div class="ibox"><div class="v">$INSTANCE_ID</div><div class="k">Instance ID</div></div>
          <div class="ibox"><div class="v">$AZ</div><div class="k">Availability Zone</div></div>
          <div class="ibox"><div class="v">$PRIVATE_IP</div><div class="k">Private IP</div></div>
        </div>
      </div>
      <p class="foot"><span>No SSH key pair was used.</span> Access is via SSM Session Manager only. All sessions are logged in CloudTrail.</p>
    </div>
    </body>
    </html>
    HTML

    echo "Bootstrap complete: $(date)"
  SCRIPT
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name         = "${var.project_name}-app-server"
      Environment  = var.environment
      IMDSv2       = "enforced"
      EBSEncrypted = "true"
      Access       = "SSM-only"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name      = "${var.project_name}-app-volume"
      Encrypted = "true"
    }
  }

  lifecycle { create_before_destroy = true }
}

# ================================================================
# AUTO SCALING GROUP
# ================================================================
resource "aws_autoscaling_group" "app" {
  name                      = "${var.project_name}-asg"
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  vpc_zone_identifier       = var.private_subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences { min_healthy_percentage = 50 }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app-server"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_autoscaling_policy" "cpu_tracking" {
  name                   = "${var.project_name}-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}
