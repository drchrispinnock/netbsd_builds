terraform {
  backend "remote" {
    organization = "estuary"

    workspaces {
      name = "test"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwG4c7d+0EBfhZw3thStTOmELYIxczSeeuHuzGW8VtWXdpXeEakf1ce52Zxlxm+cO2kcPC/rpQHVdBbBcWo8D+juAHat301wMqG455JEiR2W09dECXI/JY9++ZITk+Qp/cCUbPh5dQvq1BM0oT8c0vHIt/Txhy7VYePFh6f7yrSTwcR7Vaoxah/+hsOt4XarHHdHqaO+oO13iPlIY8k+XoPMHSezbB8HlyFDcKPjQXuakebAeVxfndjHH14tpCrKsYmIFKQFzu6yGFCUBEm0/iHTZ+Uf2k49aq0X7nKlWqm4vNALYsfjn42wlECUOlp77/rAxw5dElc2jdUOdXENqT chrispinnock@Chriss-MBP-2.home"
}

resource "aws_instance" "freebsd-13" {
  ami                    = var.freebsd-13-ami
  instance_type          = "t3.xlarge"
  vpc_security_group_ids = ["sg-8f283bee"]
  key_name               = "deployer-key"
	ebs_block_device {
	    device_name = "/dev/sda1"
	    volume_size = 30
  	}
  tags = {
    Name = "FreeBSD 13 Build Server"
  }
}

resource "aws_instance" "debian-10" {
  ami                    = var.debian-10-ami
  instance_type          = "t3.xlarge"
  vpc_security_group_ids = ["sg-8f283bee"]
  key_name               = "deployer-key"
	ebs_block_device {
	    device_name = "/dev/sda1"
	    volume_size = 30
  	}
  tags = {
    Name = "Debian 10 Build Server"
  }
}
