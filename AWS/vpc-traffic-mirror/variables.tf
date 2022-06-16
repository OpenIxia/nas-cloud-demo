variable "project_name" {
  description = "Name of AWS environment"
  type        = string
  default     = ""
  validation {
    condition     = length(var.project_name) > 1
    error_message = "Please provide Name of AWS environment to use via: terraform apply -var=\"project_name=<project_name>\"."
  }
}

variable "project_owner" {
  description = "Owner of AWS environment"
  type        = string
  default     = ""
  validation {
    condition     = length(var.project_owner) > 1
    error_message = "Please provide name of AWS environment owner to use via: terraform apply -var=\"project_owner=<owner_email>\"."
  }
}

variable "aws_region" {
  type    = string
  default = ""
  validation {
    condition     = length(var.aws_region) > 1
    error_message = "Please provide AWS region to use via: terraform apply -var=\"aws_region=<region_name>\"."
  }
}

variable "aws_profile" {
  type    = string
  default = "default"
}

variable "mgmt_cidr" {
  type    = string
  default = ""
  validation {
    condition     = length(var.mgmt_cidr) > 1
    error_message = "Please provide source IP block for management access to use via: terraform apply -var=\"mgmt_cidr=<cidr>\"."
  }
}
