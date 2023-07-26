resource "aws_vpc" "dev" {
    cidr_block = var.cidr_block
    enable_dns_hostnames = true
    tags = {
        "Name" = "${var.vpc_name}"
    }

}

resource "aws_internet_gateway" "devigw" {
    vpc_id = aws_vpc.dev.id
    tags = {
        "Name" = "${var.vpc_name}-igw"
    }
  
}

resource "aws_subnet" "public1" {
    count = 3
vpc_id = aws_vpc.dev.id
cidr_block = element(var.cidr_block_subnet,count.index+1) 
availability_zone = element(var.azs,count.index+1)
map_public_ip_on_launch = true
tags = {
    "Name" = "${var.vpc_name}-public${count.index+1}"
}
}

resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.dev.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.devigw.id
    }
      tags = {
        "Name" = "${var.vpc_name}-rt"
      }
}

resource "aws_route_table_association" "publicsubnets" {
    count = 3
    subnet_id = element(aws_subnet.public1.*.id,count.index+1) 
    route_table_id = aws_route_table.rt.id 
}
resource "aws_route" "communications" {
    vpc_peering_connection_id = aws_vpc_peering_connection.owner.id
    destination_cidr_block = var.cidr_block1
    route_table_id = aws_route_table.rt.id
  
}

resource "aws_security_group" "dev-sg" {
    vpc_id = aws_vpc.dev.id
    name = "allow all rules"
    description = "allow inbound and outbound rules"
    tags = {
        "Name" = "${var.vpc_name}-sg"
    }
    ingress {
        description = "allow only inbound rules"
        to_port = 0
        from_port = 0
        protocol   = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
            description = "allow only outbound rules"
        to_port = 0
        from_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}
 
 resource "aws_instance" "webserver" {
    count = 1
    ami = "ami-0261755bbcb8c4a84"
    instance_type = "t2.micro"
    key_name = "krishika"
    vpc_security_group_ids = [aws_security_group.dev-sg.id]
    subnet_id = element(aws_subnet.public1.*.id,count.index+1)
    associate_public_ip_address = true
    tags = {
        "Name" = "${var.vpc_name}-server${count.index+1}"
    }
   
 }

