# 1. Deploy CASP Using Docker

This project provides a quick and easy way to evaluate the Unbound [CASP](https://www.unboundtech.com/docs/CASP/CASP_User_Guide-HTML/Content/Products/CASP/CASP_Offering_Description/Solution.htm) solution. Unbound CASP is composed of several components that need to be setup to work properly. Therefore, this quick start solution is provided to enable you to launch CASP without any configuration using Docker.

**Note: This project is intended to be used for POCs, demoes and development. For production, you can [Deploy CASP Using Terraform](../casp-terraform/README.md).**

## 1.1. Getting Started

Use these instructions to get CASP running using Docker.

1. Complete the [General Prerequisites](../README.md#General-Prerequsites).
1. If you are not registered for Docker, follow the [registration process](https://hub.docker.com/?overlay=onboarding).
1. [Contact Unbound](mailto:support@unboundtech.com) and provide us with your Docker username to get access to the Docker images.
1. Install Docker.
    - For Windows:
        - Install Docker Desktop CE (community edition). It must include Docker Engine version 19.03 or newer. You can get the latest version from [Docker](https://hub.docker.com/?overlay=onboarding).
        - Use the default Docker settings during installation.
   - For Linux:
        - Follow the instructions to [install Docker Compose](https://docs.docker.com/compose/install/).

1. Download or clone this repository from the [main page](https://github.com/unbound-tech/CASP-Express-Deploy) or click [here](https://github.com/unbound-tech/CASP-Express-Deploy/archive/master.zip).
1. The downloaded repository file should be uncompressed and placed on the device where you will run Docker. The download contains a folder called *casp-docker*. You must start Docker from this folder.
1. Open a terminal and navigate to the `casp-docker` folder.
1. Create a file called *.env* in the same folder as the repository. The *.env* file holds your access tokens (see [Prerequisites](#Prerequisites)). 

   Note: The file must not have any prefix, i.e. the file name must be *.env*. If you are on Windows and it doesn't let you create a file with this name, use *.env.* (with a period at the end) for the name, then click OK twice, and it will create the *.env* file.
   
   Note: The file must be in the same folder as *docker-compose.yml*.

   For example:

   ```ini
    INFURA_TOKEN=<Replace with Infura access token>
    BLOCKCYPHER_TOKEN=<Replace with BlockCypher access token>
    FIREBASE_TOKEN=<Replace with Firebase token provided by Unbound>
   ```
1. Check that Docker is running.

You can check if Docker is running with the command `docker info`. If it returns an error, then it is not running. Otherwise, it returns status information about the Docker installation.
1. Run this command to log into Docker:
    ````bash
	docker login
    ````
    Enter the credentials that you created for the Docker Hub website.
		
    After successful login you see:
    ````
    Login Succeeded
    ````
1. Run Docker to create the CASP container:
    ```bash
    docker-compose up
    ```
    The setup takes several minutes to complete.
	
	Everything is installed and working when you see this message:
    ```
    casp-bot_1 |  Starting to approve operations
    ```

**Congratulations! CASP is now running.**

## 1.2. Next Steps
After installation, you can try some of these:
1. [Explore the web interface](./#webint)
1. [Create and activate a mobile client](./#caspclient)


<a name="webint"></a>
## 1.2.1. Explore the Web Interface
Open your browser and navigate to `https://localhost/caspui`. Use these credentials to log in:
    - Username: so
    - Password: Unbound1!

The Web UI provides the following screens:

- Accounts - provides information about your accounts, including the pending and total number of participants, vaults and operations.
- Users - lists all users for the account.
- Vaults - lists all vaults associated with the account.
- Operations - lists all quorum operations for the account.
- System - provides status information about various components in the system.

For more information on how to use the web interface, see [UKC User Guide](https://www.unboundtech.com/docs/UKC/UKC_User_Guide/HTML/Content/Products/UKC-EKM/UKC_User_Guide/UI/A1.html).

<a name="caspclient"></a>
## 1.2.2. Create and activate a mobile client

Information about installing the CASP mobile app can be found [here](https://www.unboundtech.com/docs/CASP/CASP_User_Guide-HTML/Content/Products/CASP/CASP_User_Guide/Mobile_App.htm).

## 1.3. Restarting/Updating Docker

To update and restart Docker:

1. Ensure that the previous session is finished:
    ```bash
    docker-compose down
    ```
2. Get the latest files:
    ```bash
    docker-compose pull
    ```
3. Retart Docker:
    ```bash
    docker-compose up
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

### 1.5.1. Cannot open the web console

If you cannot open the CASP web console in your browser, you might have port 443 in use by another service.

You can change CASP web console port by editing `docker-compose.yml`, and replacing the CASP export port with a different port.

For example, to change the port from 443 to 9443: 
1. Change `"443:443"` to `"9443:443"`. 
2. Restart the Docker with:

    ```bash
    docker-compose down
    docker-compose up
    ```
3. Use `https://localhost:9443/caspui` to open CASP web console.

### 1.5.2. Virtualization

If you need to turn on virtualization on your Windows device, use these instructions:

- Enable Hyper-V using the [instructions from Microsoft](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v).
- You must [enable virtualization](https://blogs.technet.microsoft.com/canitpro/2015/09/08/step-by-step-enabling-hyper-v-for-use-on-windows-10/) in the BIOS on your device.

### 1.5.3. Docker hangs when starting
    
Docker takes several minutes to create the UKC system. If it hangs for too long, use `Ctrl-c` to stop the process and then run the following commands to restart:
```bash
docker-compose down
docker-compose up
```
	
## 1.6. Tips

### 1.6.1. Installing Docker on CentOS 7

The default Docker installed by `yum` is an older version of Docker. You can use the technique below to update to a newer Docker version.

```bash
sudo yum install -y yum-utils   device-mapper-persistent-data   lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y install docker-ce
sudo systemctl start docker
sudo curl -L \
     "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" \
     -o /usr/local/docker-compose
sudo chmod +x /usr/local/docker-compose
```
