variable "public_key_path" { default = "/home/autobuild/.ssh/id_rsa.pub" }
variable "private_key_path" { default = "/home/autobuild/.ssh/id_rsa" }
variable "local_path" { default = "replace it with path to terraform tf files/home/autobuild/CASP_terraform/test190819/" }
variable "casp_rpm" { default = "replace it with casp rpm  casp-1.0.2001.38807-RHES.x86_64.rpm" }
variable "ukc_rpm" { default = "replace it with ekm rpm  ekm-2.0.1907.38507-RHES.x86_64.rpm" }
variable "access_key" { default = "replace it with AWS access_key" }
variable "secret_key" { default = "replace it with AWS secret_key" }
variable "path_backup_keys" { default = "/home/centos/" }


variable "resource-group-name" { default = "Terraform-CASP-demo"}
variable "ep_public_key_path" { default = "/home/autobuild/.ssh/id_rsa.pub" }
variable "ep_private_key_path" { default = "/home/autobuild/.ssh/id_rsa" }
variable "partner_public_key_path" { default = "/home/autobuild/.ssh/id_rsa.pub" }
variable "partner_private_key_path" { default = "/home/autobuild/.ssh/id_rsa" }
#
# variable "key_name": default may not contain interpolations
#
variable "key_name_0" { default = "terraform_ukc_ep_key" }
variable "key_name_1" { default = "terraform_ukc_partner_aux_key" }
variable "key_name_2" { default = "terraform_casp_key" }


variable "password1" { default = "Password1!" }
variable "os_user_0" {default = "centos" }


variable "provide_ssh" {
  description = "If true, id_rsa key will be copied to bastion and hosts in the private subnet will be accessible by 2 hops"
}


variable "aws_region" { default = "sa-east-1" }
variable "instance_type" { default = "t2"}


variable "casp_ami" { default = "ami-xxxxxxxxxxxxxxxx"}

variable "token-blockcypher-btc" { default = "replace it with blockcypher-btc token" }
variable "token-blockcypher-btctest" { default = "replace it by blockcypher-btctest token" }

variable "token-infura-eth" { default = "replace it with infura_eth token" }
variable "token-infura-ethtest" { default = "replace it with infura_ethtest token" }

#Firebase push notifaction push token
variable "firebase_apikey" {default = "Place your firebase mobile  push token here" }


