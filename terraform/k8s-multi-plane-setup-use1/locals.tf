locals {
  azs                 = ["us-east-1a", "us-east-1b"]
  region              = "us-east-1"
  vpc_cidr            = "10.0.0.0/16"
  app_userdata_base64 = base64encode(file("${path.module}/scripts/app-userdata.sh"))

  images = {
    amz_lnx = "ami-024ee5112d03921e2" #amz linux
    rhel10  = "ami-0ad50334604831820" #rhel 10
    rhel9   = "ami-09e973f123c32cf86" #rhel 9
  }
  valid_until_hrs = 2
  ami_id          = local.images.rhel9
  #type      = "t3.medium" #4G,2vcpu
  bastion_ec2_type = "t3.micro" #1G,2vcpu
  node_ec2_type    = "t3.small" #2G,2vcpu

  subnet                  = "subnet-pub"
  public_sg               = true
  bastion_userdata_base64 = base64encode(file("${path.module}/scripts/bastion-userdata.sh"))
  nodes = {
    control_plane = {
      node_name_tag = "node_control_plane"
      node_ec2_type    = "t3.small" #2G,2vcpu
      min_instances = 1
      max_instances = 1
    }
    data_plane = {
      node_name_tag = "node_data_plane"
      node_ec2_type    = "t3.small" #2G,2vcpu
      min_instances = 1
      max_instances = 2
     }
  }


}
