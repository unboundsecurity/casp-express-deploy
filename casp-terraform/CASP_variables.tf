variable "access_key" { default = "<Access Key>" }
variable "secret_key" { default = "<Secret Key>" }
variable "resource-group-name" { default = "Terraform-CASP-demo"}
variable "ep_public_key_path" { default = "/home/<your user>/.ssh/<public key>" }
variable "ep_private_key_path" { default = "/home/<your user>/.ssh/<private key>" }
variable "partner_public_key_path" { default = "/home/<your user>/.ssh/<public key>" }
variable "partner_private_key_path" { default = "/home/<your user>/.ssh/<private key>" }
variable "key_name_0" { default = "Terraform-CASP-UKC-EP-key" }
variable "key_name_1" { default = "Terraform-CASP-UKC-Partner-AUX-key" }
variable "password1" { default = "Password1!" }
variable "aws_region" { default = "<AWS region>" }
variable "ukc_pac" { default = "ekm-<UKC version>-RHES.x86_64.rpm" }
variable "os_user_0" { default = "centos" }
variable "instance_type_ukc" { default = "<AWS instance type>" }

variable "provide_ssh" {
  description = "If true, id_rsa key will be copied to bastion and hosts in the private subnet will be accessible by 2 hops"
}

variable "casp_public_key_path" { default = "/home/<your user>/.ssh/<public key>" }
variable "casp_private_key_path" { default = "/home/<your user>/.ssh/<private key>" }
variable "key_name_3" { default = "Terraform-CASP-key" }
variable "casp_backup_key_path" { default = "<casp backup pem file>" }
variable "casp_pac" { default = "casp-<CASP version>-RHES.x86_64.rpm" }
variable "instance_type_casp" { default = "<AWS instance type>" }

variable "token-blockcypher-btc" { default = "<blockcypher-btc token>" }
variable "token-blockcypher-btctest" { default = "<blockcypher-btctest token>" }

variable "token-infura-eth" { default = "<infura_eth token>" }
variable "token-infura-ethtest" { default = "<infura_ethtest token>" }

#Firebase push notifaction push token
variable "firebase_apikey" {default = "Place your firebase mobile  push token here" }

