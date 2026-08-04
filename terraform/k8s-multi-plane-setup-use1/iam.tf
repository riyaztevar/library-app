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

locals {
  policies = [
    "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicyV2",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

# 3. Attach the AWS-Managed Policy to the Role
resource "aws_iam_role_policy_attachment" "ebs_csidriver_policy" {
  for_each   = toset(local.policies)
  role       = aws_iam_role.ec2_role.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "k8s_node_instance_profile"
  role = aws_iam_role.ec2_role.name
}
