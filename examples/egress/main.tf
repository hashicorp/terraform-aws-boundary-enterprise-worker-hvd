# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.47.0"
    }
  }
}

provider "aws" {
  region = var.region
}


module "boundary" {
  source = "../.."

  # Common
  friendly_name_prefix = var.friendly_name_prefix
  common_tags          = var.common_tags

  # Boundary configuration settings
  boundary_version         = var.boundary_version
  boundary_upstream        = var.boundary_upstream
  boundary_upstream_port   = var.boundary_upstream_port
  kms_worker_arn           = var.kms_worker_arn
  worker_is_internal       = var.worker_is_internal
  worker_tags              = var.worker_tags
  enable_session_recording = var.enable_session_recording

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

  #IAM
  ec2_allow_ssm                 = var.ec2_allow_ssm
  bsr_s3_bucket_arn             = var.bsr_s3_bucket_arn
  boundary_worker_iam_role_name = var.boundary_worker_iam_role_name
}
