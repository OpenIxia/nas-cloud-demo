# Traffic Visibility for AWS EKS Fargate Cluster using Keysight CloudLens

## Overview

In this cookbook we are going to monitor network traffic inside AWS EKS Fargate Cluster using Keysight CloudLens. The cookbook is using Terraform.

## Diagram

TBD

## Prerequisites

* [Terraform](https://www.terraform.io/downloads.html)
* [AWS Command line or programmatic access](https://docs.aws.amazon.com/singlesignon/latest/userguide/howtogetcredentials.html?icmpid=docs_sso_user_portal) with rights to create IAM roles, VPCs, EKS Clusters.

## Define your environment

Copy `terraform.tfvars_template` to `terraform.tfvars`.

```Shell
cd deployments/terraform/aws-cloudlens-eks-fargate
cp terraform.tfvars_template terraform.tfvars
````

Edit `terraform.tfvars` to specify an AWS Region and other parameters for your environment. Please keep `ProjectTag` and `UserLoginTag` around 8 symbols to avoid running into AWS limitations for length on object names. The playbook would create objects with names derived from these parameters as follows:

* VPC: `<UserLoginTag>_<ProjectTag>_VPC_<RegionTag>`,
* EKS Fargate Cluster: `<UserLoginTag>_<ProjectTag>_K8S_EKS_CLUSTER_<RegionTag>`,
* and so on.

Make sure to replace `1.1.1.1/32` with an IP address block you'll be accessing your deployment from in `InboundIPv4CidrBlock = "1.1.1.1/32"`. For CloudLens Manager instance, please search AWS Community AMIs in the region of your choice for "CloudLens-6" and use an AMI ID with the latest version. Replace `CLMAmiId` with that ID.

## Deploy EKS Fargate cluster and CloudLens Manager EC2 instance

1. Initialize Terraform for your deployment

```Shell
terraform init
````

2. Validate access and changes to be applied by Terraform

```Shell
terraform plan
````

3. Create EKS Cluster

```Shell
terraform apply
````



