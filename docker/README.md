# Deploy CASP Using Docker

This is a quick start for [CASP](https://www.unboundtech.com/docs/CASP/CASP_User_Guide-HTML/Content/Products/CASP/CASP_Offering_Description/Solution.htm) that can be used for POCs and evaulations. It is based on Docker Compose.

**Note: This project should not be use for production.**

This project provides a quick and easy way to evaluate the Unbound CASP solution. Unbound CASP is composed of several components that need to be setup to work properly. Therefore, this quick start solution is provided to enable you to launch CASP without any configuration.

This implementation is only for demo proposes. For production, you must install and setup CASP as described in the [CASP User Guide](https://www.unboundtech.com/docs/CASP/CASP_User_Guide-HTML/Content/Products/CASP/CASP_User_Guide/Installation.htm#Installing-CASP).

## Prerequisites

1. Docker 18 or newer. See [Docker](https://www.docker.com).
2. An Infura access token (for Ethereum ledger access). See [Infura](https://infura.io/).
3. BlockCypher access token (for Bitcoin ledger access). See [BlockCypher](https://www.blockcypher.com).
4. Firebase messaging token (to enable push notifications). Contact Unbound for it.

## Overview

This CASP implementation provides the following components:

1. UKC - Unbound Key Managment servers, including an Entry Point, Partner and Auxiliary server.
2. PostgreSQL Database - used by CASP Service.
3. CASP Services - including the CASP core service and CASP wallet service.
4. CASP Bot - a CASP participant that automatically approves operations.

## Getting Started

1. Download or clone this repository.
2. Create an *.env* file in the same folder as the repository. The *.env* file holds your access token (see [Prerequisites](#Prerequisites)).

   For example:

   ```ini
    INFURA_TOKEN=<Replace with Infura access token>
    BLOCKCYPHER_TOKEN=<Replace with BlockCypher access token>
    FIREBASE_TOKEN=<Replace with Firebase token provided by Unbound>
   ```
3. Open a terminal, navigate to the folder, and execute the following command:

    ```bash
    docker-compose up
    ```

    The setup takes several minutes. Everything is ready when you see a message that the CASP bot is **starting to approve operations**.
4. Open your browser and navigate to `https://localhost/caspui`.

## Troubleshooting

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

## Tips

### Installing Docker on CentOS 7

The default Docker installed by `yum` is an older version of Docker. You can use the technique below to update to a newer Docker version.

```bash
sudo yum install -y yum-utils   device-mapper-persistent-data   lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y install docker-ce
sudo systemctl start docker
sudo curl -L \
     "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" \
     -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```
