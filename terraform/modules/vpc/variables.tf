variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "newbits" {
  type = number
  default = 8
}

variable "region" {
  type = string
  default = "us-east-1"
}

variable "tags" {
    type = map(string)
    default = {
    App = "my_vpc_project"
    }
}

variable "azs" {
    type = list(string)
    default = [ "us-east-1a", "us-east-1b"]
  
}