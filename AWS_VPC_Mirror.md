# Keysight NAS Use Cases for AWS VPC Traffic Mirror

## Initialization

1. Initialize base directory and clone this repository

```Shell
BASEDIR=<empty folder of your choice>
mkdir -p $BASEDIR
cd $BASEDIR
git clone https://github.com/OpenIxia/nas-cloud-demo.git
```

2. Project name (Environment), AWS region

```Shell
export PROJECT="nas-demo-mirror"
export OWNER="your_email"
export CIDR="192.168.128.0/18"
export AWS_DEFAULT_REGION="us-west-1"
```

3. Initialize AWS authentication. Either use env variables below, or store credentials in `$HOME/.aws/credentials` under profile name `profile_name` and use `export AWS_PROFILE=profile_name`

```Shell
export AWS_ACCESS_KEY_ID="<YOUR_AWS_ACCESS_KEY_ID>"
export AWS_SECRET_ACCESS_KEY="<YOUR_AWS_SECRET_ACCESS_KEY>"
```

## Base Infrastructure Setup

1. Initialize terraform directory

```Shell
cd $BASEDIR/nas-cloud-demo/AWS/vpc-traffic-mirror
terraform init
```

2. Review the changes to be deployed. You might want to remove `-var="aws_profile=${AWS_PROFILE}"` if you are using a default profile and/or env variables for AWS authentication

```Shell
terraform workspace new ${PROJECT}
terraform plan -var="project_name=${PROJECT}" -var="project_owner=${OWNER}" -var="aws_region=${AWS_DEFAULT_REGION}" -var="vpc_cidr=${CIDR}" -var="aws_profile=${AWS_PROFILE}"
```

3. Apply the changes

```Shell
terraform apply -var="project_name=${PROJECT}" -var="project_owner=${OWNER}" -var="aws_region=${AWS_DEFAULT_REGION}" -var="vpc_cidr=${CIDR}" -var="aws_profile=${AWS_PROFILE}"
```
