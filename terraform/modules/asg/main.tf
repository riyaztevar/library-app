resource "aws_launch_template" "k8s_spot_instance" {
  name_prefix   = "k8s-node-template"
  instance_type = var.instance_type
  image_id      = var.ami_id # Replace with your target standard AMI (e.g., Amazon Linux 2023)
  user_data = var.userdata_base64
  key_name = var.key_name
  iam_instance_profile {
    name = var.instance_profile
  }
  network_interfaces {
    associate_public_ip_address = false
    security_groups = var.security_group_ids # References your private app SG
  }

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = var.node_name_tag 
    }
  }
}

resource "aws_autoscaling_group" "k8s_asg" {
  name = var.asg_name
  min_size            = var.min_instances
  max_size            = var.max_instances
  desired_capacity    = var.min_instances # Initial capacity matches the minimum
  vpc_zone_identifier = var.subnet_ids # Spread across AZs

  #target_group_arns   = var.target_group_arns # Hooks up to your ALB Target Group
  #health_check_type   = "ELB"
  #health_check_grace_period = 300
  launch_template {
    id = aws_launch_template.k8s_spot_instance.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [desired_capacity] # Prevents Terraform applies from overriding running capacity adjustments
  }
}
