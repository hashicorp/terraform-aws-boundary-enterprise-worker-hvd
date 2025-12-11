# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

data "aws_iam_role" "boundary_ec2" {
  count = var.create_boundary_worker_role ? 0 : 1

  name = var.boundary_worker_iam_role_name
}


data "aws_iam_policy_document" "assume_role_policy" {
  count = var.create_boundary_worker_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "boundary_kms" {
  count = var.create_boundary_worker_role && var.kms_worker_arn != "" ? 1 : 0

  statement {
    sid    = "BoundaryKMSKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*"
    ]
    resources = [
      data.aws_kms_key.worker[0].arn
    ]
  }
}

data "aws_iam_policy_document" "boundary_session_recording_kms" {
  count = var.create_boundary_worker_role && var.enable_session_recording ? 1 : 0

  statement {
    sid    = "BoundarySessionRecordingS3"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectAttributes",
      "s3:DeleteObject",
      "s3:ListBucket"

    ]
    resources = [
      var.bsr_s3_bucket_arn,
      "${var.bsr_s3_bucket_arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "ec2_allow_ebs_kms_cmk" {
  count = var.ebs_kms_key_arn != null ? 1 : 0

  statement {
    sid    = "BoundaryEc2AllowEbsKmsCmk"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:GenerateDataKey*"
    ]
    resources = [
      var.ebs_kms_key_arn
    ]
  }
}

data "aws_iam_policy_document" "combined" {
  count = var.create_boundary_worker_role ? 1 : 0

  source_policy_documents = [
    var.kms_worker_arn != "" ? data.aws_iam_policy_document.boundary_kms[0].json : "",
    var.enable_session_recording ? data.aws_iam_policy_document.boundary_session_recording_kms[0].json : "",
    var.ebs_kms_key_arn != null ? data.aws_iam_policy_document.ec2_allow_ebs_kms_cmk[0].json : ""
  ]
}

resource "aws_iam_role_policy" "boundary_ec2" {
  count = var.create_boundary_worker_role ? 1 : 0

  name   = "${var.friendly_name_prefix}-boundary-worker-instance-role-policy-${data.aws_region.current.name}"
  role   = aws_iam_role.boundary_ec2[0].id
  policy = data.aws_iam_policy_document.combined[0].json
}

resource "aws_iam_instance_profile" "boundary_ec2" {

  name = "${var.friendly_name_prefix}-boundary-worker-instance-profile-${data.aws_region.current.name}"
  path = "/"
  role = var.boundary_worker_iam_role_name == null ? aws_iam_role.boundary_ec2[0].name : data.aws_iam_role.boundary_ec2[0].name
}

resource "aws_iam_role_policy_attachment" "aws_ssm" {
  count = var.create_boundary_worker_role && var.ec2_allow_ssm ? 1 : 0

  role       = aws_iam_role.boundary_ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "boundary_ec2" {
  count = var.create_boundary_worker_role ? 1 : 0

  name               = "${var.friendly_name_prefix}-boundary-worker-instance-role-${data.aws_region.current.name}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy[0].json

  tags = merge({ "Name" = "${var.friendly_name_prefix}-boundary-worker-instance-role" }, var.common_tags)
}
