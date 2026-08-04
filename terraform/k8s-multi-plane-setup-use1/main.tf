module "vpc_infra" {
  source = "../modules/vpc"
  azs    = local.azs
}

module "asg" {
  source        = "../modules/asg"
  for_each = local.nodes
  asg_name = each.key
  instance_type = each.value.node_ec2_type
  min_instances = each.value.min_instances
  max_instances = each.value.max_instances
  subnet_ids    = module.vpc_infra.priv_subnet_ids
  # target_group_arns = [
  #  module.vpc_infra.target_grp_arn
  # ]
  ami_id        = local.images.rhel9
  security_group_ids = [
    module.vpc_infra.private_sg_id
  ]
  instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  key_name         = aws_key_pair.ssh_key.id
  userdata_base64  = each.value.userdata_file 
  node_name_tag    = each.value.node_name_tag
}


module "bastion" {
  source            = "../modules/ec2"
  instance_name     = "bastion-box"
  region            = local.region
  availability_zone = local.azs[0]

  ami_id          = local.ami_id
  instance_type   = local.bastion_ec2_type
  subnet_id       = module.vpc_infra.public_subnet_ids[0]
  sg_id           = module.vpc_infra.public_sg_id
  userdata_base64 = try(local.bastion_userdata_base64, "")
  ssh_key         = aws_key_pair.ssh_key.id
  valid_until_hrs = local.valid_until_hrs
  depends_on = [aws_key_pair.ssh_key
  ]
  instance_role = "troubleshoot"
}
