# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Provider
#------------------------------------------------------------------------------
variable "region" {
  type        = string
  description = "AWS region where TFE will be deployed."
  default     = "us-east-1"
}
