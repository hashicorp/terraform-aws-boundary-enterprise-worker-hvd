# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Network Load Balancer (lb)
#------------------------------------------------------------------------------
resource "aws_lb" "proxy" {
  count = var.create_lb == true ? 1 : 0

  name               = "${var.friendly_name_prefix}-bnd-wk-proxy-lb"
  load_balancer_type = "network"
  internal           = var.lb_is_internal
  security_groups    = [aws_security_group.proxy_lb_allow_ingress[0].id, aws_security_group.proxy_lb_allow_egress[0].id]
  subnets            = var.lb_subnet_ids

  tags = merge({ "Name" = "${var.friendly_name_prefix}-boundary-worker-proxy-lb" }, var.common_tags)
}

resource "aws_lb_listener" "proxy_lb_9202" {
  count = var.create_lb == true ? 1 : 0

  load_balancer_arn = aws_lb.proxy[0].arn
  port              = 9202
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.proxy_lb_9202[0].arn
  }
}

resource "aws_lb_target_group" "proxy_lb_9202" {
  count = var.create_lb == true ? 1 : 0

  name     = "${var.friendly_name_prefix}-bnd-wk-prx-tg"
  protocol = "TCP"
  port     = 9202
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "HTTP"
    path                = "/health"
    port                = 9203
    matcher             = "200"
    healthy_threshold   = 5
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-boundary-worker-proxy-tg" },
    { "Description" = "Load Balancer Target Group for Boundary application traffic." },
    var.common_tags
  )
}

#------------------------------------------------------------------------------
# Security Groups
#------------------------------------------------------------------------------
resource "aws_security_group" "proxy_lb_allow_ingress" {
  count = var.create_lb == true ? 1 : 0

  name   = "${var.friendly_name_prefix}-boundary-wk-lb-allow-ingress"
  vpc_id = var.vpc_id

  tags = merge({ "Name" = "${var.friendly_name_prefix}-boundary-worker-lb-allow-ingress" }, var.common_tags)
}

resource "aws_security_group_rule" "proxy_lb_allow_ingress_9202_cidr" {
  count = var.cidr_allow_ingress_boundary_9202 != null && var.create_lb == true ? 1 : 0

  type        = "ingress"
  from_port   = 9202
  to_port     = 9202
  protocol    = "tcp"
  cidr_blocks = var.cidr_allow_ingress_boundary_9202
  description = "Allow TCP/9202 inbound to Boundary worker lb from specified CIDR ranges for ingress workers."

  security_group_id = aws_security_group.proxy_lb_allow_ingress[0].id
}

resource "aws_security_group_rule" "proxy_lb_allow_ingress_9202_sg" {
  for_each = toset(var.sg_allow_ingress_boundary_9202)

  type                     = "ingress"
  from_port                = 9202
  to_port                  = 9202
  protocol                 = "tcp"
  source_security_group_id = each.key
  description              = "Allow TCP/9202 inbound to Boundary lb from specified Security Groups for ingress workers."

  security_group_id = aws_security_group.proxy_lb_allow_ingress[0].id
}

resource "aws_security_group" "proxy_lb_allow_egress" {
  count = var.create_lb == true ? 1 : 0

  name   = "${var.friendly_name_prefix}-boundary-wk-lb-allow-egress"
  vpc_id = var.vpc_id
  tags   = merge({ "Name" = "${var.friendly_name_prefix}-boundary-worker-lb-allow-egress" }, var.common_tags)
}

resource "aws_security_group_rule" "proxy_lb_allow_egress_all" {
  count = var.create_lb == true ? 1 : 0

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all traffic outbound from the lb."

  security_group_id = aws_security_group.proxy_lb_allow_egress[0].id
}
