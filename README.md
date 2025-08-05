# Boundary Enterprise Worker HVD on AWS EC2

Terraform module aligned with HashiCorp Validated Designs (HVD) to deploy Boundary Enterprise Worker(s) on Amazon Web Services (AWS) using EC2 instances. This module is designed to work with the complimentary [Boundary Enterprise Controller HVD on AWS EC2](https://github.com/hashicorp/terraform-aws-boundary-enterprise-controller-hvd) module.

## Prerequisites

### General

- Terraform CLI `>= 1.9` installed on workstations.
- `Git` CLI and Visual Studio Code editor installed on workstations are strongly recommended.
- AWS account that Boundary will be hosted in with permissions to provision these [resources](#resources) via Terraform CLI.
- (Optional) AWS S3 bucket for [S3 Remote State backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3) that will solely be used to stand up the Boundary infrastructure via Terraform CLI (Community Edition).

### Networking

- AWS VPC ID and the following subnets:
  - EC2 (worker) subnet IDs.
  - (Optional) NLB Subnet IDs if a load balancer will be deployed.
- (Optional) KMS VPC Endpoint configured within VPC.
- Security Groups:
  - This module will create the necessary Security Groups and attach them to the applicable resources.
  - Ensure the [Boundary Network connectivity](https://developer.hashicorp.com/boundary/docs/install-boundary/architecture/system-requirements#network-connectivity) are met.

### Compute

One of the following mechanisms for shell access to Boundary EC2 instances:

- EC2 SSH Key Pair.
- Ability to enable AWS SSM (this module supports this via a boolean input variable).

### Boundary

Unless deploying a Boundary HCP Worker, you will require a Boundary Enterprise Cluster deployed using the [Boundary Enterprise Controller HVD on AWS EC2](https://github.com/hashicorp/terraform-aws-boundary-enterprise-controller-hvd) module.

## Usage - Boundary Enterprise

1. Create/configure/validate the applicable [prerequisites](#prerequisites).

1. Nested within the [examples](https://github.com/hashicorp/terraform-aws-boundary-enterprise-worker-hvd/blob/main/examples/) directory are subdirectories that contain ready-made Terraform configurations of example scenarios for how to call and deploy this module. To get started, choose an example scenario. If you are not sure which example scenario to start with, then we recommend starting with the [ingress](https://github.com/hashicorp/terraform-aws-boundary-enterprise-worker-hvd/blob/main/examples/ingress) example.

1. Copy all of the Terraform files from your example scenario of choice into a new destination directory to create your root Terraform configuration that will manage your Boundary deployment. If you are not sure where to create this new directory, it is common for us to see users create an `environments/` directory at the root of this repo, and then a subdirectory for each Boundary instance deployment, like so:

    ```sh
    .
    └── environments
        ├── production
        │   ├── backend.tf
        │   ├── main.tf
        │   ├── outputs.tf
        │   ├── terraform.tfvars
        │   └── variables.tf
        └── sandbox
            ├── backend.tf
            ├── main.tf
            ├── outputs.tf
            ├── terraform.tfvars
            └── variables.tf
    ```

    >📝 Note: in this example, the user will have two separate Boundary deployments; one for their `sandbox` environment, and one for their `production` environment. This is recommended, but not required.

1. (Optional) Uncomment and update the [S3 remote state backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3) configuration provided in the `backend.tf` file with your own custom values. While this step is highly recommended, it is technically not required to use a remote backend config for your Boundary deployment.

1. Populate your own custom values into the `terraform.tfvars.example` file that was provided, and remove the `.example` file extension such that the file is now named `terraform.tfvars`.

    >📝 Note: The `friendly_name_prefix` variable should be unique for every agent deployment.

1. Navigate to the directory of your newly created Terraform configuration for your Boundary Worker deployment, and run `terraform init`, `terraform plan`, and `terraform apply`.

1. After the `terraform apply` finishes successfully, you can monitor the install progress by connecting to the VM in your Boundary worker ASG using SSH or AWS SSM and observing the cloud-init logs:

    Higher-level logs:

    ```sh
    tail -f /var/log/boundary-cloud-init.log
    ```

    Lower-level logs:

    ```sh
    journalctl -xu cloud-final -f
    ```

    >📝 Note: the `-f` argument is to follow the logs as they append in real-time, and is optional. You may remove the `-f` for a static view.

    The log files should display the following message after the cloud-init (user_data) script finishes successfully:

    ```sh
    [INFO] boundary_custom_data script finished successfully!
    ```

1. Once the cloud-init script finishes successfully, while still connected to the VM via SSH you can check the status of the boundary service:

    ```sh
    sudo systemctl status boundary
    ```

1. After the Boundary Worker is deployed the Boundary worker should show up in the Boundary Clusters workers

## Usage - HCP Boundary

1. In HCP Boundary go to `Workers` and start creating a new worker. Copy the `Boundary Cluster ID`.

1. Create/configure/validate the applicable [prerequisites](#prerequisites).

1. Nested within the [examples](https://github.com/hashicorp/terraform-aws-boundary-enterprise-worker-hvd/blob/main/examples/) directory are subdirectories that contain ready-made Terraform configurations of example scenarios for how to call and deploy this module. To get started, choose an example scenario. If you are not sure which example scenario to start with, then we recommend starting with the [default](https://github.com/hashicorp/terraform-aws-boundary-enterprise-worker-hvd/blob/main/examples/default) example.

1. Copy all of the Terraform files from your example scenario of choice into a new destination directory to create your root Terraform configuration that will manage your Boundary deployment. If you are not sure where to create this new directory, it is common for us to see users create an `environments/` directory at the root of this repo, and then a subdirectory for each Boundary instance deployment, like so:

    ```sh
      .
      └── environments
          ├── production
          │   ├── backend.tf
          │   ├── main.tf
          │   ├── outputs.tf
          │   ├── terraform.tfvars
          │   └── variables.tf
          └── sandbox
              ├── backend.tf
              ├── main.tf
              ├── outputs.tf
              ├── terraform.tfvars
              └── variables.tf
    ```

    >📝 Note: in this example, the user will have two separate Boundary deployments; one for their `sandbox` environment, and one for their `production` environment. This is recommended, but not required.

1. (Optional) Uncomment and update the [S3 remote state backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3) configuration provided in the `backend.tf` file with your own custom values. While this step is highly recommended, it is technically not required to use a remote backend config for your Boundary deployment.

1. Populate your own custom values into the `terraform.tfvars.example` file that was provided, and remove the `.example` file extension such that the file is now named `terraform.tfvars`. Ensure to set the `hcp_boundary_cluster_id` variable with the Boundary Cluster ID from step 1.

    >📝 Note: The `friendly_name_prefix` variable should be unique for every agent deployment.

1. Navigate to the directory of your newly created Terraform configuration for your Boundary Worker deployment, and run `terraform init`, `terraform plan`, and `terraform apply`.

1. After the `terraform apply` finishes successfully, you can monitor the install progress by connecting to the VM in your Boundary worker ASG using SSH or AWS SSM and observing the cloud-init logs:

    Higher-level logs:

    ```sh
    tail -f /var/log/boundary-cloud-init.log
    ```

    Lower-level logs:

    ```sh
    journalctl -xu cloud-final -f
    ```

    >📝 Note: the `-f` argument is to follow the logs as they append in real-time, and is optional. You may remove the `-f` for a static view.

    The log files should display the following message after the cloud-init (user_data) script finishes successfully:

    ```sh
    [INFO] boundary_custom_data script finished successfully!
    ```

1. Once the cloud-init script finishes successfully, while still connected to the VM via SSH you can check the status of the boundary service:

    ```sh
    sudo systemctl status boundary
    ```

1. While still connected to the Boundary Worker, `sudo journalctl -xu boundary` to review the Boundary Logs.

1. Copy the `Worker Auth Registration Request` string and paste this into the `Worker Auth Registration Request` field of the new Boundary Worker in the HCP console and click `Register Worker`.

1. Worker should show up in HCP Boundary console

## Docs

Below are links to docs pages related to deployment customizations and day 2 operations of your Boundary Controller instance.

- [Deployment Customizations](https://github.com/hashicorp/terraform-aws-boundary-enterprise-worker-hvd/blob/main/docs/deployment-customizations.md)
- [Upgrading Boundary version](https://github.com/hashicorp/terraform-aws-boundary-enterprise-worker-hvd/blob/main/docs/boundary-version-upgrades.md)
- [Updating/modifying Boundary configuration settings](https://github.com/hashicorp/terraform-aws-boundary-enterprise-worker-hvd/blob/main/docs/boundary-config-settings.md)


## Troubleshooting

During deployment the output of the `user_data` script can be traced in `/var/log/cloud-init.log`, `/var/log/cloud-init-output.log` and `/var/log/vault-cloud-init.log` due to `set -xeuo pipefail` in the default  `install-vault.sh.tpl`
For help debugging cloud init and user data scripts
- <https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#userdata-linux>
- <https://cloudinit.readthedocs.io/en/latest/howto/debugging.html#cloud-init-ran-but-didn-t-do-what-i-want-it-to>

## Module support

This open source software is maintained by the HashiCorp Technical Field Organization, independently of our enterprise products. While our Support Engineering team provides dedicated support for our enterprise offerings, this open source software is not included.

- For help using this open source software, please engage your account team.
- To report bugs/issues with this open source software, please open them directly against this code repository using the GitHub issues feature.

Please note that there is no official Service Level Agreement (SLA) for support of this software as a HashiCorp customer. This software falls under the definition of Community Software/Versions in your Agreement. We appreciate your understanding and collaboration in improving our open source projects.


<!-- BEGIN_TF_DOCS -->
## Module support

This open source software is maintained by the HashiCorp Technical Field Organization, independently of our enterprise products. While our Support Engineering team provides dedicated support for our enterprise offerings, this open source software is not included.

- For help using this open source software, please engage your account team.
- To report bugs/issues with this open source software, please open them directly against this code repository using the GitHub issues feature.

Please note that there is no official Service Level Agreement (SLA) for support of this software as a HashiCorp customer. This software falls under the definition of Community Software/Versions in your Agreement. We appreciate your understanding and collaboration in improving our open source projects.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.51.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.51.0 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_iam_instance_profile.boundary_ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.boundary_ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.boundary_ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.aws_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_lb.proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.proxy_lb_9202](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.proxy_lb_9202](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.ec2_allow_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.ec2_allow_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.proxy_lb_allow_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.proxy_lb_allow_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.ec2_allow_egress_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ec2_allow_ingress_9202_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ec2_allow_ingress_9202_from_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ec2_allow_ingress_9202_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ec2_allow_ingress_9203_from_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ec2_allow_ingress_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.proxy_lb_allow_egress_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.proxy_lb_allow_ingress_9202_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.proxy_lb_allow_ingress_9202_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ami.amzn2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.centos](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.rhel](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.boundary_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.boundary_session_recording_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.combined](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ec2_allow_ebs_kms_cmk](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_role.boundary_ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_kms_key.worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_package_names"></a> [additional\_package\_names](#input\_additional\_package\_names) | List of additional repository package names to install | `set(string)` | `[]` | no |
| <a name="input_asg_health_check_grace_period"></a> [asg\_health\_check\_grace\_period](#input\_asg\_health\_check\_grace\_period) | The amount of time to wait for a new Boundary EC2 instance to become healthy. If this threshold is breached, the ASG will terminate the instance and launch a new one. | `number` | `300` | no |
| <a name="input_asg_instance_count"></a> [asg\_instance\_count](#input\_asg\_instance\_count) | Desired number of Boundary EC2 instances to run in Autoscaling Group. Leave at `1` unless Active/Active is enabled. | `number` | `1` | no |
| <a name="input_asg_max_size"></a> [asg\_max\_size](#input\_asg\_max\_size) | Max number of Boundary EC2 instances to run in Autoscaling Group. | `number` | `3` | no |
| <a name="input_boundary_upstream"></a> [boundary\_upstream](#input\_boundary\_upstream) | List of IP addresses or FQDNs for the worker to initially connect to. This could be a controller or worker. This is not used when connecting to HCP Boundary. | `list(string)` | `null` | no |
| <a name="input_boundary_upstream_port"></a> [boundary\_upstream\_port](#input\_boundary\_upstream\_port) | Port for the worker to connect to. Typically 9201 to connect to a controller, 9202 to a worker. | `number` | `9202` | no |
| <a name="input_boundary_version"></a> [boundary\_version](#input\_boundary\_version) | Version of Boundary to install. | `string` | `"0.17.1+ent"` | no |
| <a name="input_boundary_worker_iam_role_name"></a> [boundary\_worker\_iam\_role\_name](#input\_boundary\_worker\_iam\_role\_name) | Existing IAM Role to use for the Boundary Worker EC2 instances. This must be provided if `create_boundary_worker_role` is set to `false`. | `string` | `null` | no |
| <a name="input_bsr_s3_bucket_arn"></a> [bsr\_s3\_bucket\_arn](#input\_bsr\_s3\_bucket\_arn) | Arn of the S3 bucket used to store Boundary session recordings. | `string` | `null` | no |
| <a name="input_cidr_allow_ingress_boundary_9202"></a> [cidr\_allow\_ingress\_boundary\_9202](#input\_cidr\_allow\_ingress\_boundary\_9202) | List of CIDR ranges to allow ingress traffic on port 9202 to workers. | `list(string)` | `null` | no |
| <a name="input_cidr_allow_ingress_ec2_ssh"></a> [cidr\_allow\_ingress\_ec2\_ssh](#input\_cidr\_allow\_ingress\_ec2\_ssh) | List of CIDR ranges to allow SSH ingress to Boundary EC2 instance (i.e. bastion IP, client/workstation IP, etc.). | `list(string)` | `[]` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Map of common tags for taggable AWS resources. | `map(string)` | `{}` | no |
| <a name="input_create_boundary_worker_role"></a> [create\_boundary\_worker\_role](#input\_create\_boundary\_worker\_role) | Boolean to create an IAM role for Boundary Worker EC2 instances. | `bool` | `true` | no |
| <a name="input_create_lb"></a> [create\_lb](#input\_create\_lb) | Boolean to create a Network Load Balancer for Boundary. Should be true if downstream workers will connect to these workers. | `bool` | `false` | no |
| <a name="input_ebs_iops"></a> [ebs\_iops](#input\_ebs\_iops) | The amount of IOPS to provision for a `gp3` volume. Must be at least `3000`. | `number` | `3000` | no |
| <a name="input_ebs_is_encrypted"></a> [ebs\_is\_encrypted](#input\_ebs\_is\_encrypted) | Boolean for encrypting the root block device of the Boundary EC2 instance(s). | `bool` | `false` | no |
| <a name="input_ebs_kms_key_arn"></a> [ebs\_kms\_key\_arn](#input\_ebs\_kms\_key\_arn) | ARN of KMS key to encrypt EC2 EBS volumes. | `string` | `null` | no |
| <a name="input_ebs_throughput"></a> [ebs\_throughput](#input\_ebs\_throughput) | The throughput to provision for a `gp3` volume in MB/s. Must be at least `125` MB/s. | `number` | `125` | no |
| <a name="input_ebs_volume_size"></a> [ebs\_volume\_size](#input\_ebs\_volume\_size) | The size (GB) of the root EBS volume for Boundary EC2 instances. Must be at least `50` GB. | `number` | `50` | no |
| <a name="input_ebs_volume_type"></a> [ebs\_volume\_type](#input\_ebs\_volume\_type) | EBS volume type for Boundary EC2 instances. | `string` | `"gp3"` | no |
| <a name="input_ec2_allow_ssm"></a> [ec2\_allow\_ssm](#input\_ec2\_allow\_ssm) | Boolean to attach the `AmazonSSMManagedInstanceCore` policy to the Boundary instance role, allowing the SSM agent (if present) to function. | `bool` | `false` | no |
| <a name="input_ec2_ami_id"></a> [ec2\_ami\_id](#input\_ec2\_ami\_id) | Custom AMI ID for Boundary EC2 Launch Template. If specified, value of `os_distro` must coincide with this custom AMI OS distro. | `string` | `null` | no |
| <a name="input_ec2_instance_size"></a> [ec2\_instance\_size](#input\_ec2\_instance\_size) | EC2 instance type for Boundary EC2 Launch Template. Regions may have different instance types available. | `string` | `"m5.2xlarge"` | no |
| <a name="input_ec2_os_distro"></a> [ec2\_os\_distro](#input\_ec2\_os\_distro) | Linux OS distribution for Boundary EC2 instance. Choose from `amzn2`, `ubuntu`, `rhel`, `centos`. | `string` | `"ubuntu"` | no |
| <a name="input_ec2_ssh_key_pair"></a> [ec2\_ssh\_key\_pair](#input\_ec2\_ssh\_key\_pair) | Name of existing SSH key pair to attach to Boundary EC2 instance. | `string` | `""` | no |
| <a name="input_enable_session_recording"></a> [enable\_session\_recording](#input\_enable\_session\_recording) | Boolean to enable session recording. | `bool` | `false` | no |
| <a name="input_friendly_name_prefix"></a> [friendly\_name\_prefix](#input\_friendly\_name\_prefix) | Friendly name prefix used for uniquely naming AWS resources. This should be unique across all deployments | `string` | n/a | yes |
| <a name="input_hcp_boundary_cluster_id"></a> [hcp\_boundary\_cluster\_id](#input\_hcp\_boundary\_cluster\_id) | ID of the Boundary cluster in HCP. Only used when using HCP Boundary. | `string` | `""` | no |
| <a name="input_kms_endpoint"></a> [kms\_endpoint](#input\_kms\_endpoint) | AWS VPC endpoint for KMS service. | `string` | `""` | no |
| <a name="input_kms_worker_arn"></a> [kms\_worker\_arn](#input\_kms\_worker\_arn) | KMS ID of the worker-auth kms key. | `string` | `""` | no |
| <a name="input_lb_is_internal"></a> [lb\_is\_internal](#input\_lb\_is\_internal) | Boolean to create an internal (private) Proxy load balancer. The `lb_subnet_ids` must be private subnets if this is set to `true`. | `bool` | `true` | no |
| <a name="input_lb_subnet_ids"></a> [lb\_subnet\_ids](#input\_lb\_subnet\_ids) | List of subnet IDs to use for the proxy Network Load Balancer. Unless the lb needs to be publicly exposed (example: downstream Boundary Workers connecting to the ingress workers over the Internet), use private subnets. | `list(string)` | `null` | no |
| <a name="input_sg_allow_ingress_boundary_9202"></a> [sg\_allow\_ingress\_boundary\_9202](#input\_sg\_allow\_ingress\_boundary\_9202) | List of Security Groups to allow ingress traffic on port 9202 to workers. | `list(string)` | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of VPC where Boundary will be deployed. | `string` | n/a | yes |
| <a name="input_worker_is_internal"></a> [worker\_is\_internal](#input\_worker\_is\_internal) | Boolean to create give the worker an internal IP address only or give it an external IP address. | `bool` | `true` | no |
| <a name="input_worker_subnet_ids"></a> [worker\_subnet\_ids](#input\_worker\_subnet\_ids) | List of subnet IDs to use for the EC2 instance. Unless the workers need to be publicly exposed (example: ingress workers), use private subnets. | `list(string)` | n/a | yes |
| <a name="input_worker_tags"></a> [worker\_tags](#input\_worker\_tags) | Map of extra tags to apply to Boundary Worker Configuration. var.common\_tags will be merged with this map. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_boundary_worker_iam_role_name"></a> [boundary\_worker\_iam\_role\_name](#output\_boundary\_worker\_iam\_role\_name) | Name of the IAM role for Boundary Worker instances. |
| <a name="output_proxy_lb_dns_name"></a> [proxy\_lb\_dns\_name](#output\_proxy\_lb\_dns\_name) | DNS name of the Load Balancer. |
<!-- END_TF_DOCS -->
