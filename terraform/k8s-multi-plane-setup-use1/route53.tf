data "aws_route53_zone" "sandbox" {
  name         = "mysandbox.net.in"
  private_zone = false
}

data "aws_instance" "control_plane_node" {
  filter {
    name   = "tag:Name"
    values = ["node_control_plane"]
  }
  depends_on = [ module.asg ]
}

data "aws_instance" "data_plane_node" {
  filter {
    name   = "tag:Name"
    values = ["node_data_plane"]
  }
  depends_on = [ module.asg ]
}

resource "aws_route53_record" "bastion_record" {
  zone_id = data.aws_route53_zone.sandbox.zone_id
  name    = "bastion.pub"
  type    = "A"
  ttl     = 300
  records = [ 
	module.bastion.ec2_data.public_ip
  ]
}

resource "aws_route53_record" "ctl_plane_record" {
  zone_id = data.aws_route53_zone.sandbox.zone_id
  name    = "ctl-plane"
  type    = "A"
  ttl     = 300
  records = [ 
	data.aws_instance.control_plane_node.private_ip
  ]
}
