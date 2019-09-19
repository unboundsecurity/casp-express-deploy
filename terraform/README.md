# Deploy CASP Using Terraform

[Terraform](https://www.terraform.io/) is a tool for infrastructure deployment, including deploying servers over AWS. It is used here to rapidly deploy a preconfigured [CASP](https://www.unboundtech.com/docs/CASP/CASP_User_Guide-HTML/Content/Products/CASP/CASP_Offering_Description/Solution.htm) system.

## Getting Started

**Step 1: The AWS Server**
1. Create an AWS account if you do not have one.
2. Pick a Linux-based server that will be used for CASP. It can be one of these platforms:
    - RHEL/CentOS 7.2 and later
	- Windows 10
	- Ubuntu 14.04/16.04/18.04
3. The platform must have these minimum requirements:
    - At least 200GB of disk space on the root volume.
    - At least 8GB of system memory.
    - At least 2 CPU cores.
	- Open SSL 1.1 or newer.
	
**Step 2: Install Terraform**
1. Download Terraform for Linux from https://www.terraform.io/downloads.html.
1. You need Terraform 0.12 or newer.
1. Install it.

**Step 3: Download and configure the CASP repo**
All of these steps should be executed on your AWS server.
1. Download or clone the CASP repo. 

    It contains these files:
    - variables.tf - Terraform configuration file.
    - unbound.tf - Terraform configuration file.
    - CASP_installer.sh - installer script.
	
What's with these?	
    - casp-1.0.XXX.YYYYY-RHES.x86_64.rpm
    - ekm-2.0.XXX.YYYYY-RHES.x86_64.rpm

2. Generate a key by running:
   ```
   ssh-keygen
   ```
   Use the default name when generating the key (i.e. when asked to choose a name for the key, just press **Enter**).
3. Edit *variables.tf*. In the file, set all the following variables:
	- variable "key_name" – the name shown in key name in the AWS console. 
	- variable "local_path" – path where you put the RPM installer files.
	- variable "casp_rpm_version_name" – casp rpm full name.
	- variable "ukc_rpm_version_name" – ukc rpm full name.
	- variable "token-blockcypher-btc" – BTC BlockCypher token (from https://www.blockcypher.com/).
	- variable "token-blockcypher-btctest" - BTCTEST BlockCypher token (from https://www.blockcypher.com/).
	- variable "token-infura-eth" – ETH Infura token (from https://infura.io/dashboard). 
	- variable "token-infura-ethtest" – ETHTEST Infura token (from https://infura.io/dashboard).
	- variable "firebase_apikey" - token for push notifications for mobile. 
4. Locate your *Access Key* and *Secret Access Key* on AWS:
    - Log into your [AWS Management Console](https://console.aws.amazon.com/console).
	- Click on your username at the top right of the page.
	- Click on the **Security Credentials** link from the drop-down menu.
	- Find the *Access Credentials* section, and copy the latest *Access Key ID*.
	- Click on the **Show** link in the same row, and copy the *Secret Access Key*.
5. Edit *unbound.tf*. Set the following variables:
	- access_key - replace it by AWS access_key.
	- secret_key - replace it by AWS secret_key.
6. Launch Terraform using the Unbound script:
    ```
    ./CASP_installer.sh 
    ```
    
