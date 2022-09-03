############################################################
##             Create instance with Fedora Coreos         ##
##               security group, ssh-poseidon,            ##
##               IGW, Routing, Subnet, ElasticIP          ##
##                 Created by Maksim Kulikov              ##
############################################################


#=====================security group=====================#

data "aws_vpc" "dev_vpc" {
  tags = {
    Name = "dev"
  }
}

data "aws_availability_zones" "available" {}

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
  availability_zone       = data.aws_availability_zones.available.names[count.index]
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
/*
data "aws_subnet" "public_subnets" {
  tags = {
    Name = "development-public-1"
    Name = "development-public-2"
  }
  depends_on = [aws_subnet.public_subnets]
}
*/

#=====================IGW,Routing=======================#

resource "aws_internet_gateway" "main" {
  vpc_id = data.aws_vpc.dev_vpc.id
  tags = {
    Name = "${var.env}-igw"
  }
}

resource "aws_route_table" "public_subnets" {
  count  = length(var.public_subnet_cidrs)
  vpc_id = data.aws_vpc.dev_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.env}-route-public-subnets"
  }
}

resource "aws_route_table_association" "public_routes" {
  count          = length(aws_subnet.public_subnets[*].id)
  route_table_id = element(aws_route_table.public_subnets[*].id, count.index)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}
#===================Elastic-IP=============================#
##3nd phase
resource "aws_eip" "eip" {
  count = length(var.public_subnet_cidrs)
  vpc   = true
  tags = {
    Name = "${var.env}-gw-${count.index + 1}"
  }
}

resource "aws_eip_association" "eip_assoc" {
  count         = length(aws_eip.eip[*].id)
  instance_id   = element(aws_instance.app_server[*].id, count.index)
  allocation_id = element(aws_eip.eip[*].id, count.index)
}
##3nd phase
#=====================instance=============================#

resource "aws_instance" "app_server" {
  ami                    = local.instance_ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  count                  = length(aws_subnet.public_subnets[*].id)
  subnet_id              = element(aws_subnet.public_subnets[*].id, count.index)
  user_data              = data.ct_config.config.rendered
  tags = {
    Name = "Study AppServer"
  }
}


terraform {
  required_providers {

    ct = {
      source  = "poseidon/ct"
      version = "0.8.0"
    }

    docker = {
      source  = "kreuzwerker/docker"
      version = "2.11.0"
    }

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

provider "ct" {}


locals {

  instance_ami = "ami-0ca82f640eae28513"
}

#================SSH-Poseidon provider=================#



locals {
  instance_key_file = "ssh_keys/id_rsa_instance_key.pub"
  instance_user     = "core"

}

data "ct_config" "config" {
  content = templatefile("cfg.tpl", {
    key  = file(local.instance_key_file),
    user = local.instance_user
  })
  strict = true
}

#==============Create docker container=================#

##2 phase
provider "docker" {
  #host = "ssh://${local.instance_user}@${aws_instance.app_server[0].public_ip}:22"
  host = "ssh://${local.instance_user}@${aws_eip.eip[1].public_ip}:22"
}

resource "docker_image" "ruby-test-app" {
  name = "kayerosaint/ruby-test-app:latest"
}

resource "docker_container" "ruby-test-app" {
  image   = docker_image.ruby-test-app.latest
  name    = "ruby-test-app"
  restart = "unless-stopped"
  env = [
    "PORT=4000",
  ]
  ports {
    internal = 4000
    external = 80
  }
}
##2 phase
