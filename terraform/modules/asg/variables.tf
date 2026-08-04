variable "region" {
  type    = string
  default = "us-east-1"
}

variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}

variable "security_group_ids" {
    type = list(string)
    default = []
}

variable "node_name_tag" {
    type = string
}

variable "ami_id" {
    type = string
}

variable "min_instances" {
    type = number
    default = 2
}

variable "asg_name" {
    type = string
}

variable "max_instances" {
    type = number
    default = 4
}

variable "subnet_ids" {
    type = list(string)
}

variable "target_group_arns" {
    description = "target group ARNs"
    type = list(string)
    default = [] 
}

variable "userdata_base64" {
    type = string
    default = ""
}

variable "instance_profile" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
    type = string
    default = ""
}
