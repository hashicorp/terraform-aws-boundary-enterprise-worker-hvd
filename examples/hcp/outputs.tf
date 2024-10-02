# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "boundary_proxy_lb_dns_name" {
  value = module.boundary.proxy_lb_dns_name
}
