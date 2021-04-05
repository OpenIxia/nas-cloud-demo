# GCP Cloud Security Monitoring Demo

## Overview

The demo is targeting a passive network monitoring security tool deployment operating in a [Google Compute Cloud (GCP)](https://cloud.google.com/) environment. It is assumed the tool should be receiving network traffic via  [GCP Packet Mirroring](https://cloud.google.com/vpc/docs/packet-mirroring) service. Throughout the demo, a breach and attack simulation software [Keysight Threat Simulator](https://www.keysight.com/us/en/products/network-security/breach-defense/threat-simulator.html) is used to create conditions resemling a real malicious activity. The goals of the demo are:

* Validate operational readiness and basic efficacy of a network security moniring tool.
* Compare efficacy of multiple tools against identical attack scenarious.
* Fine tune configuration of the tool to increace its efficacy.

In this iteration of the demo, a combination of the following security monitoring products is being tested:

* Palo Alto Networks vm-series firewall acting as an IDS, and
* Splunk Enterprise log data indexing solution acting as a SIEM.

## IMPORTANT! Adopting command syntax to your environment

1. Throughout the document, a parameter ````--project=kt-nas-demo```` with GCP Project ID is used for ````gcloud```` command syntax. Please change ````ks-nas-demo```` to your GCP Project ID.
2. Where applicable, GCP Region ````us-west1```` (Oregon) and/or Zone ````us-west1-b```` are used withing the document. Consider changing to a region and zone that fit your deployment via ````--region=us-west1```` and ````--zone=us-west1-b```` parameters.

## GCP VPC Configuration

1. Create a demo VPC for Threat Simulator agent and IDS deployment. If needed, change IP address ranges to fit your design.

		Name: ts-demo-vpc
		Description: ThreatSim Demo
		Subnets: custom
			Name: ts-demo-app-subnet
				Region: us-west1
				IP address range: 192.168.201.0/24
			Name: ts-demo-ids-subnet
				Region: us-west1
				IP address range: 192.168.202.0/24

		gcloud compute networks create ts-demo-vpc --project=kt-nas-demo --description="ThreatSim Demo" --subnet-mode=custom --mtu=1460 --bgp-routing-mode=regional
		gcloud compute networks subnets create ts-demo-app-subnet --project=kt-nas-demo --range=192.168.201.0/24 --network=ts-demo-vpc --region=us-west1
		gcloud compute networks subnets create ts-demo-ids-subnet --project=kt-nas-demo --range=192.168.202.0/24 --network=ts-demo-vpc --region=us-west1

	For successful PAN deployment, we need another VPC to be on "trusted" security zone side on the PAN instance. It will not be used in any other way.

		Name: ts-pan-trust-vpc
		Description: ThreatSim Demo - Palo Alto Trusted NIC VPC
		Subnets: custom
			Name: ts-pan-trust-subnet
				Region: us-west1
				IP address range: 192.168.203.0/24
			

		gcloud compute networks create ts-pan-trust-vpc --project=kt-nas-demo --description="ThreatSim Demo - Palo Alto Trusted NIC VPC" --subnet-mode=custom --mtu=1460 --bgp-routing-mode=regional
		gcloud compute networks subnets create ts-pan-trust-subnet --project=kt-nas-demo --range=192.168.203.0/24 --network=ts-pan-trust-vpc --region=us-west1

2. Create VPC Firewall rules in ````ts-demo-vpc```` to permit HTTP and HTTPS traffic to any target tagged as ````http-server```` and ````https-server````

		gcloud compute --project=kt-nas-demo firewall-rules create ts-demo-allow-http --description="Allow http ingress to any instance tagged as http-server" --direction=INGRESS --priority=1000 --network=ts-demo-vpc --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server
		gcloud compute --project=kt-nas-demo firewall-rules create ts-demo-allow-https --description="Allow https ingress to any instance tagged as https-server" --direction=INGRESS --priority=1000 --network=ts-demo-vpc --action=ALLOW --rules=tcp:443 --source-ranges=0.0.0.0/0 --target-tags=https-server


## Threat Simulator Workload Deployment

1. If you do not have an active Threat Simulator account, request an evaluation access at [https://threatsimulator.cloud/login](https://threatsimulator.cloud/login)
2. Once the eval is approved, login to [Theat Simulator console](https://threatsimulator.cloud/login), navigate to Deployment page, and open "Anywhere" for a deployment type
3. Scroll down to AGENT INSTALLATION to a CURL command line, which looks similar to the following. In your case, there will be a different ````OrganizationID````. Agent version would vary with time as well.

		curl "https://api.threatsimulator.cloud/agent/download?OrganizationID=1234567890abcdef1234567890abcdef&Type=onpremise-linux" > agent-21.3.0.2325.run

4. Copy the 32-character value of ````OrganizationID```` string from the line above and paste it to the script below on the line ````organizationID```` right after the ````=```` sign. Deploy a Threat Simulator Agent instance on GCP by running the following command in GCP Console.

[//]: # (TODO consider making the name of the agent to reflect the instance name.)  

[//]: # (gcloud beta compute instances create ts-workload-1 \)
[//]: # (		--project=kt-nas-demo \)
[//]: # (--network-tier=PREMIUM \)
[//]: # (--maintenance-policy=MIGRATE \)
[//]: # (--reservation-affinity=any \)
[//]: # (--service-account=461244098184-compute@developer.gserviceaccount.com \)
[//]: # (--scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \)
[//]: # (--image=ubuntu-2004-focal-v20210315 \)
[//]: # (--boot-disk-type=pd-balanced \)
[//]: # (--no-shielded-secure-boot \)
[//]: # (--shielded-vtpm \)
[//]: # (--shielded-integrity-monitoring \)

		gcloud compute instances create ts-workload-1 \
		--zone=us-west1-b \
		--machine-type=e2-small \
		--subnet=ts-demo-app-subnet \
		--image-family=ubuntu-2004-lts \
		--image-project=ubuntu-os-cloud \
		--boot-disk-size=10GB \
		--boot-disk-device-name=ts-workload-1 \
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
			name="GCP-Demo-1"
			APIbaseURL="https://api.threatsimulator.cloud"
			curl $APIbaseURL/agent/download\?OrganizationID\=${organizationID}\&Type\=onpremise-linux >/home/threatsim/agent-init.run
			chown threatsim:threatsim /home/threatsim/agent-init.run
			sudo -u threatsim /bin/bash /home/threatsim/agent-init.run --quiet -- -y -n "${name}"
			if [ `docker ps -qf name=ts-filebeat | wc -l` -ge 1 ]; then touch /home/threatsim/.tsinstalled; fi
		fi'
		
5. After about 5 minutes the Threat Simulator workload should appear in Threat Simulator UI under [Agents](https://threatsimulator.cloud/security/agent) section

## Splunk SIEM Deployment

1. Deploy a VM Instance with Ubuntu 20.04 LTS for Splunk Enterprise

		gcloud beta compute --project=kt-nas-demo instances create ts-splunk-1 \
		--zone=us-west1-b \
		--machine-type=n1-standard-16 \
		--subnet=default \
		--network-tier=PREMIUM \
		--maintenance-policy=MIGRATE \
		--service-account=461244098184-compute@developer.gserviceaccount.com \
		--scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
		--image=ubuntu-2004-focal-v20210315 \
		--image-project=ubuntu-os-cloud \
		--boot-disk-size=100GB \
		--boot-disk-type=pd-balanced \
		--boot-disk-device-name=ts-splunk-1 \
		--no-shielded-secure-boot \
		--shielded-vtpm \
		--shielded-integrity-monitoring \
		--reservation-affinity=any \
		--tags=splunk-server

2. Open SSH session and download Splunk Enterprise Deb package

[//]: # (TODO save with a proper name to avoid mv)

		wget "https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=8.1.3&product=splunk&filename=splunk-8.1.3-63079c59e632-linux-2.6-amd64.deb&wget=true"
		mv DownloadActivityServlet\?architecture\=x86_64\&platform\=linux\&version\=8.1.3\&product\=splunk\&filename\=splunk-8.1.3-63079c59e632-linux-2.6-amd64.deb\&wget\=true splunk-8.1.3-63079c59e632-linux-2.6-amd64.deb
	
3. Install Splunk, provide admin username and password you would like to use when requested

		sudo dpkg -i splunk-8.1.3-63079c59e632-linux-2.6-amd64.deb
		dpkg --status splunk
		cd /opt/splunk/bin
		sudo ./splunk start --accept-license
		sudo ./splunk enable boot-start

4. Allow remote access to API

		sudo vi /opt/splunk/etc/system/local/server.conf
		# +++
		[general]
		allowRemoteLogin = always
		# ---
		sudo /opt/splunk/bin/splunk restart

5. Configure NTP for time syncronization on Splunk instance 
[//]: # (TODO check if chronyd is on by default - if so, than ntp is not needed)  

		sudo apt update
		sudo apt install ntp -y

6. Permit connection to Splunk services in VPC Firewall by running the following command in GCP Console

		gcloud compute --project=kt-nas-demo firewall-rules create bortok-ts-splunk --description="Access to Splunk instace" --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:8000 --source-ranges=0.0.0.0/0 --target-tags=splunk-server
		gcloud compute --project=kt-nas-demo firewall-rules create bortok-ts-splunk-syslog --description="Syslog to Splunk instace" --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:5514 --source-tags=ts-siem-agent --target-tags=splunk-server
		gcloud compute --project=kt-nas-demo firewall-rules create bortok-ts-splunk-api --description="API to Splunk instace" --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:8089 --source-tags=ts-siem-agent --target-tags=splunk-server
	
	
7. Access Splunk Web UI via browser on http port tcp/8000	
	
8. Use SIEM integration guide on https://threatsimulator.cloud/security/settings/siem/siem-deployment-how-to to setup Splunk integration

		SIEM API Token: xxx

	Create a SIEM Agent instance

		gcloud beta compute --project=kt-nas-demo instances create ts-siem-agent-1 \
		--zone=us-west1-b \
		--machine-type=e2-micro \
		--subnet=default \
		--network-tier=PREMIUM \
		--maintenance-policy=MIGRATE \
		--service-account=461244098184-compute@developer.gserviceaccount.com \
		--scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
		--image=ubuntu-2004-focal-v20210315 \
		--image-project=ubuntu-os-cloud \
		--boot-disk-size=10GB \
		--boot-disk-type=pd-balanced \
		--boot-disk-device-name=ts-siem-agent-1 \
		--no-shielded-secure-boot \
		--shielded-vtpm \
		--shielded-integrity-monitoring \
		--reservation-affinity=any \
		--tags=ts-siem-agent

	Download agent

		wget "https://api.threatsimulator.cloud/agent/download?OrganizationID=1234567890abcdef1234567890abcdef&Type=siem-agent-installer"
		sudo su -
		apt update
		apt -y install docker.io
		systemctl restart docker
		systemctl enable docker
		useradd -m -G google-sudoers threatsim
		APIbaseURL="https://api.threatsimulator.cloud"
		organizationID="1234567890abcdef1234567890abcdef"
		curl $APIbaseURL/agent/download\?OrganizationID\=${organizationID}\&Type\=siem-agent-installer >/home/threatsim/install-siem-agent.sh
		chown threatsim:threatsim /home/threatsim/install-siem-agent.sh
		sudo -u threatsim /bin/bash /home/threatsim/install-siem-agent.sh


9. Configure NTP for time syncronization on SIEM Agent instance 
[//]: # (TODO check if chronyd is on by default - if so, than ntp is not needed)

		sudo apt update
		sudo apt install ntp -y

10. Follow SIEM CONFIGURATION > SIEM SETUP > SPLUNK SIEM INSTRUCTIONS on https://threatsimulator.cloud/security/settings/siem/siem-deployment-how-to/splunk.

		Parameter 						| Value
		--- 									| ---
		Input Type 						| TCP Port
		Port Number 					| 5514
		Source name override 	| N/A
		Restrict to Host 			| N/A
		Source Type 					| threatsim
		App Context 					| TA_threatsimulator
		Method 								| IP
		Index 								| threatsim


## Prepare Splunk SIEM for Palo Alto Networks IDS integration

1. Start with Splunk SIEM configuration for Palo Alto Networks IDS. In Splunk Web UI, go to Apps → Find More Apps, type "Palo Alto Networks Add-on for Splunk" in search field. From search results, choose "Palo Alto Networks Add-on for Splunk" and click Install. Once done, click "Go Home".
2. Create index: Go to Settings > Data > Indexes. Select New index and configure the following and Save
	
		Index name: pan
		App: Palo Alto Networks Add-on

3.	Create data input (TCP): Go to Settings > Data > Data inputs. In the Local inputs section, click Add new (from TCP section). Configure:
	
		Parameter 						| Value
		--- 									| ---
		Input Type 						| TCP Port
		Port Number 					| 5614
		Source name override 	| N/A
		Restrict to Host 			| N/A
		Source Type 					| pan:log
		App Context 					| Palo Alto Networks Add-on
		Method 								| IP
		Index 								| pan

4. Permit connection to the Splunk Data input service in VPC Firewall by running the following command in GCP Console

		gcloud compute --project=kt-nas-demo firewall-rules create bortok-ts-splunk-syslog-pan --description="PAN Syslog to Splunk instace" --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:5614 --source-tags=pan-security --target-tags=splunk-server
	
5. Configure your specific timezone on Splunk instance via SSH

		sudo su -
		cd /opt/splunk/etc/apps/Splunk_TA_paloalto/local
		cat >> props.conf << EOF
		[pan:log]
		TZ = US/Pacific
		EOF
 

## Palo Alto Networks IDS deployment

1. Deploy PAN IDS instance. GCP Compute instances > Create new > Marketplace: Palo Alto VM-Series Next-Generation Firewall (Bundle1)

		Deployment name: vmseries-flex-bundle1-1
		Zone: us-west1-b
		Machine type: 4 vCPUs / 15G RAM
		Interfaces swap: Yes
		SSH Key: <admin:ssh-rsa ADD PUBLIC SSH KEY HERE>
		Networking (VPCs and subnets must be pre-created):
			Network (for nic0 - IDS): ts-demo-vpc
			Subnetwork: ts-demo-ids-subnet
			Enable External IP for Management inteface: No
			
			Network (for nic1 - MGMT): default
			Subnetwork: default
			Enable External IP for Untrust: Yes
			
			Network (for nic 2 - Trust): ts-pan-trust-vpc
			Subnetwork: ts-pan-trust-subnet
			Enable External IP for Trust: No

	See https://docs.paloaltonetworks.com/vm-series/9-1/vm-series-deployment/set-up-the-vm-series-firewall-on-google-cloud-platform/prepare-to-set-up-the-vm-series-firewall-on-a-google-instance.html#id1819C02I0AS_id821c495f-3ff8-488d-ab61-28692ab1ce26
	
2. Edit PAN IDS instance and add Network tags: ````pan-security````

4. Permit connection to PAN IDS management in VPC Firewall by running the following command in GCP Console

		gcloud compute --project=kt-nas-demo firewall-rules create bortok-ts-pan-mgmt --description="PAN Management" --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:443,tcp:22 --source-ranges=0.0.0.0/0 --target-tags=pan-security
		
5. Connect via SSH to the PAN IDS instance, setup admin password

		 ssh -i google_compute_engine admin@<pan_workload_ip_address>
		 configure
		 set mgt-config users admin password
		 commit

6. Register the PAN IDS instance on PAN support portal, download and install Dynamic Updates for Applications and Threats

7. Configure PAN as an IDS (outside the scope of this guide)

8. Configure Event forwarding from PAN IDS to Splunk (see "BreakingPoint Cloud – How to forward Palo Alto events to Splunk" guide). Note - using hostname for syslog server didn't work, you have to use an IP address

## GCP Packet Mirroring configuration
1. Start with creating an unmanaged GCP Instace Group for Packet Mirroring load balancer backends with PAN IDS monitoring interface:

		gcloud compute --project=kt-nas-demo instance-groups unmanaged create pan-ids-ig --zone=us-west1-b --description="PAN IDS group"
		gcloud compute --project=kt-nas-demo instance-groups unmanaged add-instances pan-ids-ig --zone=us-west1-b --instances=vmseries-flex-bundle1-1

2. To monitor PAN IDS instance availability, create a Health Check for SSH service and allow connections for this health check in Firewall rules

		gcloud beta compute health-checks create tcp ssh-health-check --project=kt-nas-demo --port=22 --proxy-header=NONE --no-enable-logging --description=TCP\ health-check\ for\ SSH\ service --check-interval=5 --timeout=5 --unhealthy-threshold=2 --healthy-threshold=2
		gcloud compute firewall-rules create fw-allow-health-checks \
		    --network=ts-demo-vpc \
		    --action=ALLOW \
		    --direction=INGRESS \
		    --source-ranges=35.191.0.0/16,130.211.0.0/22 \
		    --target-tags=pan-security \
		    --rules=tcp

3. VPC Network > Packet Mirroring, Create Policy. Take a note on Frontend Internal IP automatically assigned when creating a load balancer.

		Name: ts-demo-pan-mirror
		Region: us-west1
		Policy enforcement: Enabled
		Mirrored source and destinations are in the same VPC network: ts-demo-vpc
		Mirrored source: Select with network tags: ts-agent
		Mirrored destination: Create new L4 internal load balancer
			Name: ts-demo-pan-ids-ilb
			Backend configuration:
				Region: us-west1
				Network: ts-demo-vpc
				Backends instance Group: pan-ids-ig
				Health check: ssh-health-check
			Frontend configuration:
				Name: ts-demo-pan-ids-ilb-fe
				Subnetwork: ts-demo-ids-subnet
				Internal IP
					Purpose: Non-shared
					IP address: Static internal IP address
						Name: ts-demo-pan-ids-ilb-fe-ip
						Address: Assign automatically
				Global access: Disable
				Packet mirroring (advanced configuration): Enable this load balancer for Packet Mirroring
		Collector destination: ts-demo-pan-ids-ilb-fe
		Select mirrored traffic: Mirror all traffic

4. Create firewall rules to permit mirrored traffic

	Egress from source instances. Use an IP address assiged as a Frontend Internal IP in the previous step as ````--destination-ranges````.

		gcloud compute --project=kt-nas-demo firewall-rules create bortok-ts-demo-packet-mirror-egress --description="Packet mirroring egress from sources to PAN" --direction=EGRESS --priority=1000 --network=ts-demo-vpc --action=ALLOW --rules=all --destination-ranges=192.168.202.4/32

	Ingress to PAN IDS
	
		gcloud compute --project=kt-nas-demo firewall-rules create bortok-ts-demo-packet-mirror-pan --description="Packet mirrirong ingress traffic to PAN IDS" --direction=INGRESS --priority=1000 --network=ts-demo-vpc --action=ALLOW --rules=all --source-ranges=0.0.0.0/0 --target-tags=pan-security
	

4. In PAN IDS configuration, add a loopback.1 interface with an IP address assiged as a Frontend Internal IP in the previous step. Add loopback.1 to a virtual router configuration. Create static routes for the following health-check IP address ranges: ````35.191.0.0/16,130.211.0.0/22```` pointing to a default gateway in the subnet of ````Ethenet1/1```` interface: ````192.168.202.1````

## AUX

### Permit SSH via Browser
Default VPC

		gcloud compute --project=kt-nas-demo firewall-rules create bortok-allow-ssh-from-browser --description="https://cloud.google.com/iap/docs/using-tcp-forwarding" --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:22 --source-ranges=35.235.240.0/20

ts-demo-vpc VPC

		gcloud compute --project=kt-nas-demo firewall-rules create bortok-allow-ssh-from-browser-ts-demo-vpc --description="https://cloud.google.com/iap/docs/using-tcp-forwarding" --direction=INGRESS --priority=1000 --network=ts-demo-vpc --action=ALLOW --rules=tcp:22 --source-ranges=35.235.240.0/20


