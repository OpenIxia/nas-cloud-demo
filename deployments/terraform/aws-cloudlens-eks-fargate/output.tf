output "aws_eks_cluster-EksCluster" {
	value = {
		"id" : aws_eks_cluster.EksCluster.id,
		"name" : aws_eks_cluster.EksCluster.name,
		"version" : aws_eks_cluster.EksCluster.version
	}
}

output "aws_eks_fargate_profile-aws_eks_fargate_profile1" {
	value = {
		"id" : aws_eks_fargate_profile.aws_eks_fargate_profile1.id,
	}
}

output "aws_subnet-Public1Subnet" {
	value = {
		"availability_zone" : aws_subnet.Public1Subnet.availability_zone
	}
}

output "aws_subnet-Public2Subnet" {
	value = {
		"availability_zone" : aws_subnet.Public2Subnet.availability_zone
	}
}

output "aws_subnet-Private1Subnet" {
	value = {
		"availability_zone" : aws_subnet.Private1Subnet.availability_zone
	}
}

output "aws_subnet-Private2Subnet" {
	value = {
		"availability_zone" : aws_subnet.Private2Subnet.availability_zone
	}
}

output "data-aws_availability_zones" {
	value = {
		"available.names" : data.aws_availability_zones.available.names
	}
}