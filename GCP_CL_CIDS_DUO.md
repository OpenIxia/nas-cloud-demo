# Keysight CloudLens sandbox on Google Cloud with Cloud IDS and 3rd party sensor

## Overview

This sandbox is targeting traffic monitoring scenario in Google Cloud with a combination of native Cloud IDS service and a 3rd party network traffic sensor. At the moment of writing, Google Cloud IDS does not support its simulteneous use with 3rd party sensors. There are cases, when Google Cloud customers have a need to use a 3rd party sensor, for example, Zeek network traffic analyzer, to enable threat hunting efforts, or any other reason. At the same time, they might find ease of use provided by Cloud IDS, appealing to enable network threat detection. Although such cases are not supported by Cloud IDS yet, it becomes possible to implement them via Keysight CloudLens - a distributed cloud packet broker. As with physical network packet brokers, CloudLens is capable of aggregating monitored cloud traffic via its collectors, and then feeding it to both 3rd party tools like Zeek, as well as Cloud IDS, for analysis and detection.

The goals of the sandbox are:

* Validate compatibility of CloudLens operational model with Cloud IDS.
* Provide a blueprint for CloudLens deployment in Google Cloud to feed multiple network analysis tools.

## Diagram

![CloudLens sandbox with Google Cloud IDS and 3rd party tool diagram](diagrams/GCP_CL_CIDS_DUO.png)

## Adopting command syntax to your environment

1. Throughout the document, a GCP Project ID parameter `--project=kt-nas-demo` is used for `gcloud` command syntax. Please change `kt-nas-demo` to specify a GCP Project ID you intend to use for the deployment
2. Where applicable, GCP Region `us-central1` and/or Zone `us-central1-a` are used withing the document. Consider changing to a region and zone that fit your deployment via `--region=us-central1` and `--zone=us-central1-a` parameters.

## Google Cloud VPC Configuration

1. Create a NAS Sandbox VPC for Threat Simulator agent and CloudLens Collector deployment. If needed, change IP address ranges to fit your design.

| Parameter 						| Value
| --- 									| ---
| Name 									| `nas-sandbox-vpc`
| Description 					| Keysight NAS Sandbox
| Subnets 							| custom
| &nbsp;&nbsp;&nbsp;&nbsp;Name 								| `nas-sandbox-app-subnet`
| &nbsp;&nbsp;&nbsp;&nbsp;Region 							| us-central1
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;IP address range 	| `192.168.221.0/24`
| &nbsp;&nbsp;&nbsp;&nbsp;Name 								| `nas-sandbox-collector-subnet`
| &nbsp;&nbsp;&nbsp;&nbsp;Region 							| us-central1
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;IP address range 	| `192.168.222.0/24`

```Shell
gcloud compute networks create nas-sandbox-vpc --project=kt-nas-demo --description="Keysight NAS Sandbox" --subnet-mode=custom --mtu=1460 --bgp-routing-mode=regional
gcloud compute networks subnets create nas-sandbox-app-subnet --project=kt-nas-demo --range=192.168.221.0/24 --network=nas-sandbox-vpc --region=us-central1
gcloud compute networks subnets create nas-sandbox-collector-subnet --project=kt-nas-demo --range=192.168.222.0/24 --network=nas-sandbox-vpc --region=us-central1
```

Cloud IDS service operates via [Private Service Access](https://cloud.google.com/vpc/docs/configure-private-services-access) network connectivity. To start using Cloud IDS, you must enable Private Services Access and allocate an IP address range for private connectivity with Cloud IDS Service Producer. From GCP documentation: "When you create an IDS endpoint, a subnet with a 27-bit mask is allocated from your Private Service Access allocated IP address ranges. The allocated subnet contains an internal load-balancer. Any traffic mirrored or directed to this load-balancer will be inspected by the IDS endpoint."

2. Activate the Service Networking API in your project. The API is required to create a private connection.

```Shell
gcloud services enable servicenetworking.googleapis.com --project=kt-nas-demo
```

3. Allocate an IP range for Google-produced Private Services

```Shell
gcloud compute addresses create google-managed-services-nas-sandbox-vpc \
    --global \
    --purpose=VPC_PEERING \
    --addresses=172.18.248.0 \
    --prefix-length=22 \
    --description="Peering range for Google Managed Services" \
    --network=nas-sandbox-vpc \
    --project=kt-nas-demo
```

You can check IP ranges currently allocated using

```Shell
gcloud compute addresses list --global --filter="purpose=VPC_PEERING AND network=nas-sandbox-vpc"
```

4. Now create a private connection using the IP range

```Shell
gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --ranges=google-managed-services-nas-sandbox-vpc \
    --network=nas-sandbox-vpc \
    --project=kt-nas-demo
```

To check if the operation was successful list existing connections

```Shell
gcloud services vpc-peerings list \
    --network=nas-sandbox-vpc \
    --project=kt-nas-demo
```

5. Create VPC Firewall rules in `nas-sandbox-vpc` to permit HTTP and HTTPS traffic to any target tagged as `http-server` and `https-server`

```Shell
gcloud compute --project=kt-nas-demo firewall-rules create nas-sandbox-allow-http --description="Allow http ingress to any instance tagged as http-server" --direction=INGRESS --priority=1000 --network=nas-sandbox-vpc --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server
gcloud compute --project=kt-nas-demo firewall-rules create nas-sandbox-allow-https --description="Allow https ingress to any instance tagged as https-server" --direction=INGRESS --priority=1000 --network=nas-sandbox-vpc --action=ALLOW --rules=tcp:443 --source-ranges=0.0.0.0/0 --target-tags=https-server
```

6. (Optional) Permit SSH access to GCP instances via a browser. See [https://cloud.google.com/iap/docs/using-tcp-forwarding](https://cloud.google.com/iap/docs/using-tcp-forwarding) for more information.

```Shell
gcloud compute --project=kt-nas-demo firewall-rules create allow-ssh-from-browser-nas-sandbox-vpc --description="https://cloud.google.com/iap/docs/using-tcp-forwarding" --direction=INGRESS --priority=1000 --network=nas-sandbox-vpc --action=ALLOW --rules=tcp:22 --source-ranges=35.235.240.0/20
```


## Threat Simulator Workload Deployment

1. If you do not have an active Threat Simulator account, request evaluation access at [https://threatsimulator.cloud/login](https://threatsimulator.cloud/login)
2. Once the eval is approved, login to [Theat Simulator console](https://threatsimulator.cloud/login), navigate to Deployment page, and open "Anywhere" for a deployment type
3. Scroll down to AGENT INSTALLATION to a CURL command line, which looks similar to the following. In your case, there will be a different `OrganizationID`. Agent version would vary with time as well.

```Shell
curl "https://api.threatsimulator.cloud/agent/download?OrganizationID=1234567890abcdef1234567890abcdef&Type=onpremise-linux" > agent-21.3.0.2325.run
```

4. Copy the 32-character value of `OrganizationID` string from the line above and paste it to the script below on the line `organizationID` right after the `=` sign. Deploy a Threat Simulator Agent instance on GCP by running the following command in GCP Console.

[//]: # (TODO consider making the name of the agent to reflect the instance name.)  

```Shell
gcloud compute instances create ts-workload-cl-1 \
--zone=us-central1-a \
--machine-type=e2-small \
--subnet=nas-sandbox-app-subnet \
--no-address \
--image-family=ubuntu-2004-lts \
--image-project=ubuntu-os-cloud \
--boot-disk-size=10GB \
--boot-disk-device-name=ts-workload-cl-1 \
--tags=ts-agent,http-server,https-server \
--metadata=startup-script='#!/bin/bash -xe
if [ ! -f /home/threatsim/.tsinstalled ]; then
	sysctl -w net.ipv6.conf.all.disable_ipv6=1
	sysctl -w net.ipv6.conf.default.disable_ipv6=1
	apt update
	apt -y install docker.io
	systemctl restart docker
	systemctl enable docker
	useradd -m -G google-sudoers threatsim
	organizationID="1234567890abcdef1234567890abcdef"
	name="NAS-Sandbox-CloudLens-1"
	APIbaseURL="https://api.threatsimulator.cloud"
	curl $APIbaseURL/agent/download\?OrganizationID\=${organizationID}\&Type\=onpremise-linux >/home/threatsim/agent-init.run
	chown threatsim:threatsim /home/threatsim/agent-init.run
	sudo -u threatsim /bin/bash /home/threatsim/agent-init.run --quiet -- -y -n "${name}"
	if [ `docker ps -qf name=ts-filebeat | wc -l` -ge 1 ]; then touch /home/threatsim/.tsinstalled; fi
fi'
```
		
5. After about 5 minutes the Threat Simulator workload should appear in Threat Simulator UI under [Agents](https://threatsimulator.cloud/security/agent) section
