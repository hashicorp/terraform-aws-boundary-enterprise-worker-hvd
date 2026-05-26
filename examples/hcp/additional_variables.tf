# Copyright IBM Corp. 2024, 2025, 2026
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Provider
#------------------------------------------------------------------------------
variable "region" {
  type        = string
  description = "AWS region where Boundary will be deployed."
  default     = "us-east-2"
}
