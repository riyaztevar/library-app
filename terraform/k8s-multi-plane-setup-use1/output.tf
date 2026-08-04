# output "k8s_nodes" {
#     value=module.asg[*].name
# }

output "bastion_public_ip" {
    value = module.bastion.ec2_data.public_ip
}

output "control_node_ip" {
  value = data.aws_instance.control_plane_node.private_ip
}

output "data_node_ip" {
  value = data.aws_instance.data_plane_node.private_ip
}
