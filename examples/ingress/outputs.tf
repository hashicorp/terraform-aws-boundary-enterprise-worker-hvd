# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

output "boundary_proxy_lb_dns_name" {
  value = module.boundary.proxy_lb_dns_name
}

output "boundary_worker_iam_role_name" {
  value       = module.boundary.boundary_worker_iam_role_name
  description = "ARN of the IAM role for Boundary Worker instances."
}
