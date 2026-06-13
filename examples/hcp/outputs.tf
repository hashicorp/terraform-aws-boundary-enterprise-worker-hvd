# Copyright IBM Corp. 2024, 2025, 2026
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Boundary URLs
#------------------------------------------------------------------------------
output "proxy_lb_dns_name" {
  value       = try(module.boundary.proxy_lb_dns_name, null)
  description = "DNS name of the Load Balancer."
}

#------------------------------------------------------------------------------
# IAM
#------------------------------------------------------------------------------
output "boundary_worker_iam_role_name" {
  value       = try(module.boundary.boundary_worker_iam_role_name, null)
  description = "Name of the IAM role for Boundary Worker instances."
}