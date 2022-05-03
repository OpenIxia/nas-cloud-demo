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

9. Choose "I already have a project", and then create a project by clicking ‘+’. Use any project name you see fit. Open the project. Click "SHOW PROJECT KEY" and copy the key.


## Test 

1. Go to "Browse Configs", select "CyPerf Cloud Configs" on the left, and create session with "HTTP Throughput GCP Within VPC CompactPlacement c2-standard-16" test:

  * Select client and server agents to use for test – click icons with yellow exclamation signs.
  * Make sure "IP Network 1" and "IP Network 2" use "AUTOMATIC" IP assignment
  * In the Objectives and Timeline section, change throughput for Segment 1 to 10G or below. In the same area you can change the duration of the test.
  * Click START TEST



