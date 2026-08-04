variable "region" {
  type    = string
  default = "us-east-1"
}

variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}

variable "instance_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "instance_role" {
  type = string
}

variable "spot_type" {
  type    = string
  default = "one-time"
}

variable "userdata_base64" {
  type = string
  default = ""
}

variable "persistent_spot_settings" {
  description = "persistent spot type instance settings"
  type        = map(any)
  default = {
    enabled = false
  }
}

variable "ami_id" {
  type    = string
  default = "ami-024ee5112d03921e2"
}

variable "subnet_id" {
  type = string
}

variable "sg_id" {
  description = "Security group name"
  type        = string
}

variable "ssh_key" {
  type = string
}

variable "valid_until_hrs" {
  type    = string
  default = "2h" # Use 2 hr validity for spot request
}

variable "tags" {
  type    = map(string)
  default = {}
}