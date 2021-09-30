# AWS Cloud Traffic Visibility Demo

## Overview
In this demo we are going to use Keysight CloudLens 6.0 to monitor network traffic in AWS cloud.

VPC: cl-demo
"10.10.0.0/16"
Enable DNS hostnames

Subnets:
cl-demo-public-1
10.10.0.0/24

IGW:
cl-demo-igw

aws ec2 attach-internet-gateway --vpc-id "vpc-0bb27588f57dde4f9" --internet-gateway-id "igw-0d6725ceb4e928806" --region us-west-1

Add default route for cl-demo-igw to cl-demo-rt route table, associate with cl-demo-public-1 subnet

Add IAM Role: CloudLens-Collector
Policy:  AmazonEC2ReadOnlyAccess (arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess)
Desc: CloudLens collector EC2 instances need an ability to list EC2 resources monitored via VPC traffic mirroring sessions


EC2:
Ubuntu Server 18.04 LTS (HVM), SSD Volume Type - ami-07b068f843ec78e72
t2.xlarge
100G root volume
cl-demo-public-1 subnet

Security group name
cl-demo-cl-manager
Description
cloudlens manager

SSH TCP 22 70.134.62.214/32
HTTPS TCP 443 0.0.0.0/0

Add name for the instance: cl-demo-cl-manager-1

Allocate a new Elastic Public IP and associate it with `cl-demo-cl-manager-1` instance. In this case the following IP was allocated: `54.219.248.138`

Copy deployment script to the instance:

```
scp -i "aws_cloud_ist_uswest1_alex_bortok.pem" CloudLens-Installer-6.0.2-3.sh ubuntu@54.219.248.138:
```

SSH to the instance and run the script:

ssh -i "aws_cloud_ist_uswest1_alex_bortok.pem" ubuntu@54.219.248.138


Executed steps on the instance or virtual machine

````
bash CloudLens-Installer-6.0.2-3.sh
````

After the installation finishes, wait 10-30 minutes for CloudLens Manager to become available, then use a browser to connect to CloudLens Manager at: https://54.219.248.138.


To support TLS certificate validation, issue a trusted TLS certificate for the instance's DNS name. An example below relies of AWS Route53 DNS service hosting a DNS record `aws-cl-demo.ixlab.org` and uses LetsEncrypt service for signing a certificate. Use fullchain1.pem as a certificate.

````
export AWS_CONFIG_FILE=$HOME/certbot/etc/route53.cfg
certbot --config-dir ~/certbot/etc --work-dir ~/certbot/var --logs-dir ~/certbot/log \
  certonly --dns-route53 -d aws-cl-demo.ixlab.org
````

Update "Remove Access URL" value to reflect the DNS name of the CloudLens Manager: `aws-cl-demo.ixlab.org`


## Deploy Threat Simulator workload


EC2:
Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
t2.micro
8G root volume
cl-demo-public-1 subnet

AMI ID is valid for us-west-1 (California)

```Shell
aws ec2 run-instances \
--image-id ami-0d382e80be7ffdae5 \
  --count 1 \
  --instance-type t3.micro \
  --key-name aws_cloud_ist_uswest1_alex_bortok \
  --security-group-ids sg-068563dac5b64015e \
  --subnet-id subnet-0347c73e09e96498a \
  --associate-public-ip-address
````

aws ec2 create-tags \
  --resources i-0f9445db240d860e4 \
  --tags Key=Name,Value=cl-demo-ts-agent-2

Get public IP address:

aws ec2 describe-instances --instance-ids i-0f9445db240d860e4 --query 'Reservations[*].Instances[*].PublicIpAddress' --output text

SSH into the instance:

ssh -i aws_cloud_ist_uswest1_alex_bortok.pem ubuntu@50.18.138.212

User Data:
```Shell
#!/bin/bash -xe
if [ ! -f /home/threatsim/.tsinstalled ]; then
  sysctl -w net.ipv6.conf.all.disable_ipv6=1
  sysctl -w net.ipv6.conf.default.disable_ipv6=1
  apt update
  apt -y install docker.io
  systemctl restart docker
  systemctl enable docker
  cat >> /etc/sudoers.d/80-threatsim-sudo-users << EOF
threatsim ALL=(ALL) NOPASSWD:ALL
EOF  
  organizationID="1234567890abcdef1234567890abcdef"
  name="AWS-CL-Demo-1"
  APIbaseURL="https://api.threatsimulator.cloud"
  curl $APIbaseURL/agent/download\?OrganizationID\=${organizationID}\&Type\=onpremise-linux >/home/threatsim/agent-init.run
  chown threatsim:threatsim /home/threatsim/agent-init.run
  sudo -u threatsim /bin/bash /home/threatsim/agent-init.run --quiet -- -y -n "${name}"
  if [ `docker ps -qf name=ts-filebeat | wc -l` -ge 1 ]; then touch /home/threatsim/.tsinstalled; fi
fi
````

Security group name
cl-demo-ts-agent
Description
Threat Simulator Agent

SSH TCP 22 70.134.62.214/32
HTTPS TCP 443 0.0.0.0/0

Add name for the instance: cl-demo-ts-agent-1


## Deploy CloudLens Collector


* Configure VPC Traffic Mirroring session in CloudShell

python3 aws_vtap_cli.py --action create --source eni-047e0cbb18b16004b --dest eni-016b706045fd6bd08 --tag cl-demo-mirror --region us-west-1



## Deploy Tool workload

EC2:
Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
t2.micro
8G root volume
cl-demo-public-1 subnet

Security group name
cl-demo-tool
Description
CloudLens Tool

SSH TCP 22 70.134.62.214/32
HTTPS TCP 3000 70.134.62.214/32
ZeroTier UDP 19993 10.0.0.0/8

Add name for the instance: cl-demo-tool-1







user1@acme.com
IDE376hja[()


````
export CLM=aws-cl-demo.ixlab.org

sudo apt-get update -y;
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y;
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - ;
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" ;
sudo apt-get update -y;
sudo apt-get install docker-ce docker-ce-cli containerd.io -y;






sudo docker run -v /lib/modules:/lib/modules -v /var/log:/var/log/cloudlens -v /:/host -v /var/run/docker.sock:/var/run/docker.sock -v /etc/ssl/certs/:/usr/local/share/ca-certificates:ro --privileged --name cloudlens-agent -d --restart=on-failure --net=host --log-opt max-size=50m --log-opt max-file=3 ${CLM}/sensor --accept_eula yes --project_key <key> --server ${CLM}
````

