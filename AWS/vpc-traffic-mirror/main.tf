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

data "aws_region" "current" {}

######################################################################
# Create a VPC for application workloads we need to monitor
resource "aws_vpc" "apps" {
  cidr_block = "192.168.128.0/18"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}.apps"
    Project = var.project_name
    Owner = var.project_owner
  }
}

resource "aws_subnet" "apps_public" {
  vpc_id     = aws_vpc.apps.id
  cidr_block = "192.168.128.0/24"

  tags = {
    Name = "${var.project_name}.apps_public"
    Project = var.project_name
    Owner = var.project_owner
  }
}