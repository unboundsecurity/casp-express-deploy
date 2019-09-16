# CASP Fast Deploy

Unbound’s Crypto Asset Security Platform (“**CASP**”) provides the advanced technology and the architecture to secure crypto asset transactions. An overview of the CASP solution is found [here](https://www.unboundtech.com/docs/CASP/CASP_User_Guide-HTML/Content/Products/CASP/CASP_Offering_Description/Solution.htm).

CASP can be rapidly deployed using one of these methods:
- [Docker](https://www.docker.com/products/docker-desktop) - Install CASP in a container. This method is intended for POCs.
- [Terraform](https://www.terraform.io/) - Use code to build the CASP infrastructure. This method is intended for production systems.

The rapid installation process is described below. For the full installation process, refer to the [CASP User Guide](https://www.unboundtech.com/docs/CASP/CASP_User_Guide-HTML/Content/Products/CASP/CASP_User_Guide/Installation.htm#Installing-CASP).

<a name="General-Prerequsites"></a>
# General Prerequsites
The following are required before installing CASP. 
1. An Infura access token (for Ethereum ledger access). See [Infura](https://infura.io/register).
   a. Register for the Infura site.
   a. Create a new project.
   a. Copy the access token from the project page.
1. BlockCypher access token (for Bitcoin ledger access). See [BlockCypher](https://accounts.blockcypher.com/signup).
   a. Register for the Blockcypher site.
   a. After verifying your email, it opens a page that displays the token.
1. Firebase messaging token (to enable push notifications). Contact Unbound for it.

# Installation
After completing the prerequisites, follow the instructions based on the installation type:
- [Docker](./docker)
- [Terraform](./terraform)
