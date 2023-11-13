variable "region" {}
variable "key_name" {}
variable "az" {}
variable "access_key" {}
variable "secret_key" {}
variable "volume_id" {}

provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

data "aws_ami" "bitnami-ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["bitnami-wordpress-*-linux-debian-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "bitnami_instance" {
  # ami                    = aws_ami.myami.id # for recovery only !
  ami                    = data.aws_ami.bitnami-ami.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  availability_zone      = var.az
  vpc_security_group_ids = [aws_security_group.ssh_security_group.id]

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
    # this will be used for recovery 
    # if ec2 down -> create snapshot -> create ami from snapshot -> run new ec2 from ami
    delete_on_termination = false
    encrypted             = false
  }
}

resource "aws_security_group" "ssh_security_group" {
  name        = "ssh-security-group"
  description = "Allow inbound SSH and all outbound traffic"

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "ami" {
  value = data.aws_ami.bitnami-ami.id
}

