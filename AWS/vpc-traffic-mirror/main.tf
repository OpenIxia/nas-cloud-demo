terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = var.aws_profile
  region = var.aws_region
  #max_retries = 1
}

resource "aws_vpc" "vpc-apps" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}.apps"
    Project = var.project_name
    Owner = var.project_owner
  }
}

data "aws_region" "current" {}

