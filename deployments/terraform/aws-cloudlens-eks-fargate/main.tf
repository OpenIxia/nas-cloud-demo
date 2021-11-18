provider "aws" {
	profile = var.Profile
	region = var.Region
	max_retries = var.ApiMaxRetries
}

locals {
	uuid = substr(uuid(), 1, 6)
	Region = var.Region
	Public1AvailabilityZone = var.Public1AvailabilityZone
	Public2AvailabilityZone = var.Public2AvailabilityZone
	Private1AvailabilityZone = var.Private1AvailabilityZone
	Private2AvailabilityZone = var.Public2AvailabilityZone
	UserEmailTag = var.UserEmailTag
	UserLoginTag = var.UserLoginTag
	ProjectTag = var.ProjectTag
	RegionTag = upper(replace(local.Region, "-", "_"))
	CLMInstanceType = var.CLMInstanceType
	InboundIPv4CidrBlock = var.InboundIPv4CidrBlock
	VPC_CIDR_BLOCK = "10.0.0.0/16"
	VPC_INSTANCE_TENANCY = "default"
	VPC_ENABLE_DNS_SUPPORT = true
	VPC_ENABLE_DNS_HOSTNAMES = true
	PLACEMENT_GROUP_STRATEGY = "spread"
	FLOW_LOG_TRAFFIC_TYPE = "REJECT"
	PUBLIC1_SUBNET_CIDR_BLOCK = "10.0.10.0/24"
	PUBLIC2_SUBNET_CIDR_BLOCK = "10.0.11.0/24"
	PRIVATE1_SUBNET_CIDR_BLOCK = "10.0.2.0/24"
	PRIVATE2_SUBNET_CIDR_BLOCK = "10.0.3.0/24"
	EKS_CLUSTER_VERSION = "1.18"
	INTERFACE_SOURCE_DEST_CHECK = false
	INSTANCE_DISABLE_API_TERMINATION = false
	INSTANCE_MONITORING = false
	INSTANCE_INSTANCE_INITIATED_SHUTDOWN_BEHAVIOR = "stop"
	INSTANCE_EBS_DELETE_ON_TERMINATION = true
	INSTANCE_EBS_VOLUME_TYPE = "gp2"
	APP_TAG = "K8S"
}

data "aws_availability_zones" "available" {
	state = "available"
}

resource "aws_vpc" "Vpc" {
	cidr_block = local.VPC_CIDR_BLOCK
	instance_tenancy = local.VPC_INSTANCE_TENANCY
	enable_dns_support = local.VPC_ENABLE_DNS_SUPPORT
	enable_dns_hostnames = local.VPC_ENABLE_DNS_HOSTNAMES
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_VPC_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
}

resource "aws_flow_log" "VpcFlowLog" {
	log_destination =  aws_cloudwatch_log_group.VpcFlowLogGroup.arn
	iam_role_arn = aws_iam_role.VPCFlowLogAccessRole.arn
	vpc_id = aws_vpc.Vpc.id
	traffic_type = local.FLOW_LOG_TRAFFIC_TYPE
}

resource "aws_iam_role" "VPCFlowLogAccessRole" {
	name = "${local.UserLoginTag}_${local.ProjectTag}_VPC_FLOW_LOG_ACCESS_ROLE_${local.uuid}_${local.RegionTag}"
	assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Action": "sts:AssumeRole",
			"Principal": {
				"Service": "vpc-flow-logs.amazonaws.com"
			},
			"Effect": "Allow"
		}
	]
}
EOF
	permissions_boundary = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
	path = "/"
}

resource "aws_cloudwatch_log_group" "VpcFlowLogGroup" {
	name = "${local.UserLoginTag}_${local.ProjectTag}_VPC_FLOW_LOG_GROUP_${local.uuid}_${local.RegionTag}"
}

resource "aws_subnet" "Public1Subnet" {
	availability_zone = local.Public1AvailabilityZone
	cidr_block = local.PUBLIC1_SUBNET_CIDR_BLOCK
	vpc_id = aws_vpc.Vpc.id
	map_public_ip_on_launch = true
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_INPOST_PUBLIC1_SUBNET_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
}

resource "aws_subnet" "Public2Subnet" {
	availability_zone = local.Public2AvailabilityZone
	cidr_block = local.PUBLIC2_SUBNET_CIDR_BLOCK
	vpc_id = aws_vpc.Vpc.id
	map_public_ip_on_launch = true
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_PUBLIC2_SUBNET_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
}

resource "aws_subnet" "Private1Subnet" {
	availability_zone = local.Private1AvailabilityZone
	cidr_block = local.PRIVATE1_SUBNET_CIDR_BLOCK
	vpc_id = aws_vpc.Vpc.id
	map_public_ip_on_launch = false
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_PRIVATE1_SUBNET_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
}

resource "aws_subnet" "Private2Subnet" {
	availability_zone = local.Private2AvailabilityZone
	cidr_block = local.PRIVATE2_SUBNET_CIDR_BLOCK
	vpc_id = aws_vpc.Vpc.id
	map_public_ip_on_launch = false
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_PRIVATE2_SUBNET_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
}

resource "aws_security_group" "Public1SecurityGroup" {
	name = "${local.UserLoginTag}_${local.ProjectTag}_PUBLIC1_SECURITY_GROUP_${local.RegionTag}"
	description = "${local.UserLoginTag}_${local.ProjectTag}_PUBLIC1_SECURITY_GROUP_${local.RegionTag}"
	vpc_id = aws_vpc.Vpc.id
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_PUBLIC1_SECURITY_GROUP_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
}

resource "aws_security_group_rule" "Public1Ingress1" {
	type = "ingress"
	security_group_id = aws_security_group.Public1SecurityGroup.id
	protocol = "-1"
	from_port = 0
	to_port = 0
	source_security_group_id = aws_security_group.Public1SecurityGroup.id
}

resource "aws_security_group_rule" "Public1Ingress22" {
	type = "ingress"
	security_group_id = aws_security_group.Public1SecurityGroup.id
	protocol = "tcp"
	from_port = 22
	to_port = 22
	cidr_blocks = [ local.InboundIPv4CidrBlock ]
}

resource "aws_security_group_rule" "Public1Ingress80" {
	type = "ingress"
	security_group_id = aws_security_group.Public1SecurityGroup.id
	protocol = "tcp"
	from_port = 80
	to_port = 80
	cidr_blocks = [ local.InboundIPv4CidrBlock ]
}

resource "aws_security_group_rule" "Public1Ingress443" {
	type = "ingress"
	security_group_id = aws_security_group.Public1SecurityGroup.id
	protocol = "tcp"
	from_port = 443
	to_port = 443
	cidr_blocks = [ local.InboundIPv4CidrBlock ]
}

resource "aws_security_group_rule" "Public1Ingress3000" {
	type = "ingress"
	security_group_id = aws_security_group.Public1SecurityGroup.id
	protocol = "tcp"
	from_port = 3000
	to_port = 3000
	cidr_blocks = [ local.InboundIPv4CidrBlock ]
}

resource "aws_security_group_rule" "Public1Egress1" {
	type = "egress"
	security_group_id = aws_security_group.Public1SecurityGroup.id
	protocol = "-1"
	to_port = 0
	from_port = 0
	cidr_blocks = [ "0.0.0.0/0" ]
}

resource "aws_security_group" "Public2SecurityGroup" {
	name = "${local.UserLoginTag}_${local.ProjectTag}_PUBLIC2_SECURITY_GROUP_${local.RegionTag}"
	description = "${local.UserLoginTag}_${local.ProjectTag}_PUBLIC2_SECURITY_GROUP_${local.RegionTag}"
	vpc_id = aws_vpc.Vpc.id
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_PUBLIC2_SECURITY_GROUP_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
}

resource "aws_security_group_rule" "Public2Ingress1" {
	type = "ingress"
	security_group_id = aws_security_group.Public2SecurityGroup.id
	protocol = "-1"
	from_port = 0
	to_port = 0
	source_security_group_id = aws_security_group.Public2SecurityGroup.id
}

resource "aws_security_group_rule" "Public2Ingress22" {
	type = "ingress"
	security_group_id = aws_security_group.Public2SecurityGroup.id
	protocol = "tcp"
	from_port = 22
	to_port = 22
	cidr_blocks = [ local.InboundIPv4CidrBlock ]
}

resource "aws_security_group_rule" "Public2Ingress80" {
	type = "ingress"
	security_group_id = aws_security_group.Public2SecurityGroup.id
	protocol = "tcp"
	from_port = 80
	to_port = 80
	cidr_blocks = [ local.InboundIPv4CidrBlock ]
}

resource "aws_security_group_rule" "Public2Ingress443" {
	type = "ingress"
	security_group_id = aws_security_group.Public2SecurityGroup.id
	protocol = "tcp"
	from_port = 443
	to_port = 443
	cidr_blocks = [ local.InboundIPv4CidrBlock ]
}

resource "aws_security_group_rule" "Public2Ingress3000" {
	type = "ingress"
	security_group_id = aws_security_group.Public2SecurityGroup.id
	protocol = "tcp"
	from_port = 3000
	to_port = 3000
	cidr_blocks = [ local.InboundIPv4CidrBlock ]
}

resource "aws_security_group_rule" "Public2Egress1" {
	type = "egress"
	security_group_id = aws_security_group.Public2SecurityGroup.id
	protocol = "-1"
	to_port = 0
	from_port = 0
	cidr_blocks = [ "0.0.0.0/0" ]
}

resource "aws_security_group" "Private1SecurityGroup" {
	name = "${local.UserLoginTag}_${local.ProjectTag}_PRIVATE1_SECURITY_GROUP_${local.RegionTag}"
	description = "${local.UserLoginTag}_${local.ProjectTag}_PRIVATE1_SECURITY_GROUP_${local.RegionTag}"
	vpc_id = aws_vpc.Vpc.id
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_PRIVATE1_SECURITY_GROUP_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
}

resource "aws_security_group_rule" "Private1Ingress1" {
	type = "ingress"
	security_group_id = aws_security_group.Private1SecurityGroup.id
	protocol = "-1"
	from_port = 0
	to_port = 0
	source_security_group_id = aws_security_group.Private1SecurityGroup.id
}

resource "aws_security_group_rule" "Private1Egress1" {
	type = "egress"
	security_group_id = aws_security_group.Private1SecurityGroup.id
	protocol = "-1"
	to_port = 0
	from_port = 0
	cidr_blocks = [ "0.0.0.0/0" ]
}

resource "aws_security_group" "Private2SecurityGroup" {
	name = "${local.UserLoginTag}_${local.ProjectTag}_PRIVATE2_SECURITY_GROUP_${local.RegionTag}"
	description = "${local.UserLoginTag}_${local.ProjectTag}_PRIVATE2_SECURITY_GROUP_${local.RegionTag}"
	vpc_id = aws_vpc.Vpc.id
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_PRIVATE2_SECURITY_GROUP_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
}

resource "aws_security_group_rule" "Private2Ingress1" {
	type = "ingress"
	security_group_id = aws_security_group.Private2SecurityGroup.id
	protocol = "-1"
	from_port = 0
	to_port = 0
	source_security_group_id = aws_security_group.Private2SecurityGroup.id
}

resource "aws_security_group_rule" "Private2Egress1" {
	type = "egress"
	security_group_id = aws_security_group.Private2SecurityGroup.id
	protocol = "-1"
	to_port = 0
	from_port = 0
	cidr_blocks = [ "0.0.0.0/0" ]
}

resource "aws_default_security_group" "DefaultEgress1" {
	vpc_id = aws_vpc.Vpc.id

	egress {
		protocol = -1
		self = true
		from_port = 0
		to_port = 0
	}
}

resource "aws_internet_gateway" "InternetGw" {
	vpc_id = aws_vpc.Vpc.id
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_INTERNET_GW_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
}

resource "aws_route" "Public1Route" {
	destination_cidr_block = "0.0.0.0/0"
	route_table_id = aws_route_table.Public1RouteTable.id
	gateway_id = aws_internet_gateway.InternetGw.id
	depends_on = [
		aws_internet_gateway.InternetGw
	]
}

resource "aws_route_table" "Public1RouteTable" {
	vpc_id = aws_vpc.Vpc.id
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_PUBLIC1_ROUTE_TABLE_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
}

resource "aws_route_table_association" "Public1SubnetRouteTableAssociation" {
	route_table_id = aws_route_table.Public1RouteTable.id
	subnet_id = aws_subnet.Public1Subnet.id
}

resource "aws_nat_gateway" "Public1NatGateway" {
	allocation_id = aws_eip.Public1NatGwElasticIp.id
	subnet_id     = aws_subnet.Public1Subnet.id
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_PUBLIC1_NAT_GW_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
	depends_on = [
		aws_internet_gateway.InternetGw,
		aws_eip.Public1NatGwElasticIp,
		aws_subnet.Public1Subnet
	]
}

resource "aws_eip" "Public1NatGwElasticIp" {
	vpc = true
	depends_on = [
		aws_internet_gateway.InternetGw
	]
}

resource "aws_route" "Public2Route" {
	destination_cidr_block = "0.0.0.0/0"
	route_table_id = aws_route_table.Public2RouteTable.id
	gateway_id = aws_internet_gateway.InternetGw.id
	depends_on = [
		aws_internet_gateway.InternetGw
	]
}

resource "aws_route_table" "Public2RouteTable" {
	vpc_id = aws_vpc.Vpc.id
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_PUBLIC2_ROUTE_TABLE_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
}

resource "aws_route_table_association" "Public2SubnetRouteTableAssociation" {
	route_table_id = aws_route_table.Public2RouteTable.id
	subnet_id = aws_subnet.Public2Subnet.id
}

resource "aws_nat_gateway" "Public2NatGateway" {
	allocation_id = aws_eip.Public2NatGwElasticIp.id
	subnet_id     = aws_subnet.Public2Subnet.id
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_PUBLIC2_NAT_GW_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
	depends_on = [
		aws_internet_gateway.InternetGw,
		aws_eip.Public2NatGwElasticIp,
		aws_subnet.Public2Subnet
	]
}

resource "aws_eip" "Public2NatGwElasticIp" {
	vpc = true
	depends_on = [
		aws_internet_gateway.InternetGw
	]
}

resource "aws_route" "Private1Route" {
	destination_cidr_block = "0.0.0.0/0"
	route_table_id = aws_route_table.Private1RouteTable.id
	nat_gateway_id = aws_nat_gateway.Public1NatGateway.id
	depends_on = [
		aws_internet_gateway.InternetGw,
		aws_nat_gateway.Public1NatGateway
	]
}

resource "aws_route_table" "Private1RouteTable" {
	vpc_id = aws_vpc.Vpc.id
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_PRIVATE1_ROUTE_TABLE_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
}

resource "aws_route_table_association" "Private1SubnetRouteTableAssociation" {
	route_table_id = aws_route_table.Private1RouteTable.id
	subnet_id = aws_subnet.Private1Subnet.id
}

resource "aws_route" "Private2Route" {
	destination_cidr_block = "0.0.0.0/0"
	route_table_id = aws_route_table.Private2RouteTable.id
	nat_gateway_id = aws_nat_gateway.Public2NatGateway.id
	depends_on = [
		aws_internet_gateway.InternetGw,
		aws_nat_gateway.Public2NatGateway
	]
}

resource "aws_route_table" "Private2RouteTable" {
	vpc_id = aws_vpc.Vpc.id
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_PRIVATE2_ROUTE_TABLE_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
}

resource "aws_route_table_association" "Private2SubnetRouteTableAssociation" {
	route_table_id = aws_route_table.Private2RouteTable.id
	subnet_id = aws_subnet.Private2Subnet.id
}

resource "aws_iam_role" "eks_cluster" {
	name = "eks-cluster-${local.uuid}"
	assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
	policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
	role = aws_iam_role.eks_cluster.name
}

resource "aws_eks_cluster" "EksCluster" {
	name = "${local.UserLoginTag}_${local.ProjectTag}_${local.APP_TAG}_EKS_CLUSTER_${local.RegionTag}"
	role_arn = aws_iam_role.eks_cluster.arn
	version = local.EKS_CLUSTER_VERSION
	vpc_config {
		endpoint_private_access = false
		endpoint_public_access = true
		subnet_ids = [
			aws_subnet.Public1Subnet.id,
			aws_subnet.Public2Subnet.id,
			aws_subnet.Private1Subnet.id,
			aws_subnet.Private2Subnet.id
		]
		security_group_ids = [
			aws_security_group.Public1SecurityGroup.id
		]
	}
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_${local.APP_TAG}_EKS_CLUSTER_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
	depends_on = [
		aws_iam_role_policy_attachment.amazon_eks_cluster_policy
	]
	timeouts {
		create = "15m"
		delete = "5m"
	}
}

resource "aws_iam_role" "EksNodeRole" {
	name = "eks-node-group-general-${local.uuid}"
	assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }, 
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy_general" {
	policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
	role = aws_iam_role.EksNodeRole.name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy_general" {
	policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
	role = aws_iam_role.EksNodeRole.name
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
	policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
	role = aws_iam_role.EksNodeRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_execution_role.name
}

resource "aws_iam_role" "fargate_pod_execution_role" {
  name = "eks-fargate-pod-execution-role-${local.uuid}"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "eks.amazonaws.com",
          "eks-fargate-pods.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_eks_fargate_profile" "aws_eks_fargate_profile1" {
	cluster_name           = aws_eks_cluster.EksCluster.name
	fargate_profile_name   = "fg_profile_default_namespace"
	pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
	subnet_ids = [
		aws_subnet.Private1Subnet.id,
		aws_subnet.Private2Subnet.id
	]
	selector {
		namespace = "default"
	}
	depends_on = [
		aws_eks_cluster.EksCluster
	]
}

resource "aws_placement_group" "PlacementGroup" {
	name = "${local.UserLoginTag}_${local.ProjectTag}_PLACEMENT_GROUP_${local.uuid}_${local.RegionTag}"
	strategy = local.PLACEMENT_GROUP_STRATEGY
}

resource "aws_network_interface" "CLMEth0" {
	description = "${local.UserLoginTag}_${local.ProjectTag}_CLM_ETH0_${local.RegionTag}"
	source_dest_check = local.INTERFACE_SOURCE_DEST_CHECK
	subnet_id = aws_subnet.Public1Subnet.id
	security_groups = [
		aws_security_group.Public1SecurityGroup.id
	]
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_CLM_ETH0_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
}

resource "aws_instance" "CloudLensManager" {
	disable_api_termination = local.INSTANCE_DISABLE_API_TERMINATION
	instance_initiated_shutdown_behavior = local.INSTANCE_INSTANCE_INITIATED_SHUTDOWN_BEHAVIOR
	ami = local.CLMAmiId
	instance_type = local.CLMInstanceType
	monitoring = local.INSTANCE_MONITORING
	tags = {
		Name = "${local.UserLoginTag}_${local.ProjectTag}_CLM_${local.RegionTag}"
		Owner = local.UserEmailTag
		Project = local.ProjectTag
	}
	network_interface {
		network_interface_id = aws_network_interface.CLMEth0.id
		device_index = "0"
	}
	root_block_device {
		delete_on_termination = local.INSTANCE_EBS_DELETE_ON_TERMINATION
		volume_type = local.INSTANCE_EBS_VOLUME_TYPE
	}
	timeouts {
		create = "9m"
		delete = "5m"
	}
}


