#===================================
# Start of user configration section
#===================================

variable "public_key_path" { default = "/home/autobuild/.ssh/id_rsa.pub" }
variable "private_key_path" { default = "/home/autobuild/.ssh/id_rsa" }
variable "key_name" { default = "name for the project" }
variable "local_path" { default = "path to the place where rpm files are located" }
variable "casp_rpm_version_name" { default = "casp rpm file name" }
variable "ukc_rpm_version_name" { default = "ekm rpm file name" }

variable "access_key" { default = "AWS access key" }
variable "secret_key" { default = "AWS secret key" }
variable "path_backup_keys" { default = "path to backup keys" }

variable "aws_region" { default = "location of amazon cloud. example: sa-east-1" }
variable "ukc_amis" {
  type = "map"
  default = {
# CentOS 7.6
# User: centos
    "us-west-1" = "ami-xxxxxxxxxxxxxxxx"
# RH 7.2
# User: ec2-user
    "sa-east-1" = "ami-xxxxxxxxxxxxxxxx"
  }
}

variable "casp_amis" {
  type = "map"
  default = {
# CentOS 7.6
# User: centos
    "us-west-1" = "ami-xxxxxxxxxxxxxxxx"
# RH 7.2
# User: ec2-user
    "sa-east-1" = "ami-xxxxxxxxxxxxxxxx"
  }
}

variable "resource-group-name" { default = "name for the project"}

variable "token-blockcypher-btc" { default = "!!!!!! replace it with blockcypher-btc token !!!!!!" }
variable "token-blockcypher-btctest" { default = "!!!!!! replace it by blockcypher-btctest token !!!!!!" }

variable "token-infura-eth" { default = "!!!!!! replace it with infura_eth token !!!!!!" }
variable "token-infura-ethtest" { default = "!!!!!! replace it with infura_ethtest token !!!!!!" }

#Firebase push notifaction push token
variable "firebase_apikey" {default = "Place your firebase mobile  push token here" }

#=================================
# End of user configration section
#=================================

#===============
# Provisioners
#===============

resource "random_string" "dbpasswd" {
  length = 32
  min_upper = 2
  min_lower = 2
  min_numeric = 2
  min_special = 2
  override_special = "!_+=:%"

  provisioner "local-exec" {
    command = "echo ${random_string.dbpasswd.result} > dbpasswd.txt"
  }
}

resource "random_string" "ukc-root-passwd" {
  length = 32
  min_upper = 2
  min_lower = 2
  min_numeric = 2
  min_special = 2
  override_special = "!_+=:%"

  provisioner "local-exec" {
    command = "echo ${random_string.ukc-root-passwd.result} > ukc-root-passwd.txt"
  }
}

resource "random_string" "ukc-casp-so-passwd" {
  length = 32
  min_upper = 2
  min_lower = 2
  min_numeric = 2
  min_special = 2
  override_special = "!_+=:%"

  provisioner "local-exec" {
    command = "echo ${random_string.ukc-casp-so-passwd.result} > ukc-casp-so-passwd.txt"
  }
}

resource "random_string" "ukc-casp-user-passwd" {
  length = 32
  min_upper = 2
  min_lower = 2
  min_numeric = 2
  min_special = 2
  override_special = "!_+=:%"

  provisioner "local-exec" {
    command = "echo ${random_string.ukc-casp-user-passwd.result} > ukc-casp-user-passwd.txt"
  }
}