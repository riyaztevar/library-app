resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  tags = merge(var.tags, {
    Name = "my-vpc"
  })
}

resource "aws_subnet" "public" {
    count = length(var.azs)
    vpc_id = aws_vpc.my_vpc.id
    availability_zone = var.azs[count.index]
    cidr_block = cidrsubnet(var.vpc_cidr, var.newbits, count.index)
    tags = merge(var.tags, {
        Name = "pub${count.index}"
    })
}

resource "aws_subnet" "private" {
    count = length(var.azs)
    vpc_id = aws_vpc.my_vpc.id
    availability_zone = var.azs[count.index]
    cidr_block = cidrsubnet(var.vpc_cidr, var.newbits, 2+count.index)
    tags = merge(var.tags, {
        Name = "priv${count.index}"
    })
}

#internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = var.tags
}

#nat gateway
resource "aws_eip" "eip" {
    region = var.region
    count = length(var.azs)
    depends_on = [ aws_internet_gateway.igw ]
    domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
    count = length(var.azs)
    allocation_id = aws_eip.eip[count.index].id
    subnet_id = aws_subnet.public[count.index].id
    depends_on = [ aws_internet_gateway.igw ]
    tags = merge(var.tags, {
        Name = "nat-${var.azs[count.index]}"
    })
}

#public route table
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.my_vpc.id
    route  {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

#public rt assoc
resource "aws_route_table_association" "pub_rt_assoc" {
    count = length(var.azs)
    route_table_id = aws_route_table.public_rt.id
    subnet_id = aws_subnet.public[count.index].id
}

#private route table
resource "aws_route_table" "priv_rt" {
    count = length(var.azs)
    vpc_id = aws_vpc.my_vpc.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat[count.index].id
    }
}

#priv rt assoc
resource "aws_route_table_association" "priv_rt_assoc" {
    count = length(var.azs)
    route_table_id = aws_route_table.priv_rt[count.index].id
    subnet_id = aws_subnet.private[count.index].id
}


#public nacl
resource "aws_network_acl" "pub_nacl" {
    vpc_id = aws_vpc.my_vpc.id
    subnet_ids = aws_subnet.public[*].id
    ingress {
        rule_no = 100
        action = "allow"
        protocol = "tcp"
        from_port = 80
        to_port = 80
        cidr_block = "0.0.0.0/0"
        }
    ingress {
        rule_no = 200
        action = "allow"
        protocol = "tcp"
        from_port = 443
        to_port = 443
        cidr_block = "0.0.0.0/0"
    }
        ingress {
        rule_no = 300
        action = "allow"
        protocol = "tcp"
        from_port = 8080
        to_port = 8080
        cidr_block = "0.0.0.0/0"
    }
    ingress {
        rule_no = 400
        action = "allow"
        protocol = "tcp"
        from_port = 22
        to_port = 22
        cidr_block = "0.0.0.0/0"
    }
    ingress {
        rule_no = 500
        action = "allow"
        protocol = "tcp"
        from_port = 1024
        to_port = 65535
        cidr_block = "0.0.0.0/0"
    }
    egress {
        rule_no = 100
        action = "allow"
        protocol = -1
        from_port = 0
        to_port = 0
        cidr_block = "0.0.0.0/0"
    }
}

#private nacl
resource "aws_network_acl" "priv_nacl" {
    vpc_id = aws_vpc.my_vpc.id
    subnet_ids = aws_subnet.private[*].id
    ingress {
        rule_no = 100
        action = "allow"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_block = aws_vpc.my_vpc.cidr_block
    }
    ingress {
        rule_no = 200
        action = "allow"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_block = aws_vpc.my_vpc.cidr_block
    }
    ingress {
        rule_no = 300
        action = "allow"
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_block = aws_vpc.my_vpc.cidr_block
    }
     ingress {
        rule_no    = 400
        protocol   = "tcp"
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 1024
        to_port    = 65535
    }

    egress {
        rule_no = 100
        action = "allow"
        protocol = -1
        from_port = 0
        to_port = 0
        cidr_block = "0.0.0.0/0"
    }
}

#public sec. group
resource "aws_security_group" "public_sg" {
  name   = "public-sg"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#private sec. group
resource "aws_security_group" "private_sg" {
  name   = "private-sg"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups =[ aws_security_group.public_sg.id ]
    #cidr_blocks = [ aws_vpc.my_vpc.cidr_block ]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    #security_groups = [ aws_security_group.alb-sg.id ]
    cidr_blocks = [ aws_vpc.my_vpc.cidr_block ]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    # security_groups = [ aws_security_group.alb-sg.id ]
    cidr_blocks = [ aws_vpc.my_vpc.cidr_block ]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #security_groups = [ aws_security_group.alb-sg.id ]
    cidr_blocks = [ aws_vpc.my_vpc.cidr_block ]
  }
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    #security_groups = [ aws_security_group.alb-sg.id ]
    cidr_blocks = [ aws_vpc.my_vpc.cidr_block ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

