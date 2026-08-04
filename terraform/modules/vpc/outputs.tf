output "priv_subnet_ids" {
    value = aws_subnet.private[*].id
}

output "public_subnet_ids" {
    value = aws_subnet.public[*].id
  
}

#output "target_grp_arn" {
#    value = aws_lb_target_group.app_target_group.arn
#}

output "public_sg_id" {
    value = aws_security_group.public_sg.id
}

output "private_sg_id" {
    value = aws_security_group.private_sg.id
  
}
