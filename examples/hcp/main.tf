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

provider "aws" {
  region = var.region
}

provider "hcp" {
  client_id     = var.hcp_client_id
  client_secret = var.hcp_client_secret
}

module "boundary" {
  source = "../.."

  # Common
  friendly_name_prefix = var.friendly_name_prefix
  common_tags          = var.common_tags

  # Boundary configuration settings
  boundary_version = var.boundary_version
  # boundary_upstream                   = var.boundary_upstream # This variable is not used in the HCP example, but is left here for reference. The module will automatically determine the upstream based on the presence of a cluster ID or not. 
  boundary_upstream_port     = var.boundary_upstream_port
  worker_registration_method = var.worker_registration_method
  # kms_worker_arn                        = var.kms_worker_arn # This variable is not used in the HCP example, but is left here for reference. KMS is not currently supported in HCP Boundary, but may be in the future.
  # kms_endpoint                          = var.kms_endpoint
  controller_generated_activation_token = var.controller_generated_activation_token
  worker_is_internal                    = var.worker_is_internal
  enable_session_recording              = var.enable_session_recording
  boundary_worker_iam_role_name         = var.boundary_worker_iam_role_name
  create_boundary_worker_role           = var.create_boundary_worker_role
  worker_tags                           = var.worker_tags
  hcp_boundary_cluster_id               = var.hcp_boundary_cluster_id

  # Networking
  vpc_id                           = var.vpc_id
  worker_subnet_ids                = var.worker_subnet_ids
  create_lb                        = var.create_lb
  cidr_allow_ingress_boundary_9202 = var.cidr_allow_ingress_boundary_9202
  cidr_allow_ingress_ec2_ssh       = var.cidr_allow_ingress_ec2_ssh

  # Compute
  ec2_os_distro      = var.ec2_os_distro
  ec2_ssh_key_pair   = var.ec2_ssh_key_pair
  asg_instance_count = var.asg_instance_count
  ec2_instance_size  = var.ec2_instance_size

  #IAM
  ec2_allow_ssm     = var.ec2_allow_ssm
  bsr_s3_bucket_arn = var.bsr_s3_bucket_arn
}
