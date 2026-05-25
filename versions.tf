# Copyright IBM Corp. 2024, 2025, 2026
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.46.0"
    }
  }
}
