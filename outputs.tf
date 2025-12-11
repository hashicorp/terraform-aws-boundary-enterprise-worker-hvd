# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Boundary URLs
#------------------------------------------------------------------------------
output "proxy_lb_dns_name" {
  value       = try(aws_lb.proxy[0].dns_name, null)
  description = "DNS name of the Load Balancer."
}

#------------------------------------------------------------------------------
# IAM
#------------------------------------------------------------------------------
output "boundary_worker_iam_role_name" {
  value       = try(aws_iam_role.boundary_ec2[0].name, null)
  description = "Name of the IAM role for Boundary Worker instances."
}
