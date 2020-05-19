### ---------------------------------------------------------------------------------------------------------------------
# THESE TEMPLATES REQUIRE TERRAFORM VERSION 0.12 AND ABOVE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH AN IAM POLICY THAT ALLOWS THE CONSUL NODES TO AUTOMATICALLY DISCOVER EACH OTHER AND FORM A CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role_policy" "auto_discover_cluster" {
  count  = var.enabled ? 1 : 0
  name   = "auto-discover-cluster"
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.auto_discover_cluster.json
}

data "aws_iam_policy_document" "auto_discover_cluster" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "autoscaling:DescribeAutoScalingGroups",
    ]

    resources = ["*"]
  }
}

# Additionally, if desired, add the necessary policy to allow snapshots to s3 buckets


resource "aws_iam_role_policy" "snapshot_agent_to_s3" {
  count  = "${var.enabled && var.enable_snapshot_agent}" ? 1 : 0
  name   = "consul-snapshot-agent"
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.snapshot_agent_to_s3[0].json
}

data "aws_iam_policy_document" "snapshot_agent_to_s3" {
  count = "${var.enabled && var.enable_snapshot_agent}" ? 1 : 0
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:ListBucketVersions"
    ]

    resources = ["arn:aws:s3:::${var.snapshot_agent_bucket}"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = ["arn:aws:s3:::${var.snapshot_agent_bucket}/${var.snapshot_agent_s3_key_prefix}*.snap"]
  }
}
