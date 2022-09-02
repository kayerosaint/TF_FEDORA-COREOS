############################################################
##             Create instance with Fedora Coreos         ##
##               security group, ssh-poseidon             ##
##                                                        ##
############################################################


#=====================security group=====================#

data "aws_vpc" "dev_vpc" {
  tags = {
    Name = "dev"
  }
}


resource "aws_security_group" "my_webserver" {
  name        = "WebServer Security Group"
  vpc_id      = data.aws_vpc.dev_vpc.id
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
  default     = ["80", "443", "22"]
}


#==================Create Subnet=======================#

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = data.aws_vpc.dev_vpc.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.env}-public-${count.index + 1}"
  }
}

variable "env" {
  default = "development"
}

variable "public_subnet_cidrs" {
  default = [
    "10.0.8.0/24",
    "10.0.9.0/24",
  ]
}

data "aws_subnet" "public_subnets" {
  tags = {
    Name = "development-public-1"
  }
  depends_on = [aws_subnet.public_subnets]
}

#=====================instance=============================#

resource "aws_instance" "app_server" {
  ami                    = local.instance_ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  subnet_id              = data.aws_subnet.public_subnets.id
  #user_data       = data.ct_config.config.rendered
  tags = {
    Name = "Study AppServer"
  }
}



terraform {
  required_providers {
    /*
    ct = {
      source  = "poseidon/ct"
      version = "0.8.0"
    }
*/
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

# provider "ct" {}


locals {
  # FEDORA-COREOS
  instance_ami = "ami-0ca82f640eae28513"
}

#================SSH-Poseidon provider=================#

/*

locals {
  instance_key_file = "ssh_keys/id_rsa_instance_key.pub"
  instance_user     = "core"
  #...
}

data "ct_config" "config" {
  content = templatefile("cfg.tpl", {
    key  = file(local.instance_key_file),
    user = local.instance_user
  })
  strict = true
}
*/
