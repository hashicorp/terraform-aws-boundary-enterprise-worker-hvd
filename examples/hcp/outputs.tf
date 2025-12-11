# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

output "boundary_proxy_lb_dns_name" {
  value = module.boundary.proxy_lb_dns_name
}
