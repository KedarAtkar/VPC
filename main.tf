resource "aws_vpc" "myVPC" {
  cidr_block = "10.0.0.0/16"  
}

resource "aws_subnet" "privateSubnet" {
    vpc_id     = aws_vpc.myVPC.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1a"
}

resource "aws_subnet" "publicSubnet" {
  vpc_id = aws_vpc.myVPC.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-south-1a"
}

resource "aws_route_table" "privateSubnetRT" {
  vpc_id = aws_vpc.myVPC.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myVPC.id
}

resource "aws_route_table" "publicSubnetRT" {
  vpc_id = aws_vpc.myVPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "privateSubnetRTA" {
  subnet_id      = aws_subnet.privateSubnet.id
  route_table_id = aws_route_table.privateSubnetRT.id
}

resource "aws_route_table_association" "publicSubnetRTA" {
  subnet_id      = aws_subnet.publicSubnet.id
  route_table_id = aws_route_table.publicSubnetRT.id
}

resource "aws_security_group" "publicInstanceSG" {
  name        = "publicInstanceSG"
  vpc_id      = aws_vpc.myVPC.id
}

resource "aws_vpc_security_group_ingress_rule" "publicInstanceSGHTTPIngress" {
  security_group_id = aws_security_group.publicInstanceSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "HTTP trafic"
}

resource "aws_vpc_security_group_ingress_rule" "publicInstanceSGTCPIngress" {
    description = "SSH"
    security_group_id = aws_security_group.publicInstanceSG.id
    cidr_ipv4   = "0.0.0.0/0"
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "publicInstanceSGHTTPEgress" {
  security_group_id = aws_security_group.publicInstanceSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_instance" "publicInstance1" {
  ami = "ami-0d63de463e6604d0a"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.publicSubnet.id
  vpc_security_group_ids = [aws_security_group.publicInstanceSG.id]
  user_data              = base64encode(file("userdata.sh"))
}

resource "aws_security_group" "privateInstanceSG" {
  name        = "privateInstanceSG"
  vpc_id      = aws_vpc.myVPC.id
}

resource "aws_vpc_security_group_ingress_rule" "privateInstanceSGTCPIngress" {
    description = "SSH"
    security_group_id = aws_security_group.privateInstanceSG.id
    cidr_ipv4   = "0.0.0.0/0"
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
}

resource "aws_security_group_rule" "privateInstanceSGICMPIngress" {
  description = "ICMP"
  type = "ingress"
  from_port   = -1
  to_port     = -1
  security_group_id = aws_security_group.privateInstanceSG.id
  protocol = "ICMP"
  source_security_group_id = aws_security_group.publicInstanceSG.id
}

resource "aws_vpc_security_group_egress_rule" "privateInstanceSGHTTPEgress" {
  security_group_id = aws_security_group.privateInstanceSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_instance" "privateInstance1" {
  ami = "ami-0d63de463e6604d0a"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.privateSubnet.id
  vpc_security_group_ids = [aws_security_group.privateInstanceSG.id]
}