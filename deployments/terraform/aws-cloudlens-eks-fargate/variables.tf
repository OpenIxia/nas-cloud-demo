terraform {
	required_version = ">= 1.0.1"
}

variable "Profile" {
	type = string
}

variable "Region" {
	type = string
}

variable "Public1AvailabilityZone" {
	type = string
}

variable "Public2AvailabilityZone" {
	type = string
}

variable "Private1AvailabilityZone" {
	type = string
}

variable "Private2AvailabilityZone" {
	type = string
}

variable "ApiMaxRetries" {
	type = number
}

variable "UserEmailTag" {
	type = string
	description = "Email address tag of user creating the stack"
	validation {
		condition = length(var.UserEmailTag) >= 14
		error_message = "UserEmailTag minimum length must be >= 14."
	}
}

variable "UserLoginTag" {
	type = string
	description = "Login ID tag of user creating the stack"
	validation {
		condition = length(var.UserLoginTag) >= 4
		error_message = "UserLoginTag minimum length must be >= 4."
	}
}

variable "ProjectTag" {
	type = string
}

variable "InboundIPv4CidrBlock" {
	type = string
	description = "IP Address /32 or IP CIDR range connecting inbound to CloudPeak App"
	validation {
		condition = length(var.InboundIPv4CidrBlock) >= 9 && length(var.InboundIPv4CidrBlock) <= 18 && can(regex("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})", var.InboundIPv4CidrBlock))
		error_message = "InboundIPv4CidrBlock must be a valid IP CIDR range of the form x.x.x.x/x."
	}
}

variable "CLMInstanceType" {
	type = string
	description = "Instance type of CloudLens Manager VM"
	validation {
		condition = can(regex("t2.xlarge", var.CLMInstanceType))
		error_message = "CLMInstanceType must be one of (t2.xlarge) types."
	}
}

variable "CLMAmiId" {
	type = string
}

