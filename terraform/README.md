# Deploy CASP Using Terraform

[Terraform](https://www.terraform.io/) is a tool for infrastructure deployment over AWS. It is used here to deploy a preconfigured [CASP](https://www.unboundtech.com/docs/CASP/CASP_User_Guide-HTML/Content/Products/CASP/CASP_Offering_Description/Solution.htm) system.
    ![Alt text](./docs/terraform_casp.png "CASP Terraform Architecture")

## Prerequisites

   - Open SSL 1.1 or newer.
   - Terraform 0.12 or newer.
   - An AWS Account.
   - Linux-based machine: 
       - RHEL/CentOS 7.2 and later, Windows 10, or Ubuntu 14.04/16.04/18.04
       - At least 200GB of disk space on the root volume.
       - At least 8GB of system memory.
       - At least 2 CPU cores.
   
   - CASP Terraform package with the files:
       - variables.tf
       - unbound.tf
       - CASP_installer.sh
       - casp-1.0.XXX.YYYYY-RHES.x86_64.rpm
       - ekm-2.0.XXX.YYYYY-RHES.x86_64.rpm

## Build Instructions

1. Download Terraform for linux from: https://www.terraform.io/downloads.html and install it.

2. Type `ssh-keygen` and generate with the default name (When asked to choose a name for the key, leave it empty and press Enter).

3. Edit *variables.tf* using any text editor and enter the following variables:
	- variable key_name – the name shown in key name in the AWS console. 
	- variable local_path – path where you put the RPM installer files.
	- variable casp_rpm_version_name – casp rpm full name.
	- variable ukc_rpm_version_name – ukc rpm full name.
	- variable "token-blockcypher-btc" – BTC BlockCyper token (can be found at https://www.blockcypher.com/).
	- variable "token-blockcypher-btctest” - BTCTEST BlockCyper token (can be found at https://www.blockcypher.com/).
	- variable "token-infura-eth” – ETH Infura token (can be found at https://infura.io/dashboard). 
	- variable "token-infura-ethtest" – ETHTEST Infura token (can be found at https://infura.io/dashboard).
	- variable "firebase_apikey" - token for push notifications for mobile. 

4. Find your *Access Key* and *Secret Access Key* on AWS:
	
    - Log into your AWS Management Console.
	- Click on your username at the top right of the page.
	- Click on the **Security Credentials** link from the drop-down menu.
	- Find the *Access Credentials* section, and copy the latest *Access Key ID*.
	- Click on the **Show** link in the same row, and copy the Secret Access Key.
5. Edit *unbound.tf* using any text editor and enter the following variables:
	- access_key - replace it by AWS access_key.
	- secret_key - replace it by AWS secret_key.
6. Launch Terraform using the Unbound script:
    ```
    ./CASP_installer.sh 
    ```
    
