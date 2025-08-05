# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Common
#------------------------------------------------------------------------------
variable "friendly_name_prefix" {
  type        = string
  description = "Friendly name prefix used for uniquely naming AWS resources. This should be unique across all deployments"
  validation {
    condition     = length(var.friendly_name_prefix) > 0 && length(var.friendly_name_prefix) < 17
    error_message = "Friendly name prefix must be between 1 and 16 characters."
  }
}

variable "common_tags" {
  type        = map(string)
  description = "Map of common tags for taggable AWS resources."
  default     = {}
}

#------------------------------------------------------------------------------
# Boundary Configuration Settings
#------------------------------------------------------------------------------
variable "boundary_version" {
  type        = string
  description = "Version of Boundary to install."
  default     = "0.17.1+ent"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\+ent$", var.boundary_version))
    error_message = "Value must be in the format 'X.Y.Z+ent'."
  }
}

variable "boundary_upstream" {
  type        = list(string)
  description = "List of IP addresses or FQDNs for the worker to initially connect to. This could be a controller or worker. This is not used when connecting to HCP Boundary."
  default     = null
}

variable "boundary_upstream_port" {
  type        = number
  description = "Port for the worker to connect to. Typically 9201 to connect to a controller, 9202 to a worker."
  default     = 9202
}

variable "hcp_boundary_cluster_id" {
  type        = string
  description = "ID of the Boundary cluster in HCP. Only used when using HCP Boundary."
  default     = ""
  validation {
    condition     = var.hcp_boundary_cluster_id != "" ? var.boundary_upstream == null : true
    error_message = "HCP Boundary cluster ID must be provided when `boundary_upstream` is not provided."
  }
}

variable "kms_worker_arn" {
  type        = string
  description = "KMS ID of the worker-auth kms key."
  default     = ""
}

variable "kms_endpoint" {
  type        = string
  description = "AWS VPC endpoint for KMS service."
  default     = ""
}

variable "enable_session_recording" {
  type        = bool
  description = "Boolean to enable session recording."
  default     = false
}

variable "worker_tags" {
  type        = map(string)
  description = "Map of extra tags to apply to Boundary Worker Configuration. var.common_tags will be merged with this map."
  default     = {}
}

variable "additional_package_names" {
  type        = set(string)
  description = "List of additional repository package names to install"
  default     = []
}
#------------------------------------------------------------------------------
# IAM
#------------------------------------------------------------------------------
variable "create_boundary_worker_role" {
  type        = bool
  description = "Boolean to create an IAM role for Boundary Worker EC2 instances."
  default     = true
}

variable "boundary_worker_iam_role_name" {
  type        = string
  description = "Existing IAM Role to use for the Boundary Worker EC2 instances. This must be provided if `create_boundary_worker_role` is set to `false`."
  default     = null
  validation {
    condition     = !var.create_boundary_worker_role ? var.boundary_worker_iam_role_name != null : true
    error_message = "IAM role name must be provided if `create_boundary_worker_role` is set to `false`."
  }
}

variable "bsr_s3_bucket_arn" {
  type        = string
  description = "Arn of the S3 bucket used to store Boundary session recordings."
  default     = null
  validation {
    condition     = var.enable_session_recording && var.create_boundary_worker_role ? var.bsr_s3_bucket_arn != null : true
    error_message = "S3 bucket ARN must be provided if `enable_session_recording` is set to `true' and `create_boundary_worker_role` is set to `true`."
  }
}

#------------------------------------------------------------------------------
# Networking
#------------------------------------------------------------------------------
variable "vpc_id" {
  type        = string
  description = "ID of VPC where Boundary will be deployed."
}

variable "worker_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to use for the EC2 instance. Unless the workers need to be publicly exposed (example: ingress workers), use private subnets."
}

variable "lb_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to use for the proxy Network Load Balancer. Unless the lb needs to be publicly exposed (example: downstream Boundary Workers connecting to the ingress workers over the Internet), use private subnets."
  default     = null
}

variable "cidr_allow_ingress_boundary_9202" {
  type        = list(string)
  description = "List of CIDR ranges to allow ingress traffic on port 9202 to workers."
  default     = null
}

variable "sg_allow_ingress_boundary_9202" {
  type        = list(string)
  description = "List of Security Groups to allow ingress traffic on port 9202 to workers."
  default     = []
}

variable "cidr_allow_ingress_ec2_ssh" {
  type        = list(string)
  description = "List of CIDR ranges to allow SSH ingress to Boundary EC2 instance (i.e. bastion IP, client/workstation IP, etc.)."
  default     = []
}

variable "worker_is_internal" {
  type        = bool
  description = "Boolean to create give the worker an internal IP address only or give it an external IP address."
  default     = true
}

variable "create_lb" {
  type        = bool
  description = "Boolean to create a Network Load Balancer for Boundary. Should be true if downstream workers will connect to these workers."
  default     = false
  validation {
    condition     = var.create_lb == true ? var.lb_subnet_ids != null : true
    error_message = "The `lb_subnet_ids` must be provided if `create_lb` is set to `true`."
  }
}

variable "lb_is_internal" {
  type        = bool
  description = "Boolean to create an internal (private) Proxy load balancer. The `lb_subnet_ids` must be private subnets if this is set to `true`."
  default     = true
}

#------------------------------------------------------------------------------
# Compute
#------------------------------------------------------------------------------
variable "ec2_os_distro" {
  type        = string
  description = "Linux OS distribution for Boundary EC2 instance. Choose from `amzn2`, `ubuntu`, `rhel`, `centos`."
  default     = "ubuntu"

  validation {
    condition     = contains(["amzn2", "ubuntu", "rhel", "centos"], var.ec2_os_distro)
    error_message = "Supported values are `amzn2`, `ubuntu`, `rhel` or `centos`."
  }
}

variable "asg_instance_count" {
  type        = number
  description = "Desired number of Boundary EC2 instances to run in Autoscaling Group. Leave at `1` unless Active/Active is enabled."
  default     = 1
}

variable "asg_max_size" {
  type        = number
  description = "Max number of Boundary EC2 instances to run in Autoscaling Group."
  default     = 3
}

variable "asg_health_check_grace_period" {
  type        = number
  description = "The amount of time to wait for a new Boundary EC2 instance to become healthy. If this threshold is breached, the ASG will terminate the instance and launch a new one."
  default     = 300
}

variable "ec2_ami_id" {
  type        = string
  description = "Custom AMI ID for Boundary EC2 Launch Template. If specified, value of `os_distro` must coincide with this custom AMI OS distro."
  default     = null

  validation {
    condition     = try((length(var.ec2_ami_id) > 4 && substr(var.ec2_ami_id, 0, 4) == "ami-"), var.ec2_ami_id == null)
    error_message = "Value must start with \"ami-\"."
  }
}

variable "ec2_instance_size" {
  type        = string
  description = "EC2 instance type for Boundary EC2 Launch Template. Regions may have different instance types available."
  default     = "m5.2xlarge"
}

variable "ec2_ssh_key_pair" {
  type        = string
  description = "Name of existing SSH key pair to attach to Boundary EC2 instance."
  default     = ""
}

variable "ec2_allow_ssm" {
  type        = bool
  description = "Boolean to attach the `AmazonSSMManagedInstanceCore` policy to the Boundary instance role, allowing the SSM agent (if present) to function."
  default     = false
}

variable "ebs_is_encrypted" {
  type        = bool
  description = "Boolean for encrypting the root block device of the Boundary EC2 instance(s)."
  default     = false
}

variable "ebs_kms_key_arn" {
  type        = string
  description = "ARN of KMS key to encrypt EC2 EBS volumes."
  default     = null
}

variable "ebs_volume_type" {
  type        = string
  description = "EBS volume type for Boundary EC2 instances."
  default     = "gp3"

  validation {
    condition     = var.ebs_volume_type == "gp3" || var.ebs_volume_type == "gp2"
    error_message = "Supported values are 'gp3' and 'gp2'."
  }
}

variable "ebs_volume_size" {
  type        = number
  description = "The size (GB) of the root EBS volume for Boundary EC2 instances. Must be at least `50` GB."
  default     = 50

  validation {
    condition     = var.ebs_volume_size >= 50 && var.ebs_volume_size <= 16000
    error_message = "The ebs volume must be greater `50` GB and lower than `16000` GB (16TB)."
  }
}

variable "ebs_throughput" {
  type        = number
  description = "The throughput to provision for a `gp3` volume in MB/s. Must be at least `125` MB/s."
  default     = 125

  validation {
    condition = (
      var.ebs_throughput >= 125 &&
      var.ebs_throughput <= 1000
    )
    error_message = "The throughput must be at least `125` MB/s and lower than `1000` MB/s."
  }
}

variable "ebs_iops" {
  type        = number
  description = "The amount of IOPS to provision for a `gp3` volume. Must be at least `3000`."
  default     = 3000

  validation {
    condition = (
      var.ebs_iops >= 3000 &&
      var.ebs_iops <= 16000
    )
    error_message = "The IOPS must be at least `3000` GB and lower than `16000` (16TB)."
  }
}

variable "custom_install_template" {
  type        = string
  description = "Filename of a custom Install script template to use in place of the built-in user_data script. The file must exist within a directory named './templates' in your current working directory."
  default     = null

  validation {
    condition     = var.custom_install_template != null ? fileexists("${path.cwd}/templates/${var.custom_install_template}") : true
    error_message = "File not found. Ensure the file exists within a directory named './templates' relative to your current working directory."
  }
}
