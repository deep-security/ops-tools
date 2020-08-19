provider "aws" {
  region = "us-east-1"
}

# (Optional) backend configuration to manage terraform state file via S3. 
#terraform {
#  backend "s3" {
#    bucket  = "terraform-state-bucket"
#    key     = "environment/trend-micro-deep-security/terraform.tfstate"
#    region  = "us-east-1"
#    encrypt = "true"
#  }
#}

data "aws_iam_policy_document" "tmds_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.tmds_aws_account_id}:root"]
    }

    condition {
      test = "StringEquals"
      variable = "sts:ExternalId"

      values = [var.external_id]
    }
  }
}

data "aws_iam_policy_document" "tmds_role_policy_document" {
  statement {
    actions = [
      "ec2:DescribeRegions",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "iam:ListAccountAlias"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "iam:GetRole",
      "iam:GetRolePolicy"
    ]

    resources = [aws_iam_role.tmds_role.arn]
  }

  statement {
    actions = [
      "workspaces:DescribeWorkspaces",
      "workspaces:DescribeWorkspaceDirectories",
      "workspaces:DescribeWorkspaceBundles",
      "workspaces:DescribeTags"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "tmds_role_policy" {
  name   = "${var.environment}-${var.service_name}-role-policy"
  policy = data.aws_iam_policy_document.tmds_role_policy_document.json
}

resource "aws_iam_role_policy_attachment" "tmds_role_policy_attachment" {
  role       = aws_iam_role.tmds_role.id
  policy_arn = aws_iam_policy.tmds_role_policy.arn
}

resource "aws_iam_role" "tmds_role" {
  name               = "${var.environment}-${var.service_name}"
  assume_role_policy = data.aws_iam_policy_document.tmds_assume_role_policy.json
}
