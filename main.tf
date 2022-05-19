provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

resource "aws_vpc" "clir-test-aws_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    "Name" = var.tag_name
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.clir-test-aws_vpc.id

  tags = {
    "Name" = var.tag_name
  }
}

resource "aws_route_table" "clir-test-rt" {
  vpc_id = aws_vpc.clir-test-aws_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    "Name" = var.tag_name
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.clir-test-aws_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2c"

  tags = {
    "Name" = var.tag_name
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.clir-test-rt.id
}

resource "aws_security_group" "allow_ssh" {
  vpc_id      = aws_vpc.clir-test-aws_vpc.id
  name        = "allow_ssh"
  description = "allow ssh"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  tags = {
    "Name" = var.tag_name
  }
}

resource "aws_network_interface" "clir-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ip      = "10.0.1.151"
  security_groups = [aws_security_group.allow_ssh.id]

  tags = {
    "Name" = var.tag_name
  }
}

resource "aws_eip" "one" {
  associate_with_private_ip = "10.0.1.151"
  network_interface         = aws_network_interface.clir-nic.id
  depends_on = [
    aws_internet_gateway.gw
  ]
  vpc = var.eip_vpc
}

resource "aws_instance" "clir-test-ec2" {
  ami               = "ami-0ca285d4c2cda3300"
  instance_type     = "t2.micro"
  availability_zone = "us-west-2c"
  key_name          = "vpn-new"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.clir-nic.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF
  tags = {
    "Name" = var.tag_name
  }
}