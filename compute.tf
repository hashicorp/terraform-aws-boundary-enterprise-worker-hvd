# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# User Data (cloud-init) arguments
#------------------------------------------------------------------------------
locals {
  custom_install_tpl          = var.custom_install_template != null ? "${path.cwd}/templates/${var.custom_install_template}" : "${path.module}/templates/boundary_custom_data.sh.tpl"
  user_data_template_rendered = templatefile(local.custom_install_tpl, local.custom_data_args)
  custom_data_args = {

    # https://developer.hashicorp.com/boundary/docs/configuration/worker

    # boundary settings
    boundary_version         = var.boundary_version
    systemd_dir              = "/etc/systemd/system",
    boundary_dir_bin         = "/usr/bin",
    boundary_dir_config      = "/etc/boundary.d",
    boundary_dir_home        = "/opt/boundary",
    boundary_upstream_ips    = var.boundary_upstream
    boundary_upstream_port   = var.boundary_upstream_port
    hcp_boundary_cluster_id  = var.hcp_boundary_cluster_id
    worker_is_internal       = var.worker_is_internal
    worker_tags              = lower(replace(jsonencode(merge(var.common_tags, var.worker_tags)), ":", "="))
    enable_session_recording = var.enable_session_recording
    additional_package_names = join(" ", var.additional_package_names)

    # KMS settings
    worker_kms_id = var.kms_worker_arn != "" ? data.aws_kms_key.worker[0].id : ""
    kms_endpoint  = var.kms_endpoint
    aws_region    = data.aws_region.current.name
  }
}

#------------------------------------------------------------------------------
# Launch Template
#------------------------------------------------------------------------------
locals {
  // If an AMI ID is provided via `var.ec2_ami_id`, use it.
  // Otherwise, use the latest AMI for the specified OS distro via `var.ec2_os_distro`.
  ami_id_list = tolist([
    var.ec2_ami_id,
    join("", data.aws_ami.ubuntu.*.image_id),
    join("", data.aws_ami.rhel.*.image_id),
    join("", data.aws_ami.centos.*.image_id),
    join("", data.aws_ami.amzn2.*.image_id),
  ])
}

resource "aws_launch_template" "boundary" {
  name          = "${var.friendly_name_prefix}-boundary-worker-ec2-launch-template"
  image_id      = coalesce(local.ami_id_list...)
  instance_type = var.ec2_instance_size
  key_name      = var.ec2_ssh_key_pair
  user_data     = base64gzip(local.user_data_template_rendered)

  iam_instance_profile {
    name = aws_iam_instance_profile.boundary_ec2.name
  }

  network_interfaces {
    associate_public_ip_address = !var.worker_is_internal
    security_groups = [
      aws_security_group.ec2_allow_ingress.id,
      aws_security_group.ec2_allow_egress.id
    ]
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_type = var.ebs_volume_type
      volume_size = var.ebs_volume_size
      throughput  = var.ebs_throughput
      iops        = var.ebs_iops
      encrypted   = var.ebs_is_encrypted
      kms_key_id  = var.ebs_is_encrypted == true && var.ebs_kms_key_arn != "" ? var.ebs_kms_key_arn : null
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      { "Name" = "${var.friendly_name_prefix}-boundary-worker-ec2" },
      { "Type" = "autoscaling-group" },
      { "OS_Distro" = var.ec2_os_distro },
      var.common_tags
    )
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-boundary-worker-ec2-launch-template" },
    var.common_tags
  )
}

#------------------------------------------------------------------------------
# Autoscaling Group
#------------------------------------------------------------------------------
resource "aws_autoscaling_group" "boundary" {
  name                      = "${var.friendly_name_prefix}-boundary-worker-asg"
  min_size                  = 0
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_instance_count
  vpc_zone_identifier       = var.worker_subnet_ids
  health_check_grace_period = var.asg_health_check_grace_period
  health_check_type         = var.create_lb ? "ELB" : "EC2"

  launch_template {
    id      = aws_launch_template.boundary.id
    version = "$Latest"
  }

  target_group_arns = var.create_lb == true ? [aws_lb_target_group.proxy_lb_9202[0].arn] : null

  tag {
    key                 = "Name"
    value               = "${var.friendly_name_prefix}-boundary-worker-asg"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = var.common_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }
}

#------------------------------------------------------------------------------
# Security Groups
#------------------------------------------------------------------------------
resource "aws_security_group" "ec2_allow_ingress" {
  name   = "${var.friendly_name_prefix}-boundary-worker-ec2-allow-ingress"
  vpc_id = var.vpc_id
  tags   = merge({ "Name" = "${var.friendly_name_prefix}-boundary-worker-ec2-allow-ingress" }, var.common_tags)
}

resource "aws_security_group_rule" "ec2_allow_ingress_9202_from_lb" {
  count = var.create_lb == true ? 1 : 0

  type                     = "ingress"
  from_port                = 9202
  to_port                  = 9202
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.proxy_lb_allow_ingress[0].id
  description              = "Allow TCP/9202 inbound to Boundary Worker EC2 instances from Boundary proxy load balancer."

  security_group_id = aws_security_group.ec2_allow_ingress.id
}

resource "aws_security_group_rule" "ec2_allow_ingress_9203_from_lb" {
  count = var.create_lb == true ? 1 : 0

  type                     = "ingress"
  from_port                = 9203
  to_port                  = 9203
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.proxy_lb_allow_ingress[0].id
  description              = "Allow TCP/9203 inbound to Boundary Worker EC2 instances from Boundary proxy load balancer."

  security_group_id = aws_security_group.ec2_allow_ingress.id
}

resource "aws_security_group_rule" "ec2_allow_ingress_9202_cidr" {
  count = var.cidr_allow_ingress_boundary_9202 != null ? 1 : 0

  type        = "ingress"
  from_port   = 9202
  to_port     = 9202
  protocol    = "tcp"
  cidr_blocks = var.cidr_allow_ingress_boundary_9202
  description = "Allow TCP/9202 inbound to Boundary Worker EC2 instances from specified CIDR ranges for workers."

  security_group_id = aws_security_group.ec2_allow_ingress.id
}

resource "aws_security_group_rule" "ec2_allow_ingress_9202_sg" {
  for_each = toset(var.sg_allow_ingress_boundary_9202)

  type                     = "ingress"
  from_port                = 9202
  to_port                  = 9202
  protocol                 = "tcp"
  source_security_group_id = each.key
  description              = "Allow TCP/9202 inbound to Boundary Worker EC2 instances from specified Security Groups for ingress workers."

  security_group_id = aws_security_group.ec2_allow_ingress.id
}

resource "aws_security_group_rule" "ec2_allow_ingress_ssh" {
  count = length(var.cidr_allow_ingress_ec2_ssh) > 0 ? 1 : 0

  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = var.cidr_allow_ingress_ec2_ssh
  description = "Allow TCP/22 (SSH) inbound to Boundary Worker EC2 instances from specified CIDR ranges."

  security_group_id = aws_security_group.ec2_allow_ingress.id
}

resource "aws_security_group" "ec2_allow_egress" {
  name   = "${var.friendly_name_prefix}-boundary-worker-ec2-allow-egress"
  vpc_id = var.vpc_id
  tags   = merge({ "Name" = "${var.friendly_name_prefix}-boundary-worker-ec2-allow-egress" }, var.common_tags)
}

resource "aws_security_group_rule" "ec2_allow_egress_all" {

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all traffic outbound from Boundary Worker EC2 instances."

  security_group_id = aws_security_group.ec2_allow_egress.id
}

# ------------------------------------------------------------------------------
# Debug rendered boundary custom_data script from template
# ------------------------------------------------------------------------------
# Uncomment this block to debug the rendered boundary custom_data script
# resource "local_file" "debug_custom_data" {
#   content  = templatefile("${path.module}/templates/boundary_custom_data.sh.tpl", local.custom_data_args)
#   filename = "${path.module}/debug/debug_boundary_custom_data.sh"
# }
