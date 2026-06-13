# Copyright IBM Corp. 2024, 2025, 2026
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.46.0"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.111.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.9.0"
    }
  }
}
