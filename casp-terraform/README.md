# 1. Deploy CASP Using Terraform

[Terraform](https://www.terraform.io/) is a tool for infrastructure deployment, including deploying servers over AWS. It is used here to rapidly deploy a preconfigured [CASP](https://www.unboundtech.com/docs/CASP/CASP_User_Guide-HTML/Content/Products/CASP/CASP_Offering_Description/Solution.htm) system.

## 1.1 Installation

**Step 1: The AWS Server**
1. Create an AWS account if you do not have one.
2. Check your AWS permissions that you can create and configure EC2 instances, VPCs, security groups, public IP addresses, and DNS.
	
**Step 2: Install Terraform**
1. Download Terraform for Linux from [here](https://www.terraform.io/downloads.html).
    - You need Terraform 0.12 or newer.
1. Uncompress the archive that you downloaded. It contains the Terraform executable.

**Step 3: Download and configure the CASP repo**

All of these steps should be executed on your AWS server.
1. Download or clone the CASP repo. 

    It contains these files:
    - CASP_variables.tf - Terraform configuration file.
    - CASP_unbound.tf - Terraform configuration file.
	
1. [Contact Unbound](mailto:support@unboundtech.com) to get links to download the **UKC server** and **CASP server** packages for RedHat. The packages have these formats:
    - casp-1.0.XXX.YYYYY-RHES.x86_64.rpm
    - ekm-2.0.XXX.YYYYY-RHES.x86_64.rpm

1. Generate a key by running:
   ```
   ssh-keygen
   ```
   Use the default name when generating the key (i.e. when asked to choose a name for the key, just press **Enter**).
1. Locate your *Access Key* and *Secret Access Key* on AWS.
    - Log into your [AWS Management Console](https://console.aws.amazon.com/console).
	- Click on your username at the top right of the page.
	- Click on the **Security Credentials** link from the drop-down menu.
	- Find the *Access Credentials* section, and copy the latest *Access Key ID*.
	- Click on the **Show** link in the same row, and copy the *Secret Access Key*.
1. Generate the CASP backup key.
    ```
    openssl genrsa 2048 > key.pem
    openssl rsa -in key.pem -pubout > casp_backup.pem
    ```
    The CASP backup key can be used to restore the system, as described [here](https://www.unboundtech.com/docs/CASP/CASP_User_Guide-HTML/Content/Products/CASP/CASP_User_Guide/Key_Backup_and_Restore.htm).
1. Edit *CASP_unbound.tf*. Set the following variables:
	- access_key - replace it by AWS access_key.
	- secret_key - replace it by AWS secret_key.
1. Edit *CASP_variables.tf*. In the file, follow the comments to set all the necessary variables.    
1. Start Terraform. This step uses the executable that was downloaded in Step 2. You may need to add it to your path.
   ```
   $ terraform init
   ```
1. Apply the configuration file.
   ```
   $ terraform apply
   ```

**Congratulations! CASP is now running.**

## 1.2. Next Steps
After installation, you can try some of these tasks:
1. [Explore the web interface](./#webint)
1. [Create and activate a mobile client](./#caspclient)
1. [Develop your own application using the CASP SDK](./#caspsdk)

<a name="webint"></a>
## 1.2.1. Explore the Web Interface
Open your browser and navigate to `https://<docker-ip-address>/caspui`, where *docker-ip-address* is the server where you installed Docker. Use these credentials to log in:
- Username: so
- Password: Unbound1!

The Web UI provides the following screens:

- Accounts - provides information about your accounts, including the pending and total number of participants, vaults and operations.
- Users - lists all users for the account.
- Vaults - lists all vaults associated with the account.
- Operations - lists all quorum operations for the account.
- System - provides status information about various components in the system.

For more information on how to use the web interface, see [CASP User Guide](https://www.unboundtech.com/docs/CASP/CASP_User_Guide-HTML/Content/Products/CASP/CASP_User_Guide/Web_Interface.htm).

<a name="caspclient"></a>
## 1.2.2. Create and activate a mobile client

Information about installing the CASP mobile app can be found [here](https://www.unboundtech.com/docs/CASP/CASP_User_Guide-HTML/Content/Products/CASP/CASP_User_Guide/Mobile_App.htm).

<a name="caspsdk"></a>
## 1.2.3. Develop your own application using the CASP SDK

You can use the CASP SDK to develop your own application. See the [CASP Developers Guide](https://www.unboundtech.com/docs/CASP/CASP_Developers_Guide-HTML/Content/Products/Unbound_Cover_Page.htm) for more information and a full API reference.

Also, refer to the [CASP BYOW JS Demo](https://github.com/unbound-tech/CASP-BYOW-JS-Demo) for sample code.

## 1.3 Terminating CASP
Use this command to terminate CASP.
   ```
   $ terraform destroy
   ```
    
## 1.4. More Information
This release has these associated documents:

- [CASP User Guide](https://www.unboundtech.com/docs/CASP/CASP_User_Guide-HTML/Content/Products/Unbound_Cover_Page.htm)
    - [CASP Web UI](https://www.unboundtech.com/docs/CASP/CASP_User_Guide-HTML/Content/Products/CASP/CASP_User_Guide/Web_Interface.htm) - explore more about the WEb UI.
    - [CASP Mobile App](https://www.unboundtech.com/docs/CASP/CASP_User_Guide-HTML/Content/Products/CASP/CASP_User_Guide/Mobile_App.htm) - add more participants that use the CASP Mobile app.
- [CASP Frequently Asked Questions](https://www.unboundtech.com/docs/CASP/CASP_FAQ-HTML/Content/Products/Unbound_Cover_Page.htm)
- [CASP Developers Guide with API Reference](https://www.unboundtech.com/docs/CASP/CASP_Developers_Guide-HTML/Content/Products/Unbound_Cover_Page.htm)
- [CASP Participant SDK](https://www.unboundtech.com/docs/CASP/CASP_Participant_SDK-HTML/Content/Products/Unbound_Cover_Page.htm)

## 1.5. Troubleshooting

### 1.5.1. CASP logs

You can see the CASP log files by logging into the Docker container and then finding the CASP logs. See [here](https://www.unboundtech.com/docs/CASP/CASP_User_Guide-HTML/Content/Products/CASP/CASP_User_Guide/Audit_and_Logging.htm) for more information about the CASP logs.

