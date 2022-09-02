###########################################
##   Create instance with Fedora Coreos  ##
##########################################

#===============instance==================#

resource "aws_instance" "app_server" {
  ami             = local.instance_ami
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.my_webserver.id]
  tags = {
    Name = "Study AppServer"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.38"
    }
  }

  required_version = ">= 0.15.3"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-3"
}


locals {
  # FEDORA-COREOS
  instance_ami = "ami-09e2e5104f310ffb5"
}

#=====================security group=====================#

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "my_webserver" {
  name        = "WebServer Security Group"
  vpc_id      = data.aws_vpc.default.id
  description = "tcp/http/icmp"

  dynamic "ingress" {

    for_each = var.allow_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name  = "web server"
    Owner = "MaksK"
  }
}

variable "allow_ports" {
  description = "List of Ports to open for server"
  type        = list(any)
  default     = ["80", "443"]
}
