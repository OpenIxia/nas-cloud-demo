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



Copy deployment script to the instance:

```
scp -i "bortok_us-west-1.pem" CloudLens-Installer-6.0.1-16.sh ubuntu@ec2-54-177-68-226.us-west-1.compute.amazonaws.com:
```

SSH to the instance and run the script:

ssh -i "bortok_us-west-1.pem" ubuntu@ec2-54-177-68-226.us-west-1.compute.amazonaws.com
ssh -i "bortok_us-west-1.pem" ubuntu@ec2-54-219-191-153.us-west-1.compute.amazonaws.com

Executed steps on the instance or virtual machine

````
bash CloudLens-Installer-6.0.1-16.sh
````

After the installation finishes, wait 10-30 minutes for CloudLens Manager to become available, then use a browser to connect to CloudLens Manager at: https://<cl_manager_vm_ ip>.

To support TLS certificate validation, issue a trusted TLS certificate for the instance's DNS name. An example below relies of AWS Route53 DNS service hosting a DNS record `aws-cl-demo.ixlab.org` and uses LetsEncrypt service for signing a certificate. Use fullchain1.pem as a certificate.

````
export AWS_CONFIG_FILE=$HOME/certbot/etc/route53.cfg
certbot --config-dir ~/certbot/etc --work-dir ~/certbot/var --logs-dir ~/certbot/log \
  certonly --dns-route53 -d aws-cl-demo.ixlab.org
````

Update "Remove Access URL" value to reflect the DNS name of the CloudLens Manager: `aws-cl-demo.ixlab.org`



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

