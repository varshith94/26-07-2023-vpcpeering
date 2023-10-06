resource "aws_vpc" "prod" {
    provider = aws.central
    cidr_block = var.cidr_blocks1
    enable_dns_hostnames = true
    tags = {
        "Name" = "${var.vpcs_name}"
    }

}

resource "aws_internet_gateway" "prodigw" {
    provider = aws.central
    vpc_id = aws_vpc.prod.id
    tags = {
        "Name" = "${var.vpcs_name}-igw"
    }
  
}

resource "aws_subnet" "publics" {
    provider = aws.central
    count = 3
vpc_id = aws_vpc.prod.id
cidr_block = element(var.cidr_block_subnets,count.index+1) 
availability_zone = element(var.azs1,count.index+1)
map_public_ip_on_launch = true
tags = {
    "Name" = "${var.vpcs_name}-public${count.index+1}"
}
}

resource "aws_route_table" "rtable" {
    provider = aws.central
    vpc_id = aws_vpc.prod.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.prodigw.id
    }
      tags = {
        "Name" = "${var.vpcs_name}-rt"
      }
}

resource "aws_route_table_association" "publicsubnet" {
    provider = aws.central
    count = 3
    subnet_id = element(aws_subnet.publics.*.id,count.index+1) 
    route_table_id = aws_route_table.rtable.id 
}
resource "aws_route" "connection" {
    provider = aws.central
    destination_cidr_block = var.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.owner.id
      route_table_id = aws_route_table.rtable.id
  
}
resource "aws_security_group" "prod-sg" {
    provider = aws.central
    vpc_id = aws_vpc.prod.id
    name = "allow all rules"
    description = "allow inbound and outbound rules"
    tags = {
        "Name" = "${var.vpcs_name}-sg"
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
 
 resource "aws_instance" "prodserver" {
    provider = aws.central
    count = 1
    ami = "ami-024e6efaf93d85776"
    instance_type = "t2.micro"
    key_name = "krishika"
    vpc_security_group_ids = [aws_security_group.prod-sg.id]
    subnet_id = element(aws_subnet.publics.*.id,count.index+1)
    associate_public_ip_address = true
    tags = {
        "Name" = "${var.vpcs_name}-server${count.index+1}"
    }
   
 }

