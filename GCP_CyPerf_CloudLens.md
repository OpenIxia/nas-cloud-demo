# CloudLens Demo on Google Cloud with Keysight CyPerf

## Prerequisites

1. CyPerf activation code (license)

2. A Google account with Google Cloud access

3. Install [Google Cloud SDK](https://cloud.google.com/sdk/docs) and authenticate via

```Shell
gcloud init
````

## Setup

1. Initialize base directory and clone this repository as well as CyPerf Deployment Templates Repo

```Shell
BASEDIR=<an empty folder of your choice>
mkdir -p $BASEDIR
cd $BASEDIR
git clone https://github.com/OpenIxia/nas-cloud-demo.git
git clone --depth 1 --branch CyPerf-1.1-Update1 https://github.com/Keysight/cyperf.git
````

2. Create a [GCP Service Account](https://console.cloud.google.com/iam-admin/serviceaccounts) to execute this deployment with. In this setup I'm using `nascloud@kt-nas-demo.iam.gserviceaccount.com` Sevice Account

```Shell
gcloud iam service-accounts create nascloud
gcloud projects add-iam-policy-binding kt-nas-demo --member="serviceAccount:nascloud@kt-nas-demo.iam.gserviceaccount.com" --role="roles/owner"
gcloud iam service-accounts keys create nascloud.json --iam-account=nascloud@kt-nas-demo.iam.gserviceaccount.com
````

3. Initialize Google Cloud environment for Terraform

```Shell

gcp_project_name=<project_name>
gcp_owner_tag=<owner_tag>
gcp_ssh_key=<ssh_key>
gcp_credential_file="${BASEDIR}/nascloud.json"
````

4. Install CyPerf with Terraform

```Shell
cd $BASEDIR/cyperf/deployment/gcp/terraform/controller_and_agent_pair
terraform workspace new gcp-cyperf-cloudlens
terraform init
terraform apply \
-var gcp_project_name="${gcp_project_name}" \
-var gcp_owner_tag="${gcp_owner_tag}" \
-var gcp_ssh_key="${gcp_ssh_key}" \
-var gcp_credential_file="${gcp_credential_file}"
````

5. Connect to a `public_ip` IP address of `mdw_detail` output and accept CyPerf EULA. Login with

  * Username: admin
  * Password: CyPerf&Keysight#1

6. Activate CyPerf license "Gear button" > Administration > License Manager

## Install CloudLens

1. Download CloudLens Manager VMDK image from [Ixia Keysight Support website](https://support.ixiacom.com/support-overview/product-support/downloads-updates/versions/228985)

2. Follow steps from [CloudLens Manager deployment section](https://github.com/OpenIxia/gcp-cloudlens/blob/main/DEPLOY.md#deploying-cloudlens-manager) applicable to Google Cloud.) to create a Compute Engine Image for CloudLens Manager. In this guide, we created an image `cloudlens-manager-612-3`. Use the next step to create an actual instance

3. Deploy an instance with CloudLens Manager in a default VPC using `cloudlens-manager-612-3` image

[//]: # (TODO static public IP address)

```Shell
gcloud compute instances create cl-manager-use1-vmdk \
--zone=us-east1-b \
--machine-type=e2-standard-4 \
--subnet=default \
--create-disk=auto-delete=yes,boot=yes,device-name=cl-manager-use1-vmdk,image=projects/kt-nas-demo/global/images/cloudlens-manager-612-3,mode=rw,size=196 \
--tags=cl-manager,https-server
````

4. Record a public IP of the CloudLens Manager instance, which would be refered as `clm_public_ip` further in this document

```Shell
export clm_public_ip=`gcloud compute instances describe cl-manager-use1-vmdk --zone=us-east1-b --format='get(networkInterfaces[0].accessConfigs[0].natIP)'`; echo $clm_public_ip
````

5. To access CloudLens Manager, open a web browser and enter `https://clm_public_ip` in the URL field. It may take up some time for CloudLens Manager Web UI to initialize

  The default credentials for the CloudLens admin account are as follows. After first login you will be asked to change the password.

    * Username admin
    * Password Cl0udLens@dm!n

6. In CloudLens Manager admin UI, section "Remote Access URL", change private IP address to `clm_public_ip` or corresponding DNS entry.

7. In "License Management" use an activation code to add a license.

8. In "User Management" create a user with parameters of your liking. Assign nessecary quantity of licenses to the user.

9. Logout and login as a user created in the previous step.

10. Choose "I already have a project", and then create a project by clicking ‘+’. Use any project name you see fit. Open the project. Click "SHOW PROJECT KEY" and copy the key. Copy and paste the project key below to replace `PROJECT_KEY`

```Shell
cloudlens_project_key=PROJECT_KEY
````

## CloudLens Collector Deployment

1. Create a subnet for CloudLens Collector deployment

```Shell
gcloud compute networks subnets create "${gcp_owner_tag}-collector-use1-subnet" --project="${gcp_project_name}" --range=192.168.222.0/24 --network="${gcp_owner_tag}-test-vpc-network" --region=us-east1
````

2. Deploy a pair of Ubuntu instance as CloudLens Collectors. We are going to use these instances to collect network traffic using Packet Mirroring service from a CyPerf instance.

```Shell
set +H
gcloud compute instances create cl-collector-use1-1 \
--zone=us-east1-b \
--machine-type="c2-standard-4" \
--subnet="${gcp_owner_tag}-collector-use1-subnet" \
--image-family=ubuntu-2004-lts \
--image-project=ubuntu-os-cloud \
--boot-disk-size=10GB \
--boot-disk-device-name=cl-collector-use1-1 \
--tags=cl-collector \
--scopes=https://www.googleapis.com/auth/compute.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.read_only \
--metadata=startup-script="#!/bin/bash -xe
if [ ! -f /root/.cl-collector-installed ]; then
  mkdir /etc/docker
  cat >> /etc/docker/daemon.json << EOF
{\"insecure-registries\":[\"$clm_public_ip\"]}
EOF
  apt-get update -y
  apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - 
  add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\"
  apt-get update -y
  apt-get install docker-ce docker-ce-cli containerd.io -y
  docker run -v /var/log:/var/log/cloudlens -v /:/host -v /var/run/docker.sock:/var/run/docker.sock -v /lib/modules:/lib/modules --privileged --name cloudlens-agent -d --restart=on-failure --net=host --log-opt max-size=50m --log-opt max-file=3 $clm_public_ip/sensor --accept_eula yes --runmode collector --ssl_verify no --project_key $cloudlens_project_key --server $clm_public_ip
  if [ \`docker ps -qf name=cloudlens-agent | wc -l\` -ge 1 ]; then touch /root/.cl-collector-installed; fi
fi"
```


```Shell
set +H
gcloud compute instances create cl-collector-use1-2 \
--zone=us-east1-b \
--machine-type="c2-standard-4" \
--subnet="${gcp_owner_tag}-collector-use1-subnet" \
--image-family=ubuntu-2004-lts \
--image-project=ubuntu-os-cloud \
--boot-disk-size=10GB \
--boot-disk-device-name=cl-collector-use1-2 \
--tags=cl-collector \
--scopes=https://www.googleapis.com/auth/compute.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.read_only \
--metadata=startup-script="#!/bin/bash -xe
if [ ! -f /root/.cl-collector-installed ]; then
  mkdir /etc/docker
  cat >> /etc/docker/daemon.json << EOF
{\"insecure-registries\":[\"$clm_public_ip\"]}
EOF
  apt-get update -y
  apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - 
  add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\"
  apt-get update -y
  apt-get install docker-ce docker-ce-cli containerd.io -y
  docker run -v /var/log:/var/log/cloudlens -v /:/host -v /var/run/docker.sock:/var/run/docker.sock -v /lib/modules:/lib/modules --privileged --name cloudlens-agent -d --restart=on-failure --net=host --log-opt max-size=50m --log-opt max-file=3 $clm_public_ip/sensor --accept_eula yes --runmode collector --ssl_verify no --project_key $cloudlens_project_key --server $clm_public_ip
  if [ \`docker ps -qf name=cloudlens-agent | wc -l\` -ge 1 ]; then touch /root/.cl-collector-installed; fi
fi"
```

3. Open Google Cloud Console in the browser and select Activate Cloud Shell icon in the top right menu bar. Create a Packet Mirroring session by running the script below. You'll need to replace `${gcp_owner_tag}` with value you used in Setup section.

[//]: # (TODO there is a bug with collector that doesn't work if the mirror is created with `--mirrored-tags ts-agent`)

```Shell
clm_public_ip=`gcloud compute instances describe cl-manager-use1-vmdk --zone=us-east1-b --format='get(networkInterfaces[0].accessConfigs[0].natIP)'`; echo $clm_public_ip
wget --no-check-certificate https://${clm_public_ip}/cloudlens/static/scripts/google/gcp_packetmirroring_cli.py
python3 gcp_packetmirroring_cli.py --action create --region us-east1 --project kt-nas-demo --mirrored-network "${gcp_owner_tag}-test-vpc-network" --mirrored-tags gcp-server --collector cl-collector-use1-1 
````

If any failures are encountered during Packet Mirroring setup, to cleanup configuration, please use

```Shell
python3 gcp_packetmirroring_cli.py --action delete --region us-east1 --project kt-nas-demo --collector cl-collector-use1-1 --mirrored-network "${gcp_owner_tag}-test-vpc-network"
````

4. In Google Cloud Console add `cl-collector-use1-2` instance to `cls-ig-*` instance group that `cl-collector-use1-1` is a member of.

5. Create firewall rules to permit mirrored traffic from monitored instances to CloudLens Collectors

[//]: # (TODO replace FR IP - Use an IP address assiged as a Frontend Internal IP in the previous step as `--destination-ranges`)
Egress from source instances:

```Shell
gcloud compute --project=kt-nas-demo firewall-rules create "${gcp_owner_tag}-test-vpc-network-packet-mirror-egress-cl" --description="Packet mirroring egress from sources to CL Collectors" --direction=EGRESS --priority=1000 --network="${gcp_owner_tag}-test-vpc-network" --action=ALLOW --rules=all --destination-ranges=192.168.222.0/24
```

Ingress to CloudLens Collectors:

```Shell
gcloud compute --project=kt-nas-demo firewall-rules create "${gcp_owner_tag}-test-vpc-network-packet-mirror-ingress-cl" --description="Packet mirrirong ingress traffic to CL Collectors" --direction=INGRESS --priority=1000 --network=${gcp_owner_tag}-test-vpc-network --action=ALLOW --rules=all --source-ranges=0.0.0.0/0 --target-tags=cl-collector
```

## Network Traffic Sensor Deployment with VxLAN termination

1. Deploy two Ubuntu instances to work as a network traffic sensors.

```Shell
set +H
gcloud compute instances create cl-tool-1 \
--zone=us-east1-b \
--machine-type="c2-standard-4" \
--subnet="${gcp_owner_tag}-collector-use1-subnet" \
--image-family=ubuntu-2004-lts \
--image-project=ubuntu-os-cloud \
--boot-disk-size=10GB \
--boot-disk-device-name=cl-tool-1 \
--tags=cl-tool \
--metadata=startup-script="#!/bin/bash -xe
if [ ! -f /root/.cl-tool-installed ]; then
  apt-get update -y
  apt-get install software-properties-common wget -y
  add-apt-repository universe
  wget https://packages.ntop.org/apt-stable/20.04/all/apt-ntop-stable.deb
  apt install ./apt-ntop-stable.deb
  apt-get clean all
  apt-get update
  apt-get install ntopng -y
  mkdir -p /etc/ntopng
  cat > /etc/ntopng/ntopng.conf << EOF
-e=
-w=3000
--local-networks=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
EOF
  systemctl restart ntopng
  touch /root/.cl-tool-installed
fi"

gcloud compute instances create cl-tool-2 \
--zone=us-east1-b \
--machine-type="c2-standard-4" \
--subnet="${gcp_owner_tag}-collector-use1-subnet" \
--image-family=ubuntu-2004-lts \
--image-project=ubuntu-os-cloud \
--boot-disk-size=10GB \
--boot-disk-device-name=cl-tool-2 \
--tags=cl-tool \
--metadata=startup-script="#!/bin/bash -xe
if [ ! -f /root/.cl-tool-installed ]; then
  apt-get update -y
  apt-get install software-properties-common wget -y
  add-apt-repository universe
  wget https://packages.ntop.org/apt-stable/20.04/all/apt-ntop-stable.deb
  apt install ./apt-ntop-stable.deb
  apt-get clean all
  apt-get update
  apt-get install ntopng -y
  mkdir -p /etc/ntopng
  cat > /etc/ntopng/ntopng.conf << EOF
-e=
-w=3000
--local-networks=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
EOF
  systemctl restart ntopng
  touch /root/.cl-tool-installed
fi"
````

2. Copy INTERNAL_IP values from the output of the commands above, one-by-one, and create DESTINATIONS > NEW STATIC DESTINATION for each of them in CloudLens Manager UI. Use "tool:cl-tool-1" and "tool:cl-tool-2" tags respectively.

3. Create VPC Firewall rules to permit CloudLens ingress traffic to any target tagged as `cl-tool` from CloudLens Collectors (`cl-collector`), as well as access to ntopng web interface

```Shell
gcloud compute --project=kt-nas-demo firewall-rules create "${gcp_owner_tag}-test-vpc-network-allow-vxlan" --description="Allow VxLAN ingress to any instance tagged as cl-tool" --direction=INGRESS --priority=1000 --network=${gcp_owner_tag}-test-vpc-network --action=ALLOW --rules=udp:4789 --source-tags=cl-collector --target-tags=cl-tool
gcloud compute --project=kt-nas-demo firewall-rules create "${gcp_owner_tag}-test-vpc-network-allow-ntopng" --description="Allow ntopng web access" --direction=INGRESS --priority=1000 --network=${gcp_owner_tag}-test-vpc-network --action=ALLOW --rules=tcp:3000 --source-ranges=0.0.0.0/0 --target-tags=cl-tool
```

## Create CloudLens Monitoring Policy

1. Using CloudLens Web UI, define a group with tag `cl-tool-1` as `Monitoring Tool`, of type Tool. Use `cl-tool-1` name
1. Using CloudLens Web UI, define a group with tag `cl-tool-2` as `Monitoring Tool`, of type Tool. Use `cl-tool-2` name
3. Define a group with network tags `gcp-server` as `CyPerf-Servers`, of type Instance Group
4. Create a connection from `CyPerf-Servers` to `cl-tool-1` with packet type `RAW`, encapsulation `VXLAN`. Use VNI: 101
5. Create a connection from `CyPerf-Servers` to `cl-tool-1` with packet type `RAW`, encapsulation `VXLAN`. Use VNI: 102


## Test 

1. Go to "Browse Configs", select "CyPerf Cloud Configs" on the left, and create session with "HTTP Throughput GCP Within VPC CompactPlacement c2-standard-16" test:

  * Select client and server agents to use for test – click icons with yellow exclamation signs.
  * Make sure "IP Network 1" and "IP Network 2" use "AUTOMATIC" IP assignment
  * In the Objectives and Timeline section, change throughput for Segment 1 to 10G or below. In the same area you can change the duration of the test.
  * Click START TEST



