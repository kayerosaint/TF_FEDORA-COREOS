###########################################
##   Create instance with Fedora Coreos  ##
###########################################


resource "aws_instance" "app_server" {
  ami           = local.instance_ami
  instance_type = "t2.micro"

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
