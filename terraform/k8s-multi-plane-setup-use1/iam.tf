# 2. Create the IAM Role
resource "aws_iam_role" "ec2_role" {
  name = "k8s-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "bastion_role" {
  name = "bastion-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "secrets_reader" {
  statement {
    sid    = "AllowReadSecretValue"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:us-east-1:953909302469:secret:*"
    ]
  }
  statement {
    sid = "Allowec2Describe"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }
}

# Secret read policy for bastion
resource "aws_iam_policy" "secrets_reader" {
  name        = "secrets-reader-policy"
  description = "Grants permission to read Secrets Manager secret"
  policy      = data.aws_iam_policy_document.secrets_reader.json
}

# lb controller policy loaded from json file
resource "aws_iam_policy" "lb_policy" {
  name        = "lb_controller_policy"
  description = "IAM policy loaded directly from the JSON file"
  policy = file("${path.module}/lb_controller_policy.json")
}

# aws managed policies for k8s nodes
locals {
  inline_policies = { 
    ebs_csi_driver_policy: "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicyV2",
    container_registry_readonly_policy: "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    lb_controller_poliy: aws_iam_policy.lb_policy.arn,
   cni_policy: "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  }
}

#3. Attach the AWS-Managed Policies to the Role
resource "aws_iam_role_policy_attachment" "ebs_csidriver_policy" {
  for_each   = local.inline_policies
  role       = aws_iam_role.ec2_role.name
  policy_arn = each.value
}


# bastion policy attachment
resource "aws_iam_role_policy_attachment" "bastion_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = aws_iam_policy.secrets_reader.arn
}

#k8s nodes instance profile
resource "aws_iam_instance_profile" "nodes_instance_profile" {
  name = "k8s_node_instance_profile"
  role = aws_iam_role.ec2_role.name
}

# bastion instance profile
resource "aws_iam_instance_profile" "bastion_instance_profile" {
  name = "bastion_instance_profile"
  role = aws_iam_role.bastion_role.name
}
