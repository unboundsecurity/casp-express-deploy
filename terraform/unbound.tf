# unbound.tf -- Create stand-alone Unbound infrastructure from VPC
#

provider "aws" {
  region = "${var.aws_region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"

}

data "aws_availability_zones" "available" {}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_vpc" "unbound" {
  cidr_block           = "10.137.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

   tags = {
    Name = "${var.resource-group-name}: VPC"
  }
}

locals {
  domain = "unbound-${terraform.workspace}"
}

resource "aws_route53_zone" "unbound" {
  name = "${local.domain}"

  vpc {
    vpc_id = "${aws_vpc.unbound.id}"
  }

   tags = {
    Name = "${var.resource-group-name}: Route 53 zone"
  }
}

resource "aws_vpc_dhcp_options" "unbound" {
  domain_name         = "${local.domain}"
  domain_name_servers = ["AmazonProvidedDNS"]

   tags = {
    Name = "${var.resource-group-name}: DHCP"
  }
}

resource "aws_vpc_dhcp_options_association" "unbound" {
  vpc_id          = "${aws_vpc.unbound.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.unbound.id}"
}

resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.unbound.id}"
  cidr_block              = "10.137.0.0/24"
  map_public_ip_on_launch = true

  availability_zone = "${data.aws_availability_zones.available.names[0]}"


  tags = {
    Name = "${var.resource-group-name}: Public subnet 0"
  }
}
#for DB check order!!!
resource "aws_subnet" "private1" {
  vpc_id                  = "${aws_vpc.unbound.id}"
  cidr_block              = "10.137.1.0/24"
  map_public_ip_on_launch = false

  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  depends_on = ["aws_route53_zone.unbound"]

  tags = {
    Name = "${var.resource-group-name}: Private subnet 1"
  }
}
#for EKM check order!!!
resource "aws_subnet" "private2" {
  vpc_id                  = "${aws_vpc.unbound.id}"
  cidr_block              = "10.137.2.0/24"
  map_public_ip_on_launch = false

  availability_zone = "${data.aws_availability_zones.available.names[1]}"

  depends_on = ["aws_route53_zone.unbound"]

  tags = {
    Name = "${var.resource-group-name} unbound-private2"
  }
}

resource "aws_db_subnet_group" "caspdb" {
  name        = "unbound-dbprivate_${var.key_name}"
  description = "Subnets for database"
  subnet_ids  = ["${aws_subnet.private1.id}", "${aws_subnet.private2.id}"]
}

resource "aws_internet_gateway" "public" {
  vpc_id = "${aws_vpc.unbound.id}"

   tags = {
    Name = "${var.resource-group-name}: Public gateway"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.unbound.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.public.id}"
}

resource "aws_security_group" "caspdb" {
  name        = "CASP Database"
  description = "Default Postgres access"
  vpc_id      = " ${aws_vpc.unbound.id}"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   tags = {
    Name = "${var.resource-group-name}: Security group beetwen word and EP"
  }
}

resource "aws_security_group" "casp" {
  name        = "CASP"
  description = "Default CASP access"
  vpc_id      = "${aws_vpc.unbound.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

 tags = {
    Name = "${var.resource-group-name}: Security group beetwen CASP and EP"
  }
}

resource "aws_security_group" "ukc" {
  name        = "UKC"
  description = "Security group beetwen EP, Partner and AUX"
  vpc_id      = "${aws_vpc.unbound.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6603
    to_port     = 6603
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   tags = {
    Name = "${var.resource-group-name}: Security group beetwen EP, Partner and AUX"
  }
}

resource "aws_db_instance" "caspdb" {
  #  count = "${terraform.workspace == "production" ? 0 : 1}"

  engine                  = "postgres"
  allocated_storage       = 20
  backup_retention_period = 1
  instance_class          = "db.t2.medium"
  apply_immediately       = true

  db_subnet_group_name = "${aws_db_subnet_group.caspdb.id}"
  multi_az             = false
  username             = "postgres"
  password             = "${random_string.dbpasswd.result}"
  storage_encrypted    = true
  storage_type         = "standard"

  vpc_security_group_ids = ["${aws_security_group.caspdb.id}"]
  skip_final_snapshot    = true

  tags = {
    Name = "${var.resource-group-name} CASP Database"
  }
}

resource "aws_route53_record" "caspdb" {
  zone_id = "${aws_route53_zone.unbound.zone_id}"
  name    = "caspdb"
  type    = "CNAME"
  ttl     = "5"
  records = ["${aws_db_instance.caspdb.address}"]
}

#########################################
# UKC bootstrup
#########################################
resource "null_resource" "ekm_boot_partner" {
  connection {
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "centos"
    host         = "${aws_instance.partner.private_ip}"
    type         = "ssh"
    user         = "centos"
    private_key  = "${file(var.private_key_path)}"
  }

  depends_on = ["aws_route53_record.ep","aws_route53_record.partner","aws_route53_record.aux"]

  provisioner "remote-exec" {
    inline = [
      "echo + sudo /opt/ekm/bin/ekm_boot_partner.sh -s partner -p ep -f",
      "sudo /opt/ekm/bin/ekm_boot_partner.sh -s partner -p ep -f",
      "echo + sleep 20",
      "sleep 20",
      "echo + sudo su - -c 'nohup service ekm start &'",
      "sudo su - -c 'nohup service ekm start &'",
      "echo + sleep 20",
      "sleep 20",
    ]
  }
}

resource "null_resource" "ekm_boot_ep" {
  connection {
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "centos"
    host         = "${aws_instance.ep.private_ip}"
    type         = "ssh"
    user         = "centos"
    private_key  = "${file(var.private_key_path)}"
  }

  depends_on = ["aws_route53_record.ep","aws_route53_record.partner","aws_route53_record.aux"]

  provisioner "remote-exec" {
    inline = [
      "echo + sudo /opt/ekm/bin/ekm_boot_ep.sh -s ep -p partner -w file:/etc/ekm/root.passwd -f",
      "sudo /opt/ekm/bin/ekm_boot_ep.sh -s ep -p partner -w file:/etc/ekm/root.passwd -f",
      "echo + sleep 20",
      "sleep 20",
      "echo + sudo su - -c 'nohup service ekm start &'",
      "sudo su - -c 'nohup service ekm start &'",
      "echo + sleep 20",
      "sleep 20",
    ]
  }
}


#########################################
# Restart UKC service
#########################################
resource "null_resource" "ekm_service_partner" {
  connection {
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "centos"
    host         = "${aws_instance.partner.private_ip}"
    type         = "ssh"
    user         = "centos"
    private_key  = "${file(var.private_key_path)}"
  }

  depends_on = ["null_resource.ekm_boot_ep","null_resource.ekm_boot_partner"]

  provisioner "remote-exec" {
    inline = [
      "echo + sudo su - -c 'nohup service ekm restart &'",
      "sudo su - -c 'nohup service ekm restart &'",
    ]
  }
}

resource "null_resource" "ekm_service_ep" {
  connection {
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "centos"
    host         = "${aws_instance.ep.private_ip}"
    type         = "ssh"
    user         = "centos"
    private_key  = "${file(var.private_key_path)}"
  }

  depends_on = ["null_resource.ekm_boot_ep","null_resource.ekm_boot_partner"]

  provisioner "remote-exec" {
    inline = [
      "echo + sudo su - -c 'nohup service ekm restart &'",
      "sudo su - -c 'nohup service ekm restart &'",
      "echo + sleep 20; sleep 20",
    ]
  }
}

#########################################
# Add AUX to EKM
#########################################
resource "null_resource" "ekm_add-aux" {
  depends_on = ["null_resource.ekm_service_ep","aws_route53_record.aux"]

  #------------------
  # AUX: bootstrup
  #------------------
  provisioner "remote-exec" {
    connection {
      bastion_host = "${aws_instance.casp.public_ip}"
      bastion_user = "centos"
      host         = "${aws_instance.aux.private_ip}"
      type         = "ssh"
      user         = "centos"
      private_key  = "${file(var.private_key_path)}"
    }

    inline = [
      "uname -a",
      "echo + sudo /opt/ekm/bin/ekm_boot_additional_server.sh -s aux",
      "sudo /opt/ekm/bin/ekm_boot_additional_server.sh -s aux",
      "echo + sleep 20; sleep 20",
      "echo + sudo su - -c 'nohup service ekm start &'",
      "sudo su - -c 'nohup service ekm start &'",
      "echo + sleep 20; sleep 20",
    ]
  }

  #------------------
  # EP: add aux
  #------------------
  provisioner "remote-exec" {
    connection {
      bastion_host = "${aws_instance.casp.public_ip}"
      bastion_user = "centos"
      host         = "${aws_instance.ep.private_ip}"
      type         = "ssh"
      user         = "centos"
      private_key  = "${file(var.private_key_path)}"
    }

    inline = [
      "uname -a",
      "echo + sudo ucl server create -a aux -w file:/etc/ekm/root.passwd",
      "echo Y | sudo ucl server create -a aux -w file:/etc/ekm/root.passwd",
    ]
  }

  #------------------
  # AUX: restart
  #------------------
  provisioner "remote-exec" {
    connection {
      bastion_host = "${aws_instance.casp.public_ip}"
      bastion_user = "centos"
      host         = "${aws_instance.aux.private_ip}"
      type         = "ssh"
      user         = "centos"
      private_key  = "${file(var.private_key_path)}"
    }

    inline = [
      "uname -a",
      "echo + sudo su - -c 'nohup service ekm restart &'",
      "sudo su - -c 'nohup service ekm restart &'",
      "echo + sleep 20",
      "sleep 20",
    ]
  }
}


#########################################
# UKC partitions creation
#########################################
resource "null_resource" "ekm_partitions_ep" {
  connection {
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "centos"
    host         = "${aws_instance.ep.private_ip}"
    type         = "ssh"
    user         = "centos"
    private_key  = "${file(var.private_key_path)}"
  }

  depends_on = ["null_resource.ekm_service_ep","null_resource.ekm_service_partner","null_resource.ekm_add-aux"]

  provisioner "remote-exec" {
    inline = [
      "echo + ucl server test",
      "ucl server test",
      "echo + sudo ucl partition create -p casp -w file:/etc/ekm/root.passwd -s file:/etc/ekm/caspso.passwd",
      "sudo ucl partition create -p casp -w file:/etc/ekm/root.passwd -s file:/etc/ekm/caspso.passwd",
      "echo + sudo ucl user reset-pwd -p casp -n user -w file:/etc/ekm/caspso.passwd -d file:/etc/ekm/caspuser.passwd",
      "sudo ucl user reset-pwd -p casp -n user -w file:/etc/ekm/caspso.passwd -d file:/etc/ekm/caspuser.passwd",
      "echo + sudo ucl system-settings set -k no-cert -v 1 -w file:/etc/ekm/root.passwd",
      "sudo ucl system-settings set -k no-cert -v 1 -w file:/etc/ekm/root.passwd",
    ]
  }
}

#########################################
# EKM - set offline backup
#########################################
resource "null_resource" "ekm_set_offline_backup_ep" {
  connection {
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "centos"
    host         = "${aws_instance.ep.private_ip}"
    type         = "ssh"
    user         = "centos"
    private_key  = "${file(var.private_key_path)}"
  }

  depends_on = ["null_resource.ekm_service_ep","null_resource.ekm_service_partner"]

  provisioner file {
    source      = "${var.local_path}casp_backup.pem"
    destination = "${var.path_backup_keys}casp_backup.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "echo + sudo /opt/ekm/bin/ekm_set_offline_backup_key.sh -k ${var.path_backup_keys}casp_backup.pem",
      "sudo /opt/ekm/bin/ekm_set_offline_backup_key.sh -k ${var.path_backup_keys}casp_backup.pem",
    ]
  }
}

resource "null_resource" "ekm_set_offline_backup_partner" {
  connection {
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "centos"
    host         = "${aws_instance.partner.private_ip}"
    type         = "ssh"
    user         = "centos"
    private_key  = "${file(var.private_key_path)}"
  }

  depends_on = ["null_resource.ekm_service_ep","null_resource.ekm_service_partner"]

  provisioner file {
    source      = "${var.local_path}casp_backup.pem"
    destination = "${var.path_backup_keys}casp_backup.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "echo + sudo /opt/ekm/bin/ekm_set_offline_backup_key.sh -k ${var.path_backup_keys}casp_backup.pem",
      "sudo /opt/ekm/bin/ekm_set_offline_backup_key.sh -k ${var.path_backup_keys}casp_backup.pem",
    ]
  }
}

resource "null_resource" "ekm_set_offline_backup_aux" {
  connection {
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "centos"
    host         = "${aws_instance.aux.private_ip}"
    type         = "ssh"
    user         = "centos"
    private_key  = "${file(var.private_key_path)}"
  }

  depends_on = ["null_resource.ekm_service_ep","null_resource.ekm_service_partner"]

  provisioner file {
    source      = "${var.local_path}casp_backup.pem"
    destination = "${var.path_backup_keys}casp_backup.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "echo + sudo /opt/ekm/bin/ekm_set_offline_backup_key.sh -k ${var.path_backup_keys}casp_backup.pem",
      "sudo /opt/ekm/bin/ekm_set_offline_backup_key.sh -k ${var.path_backup_keys}casp_backup.pem",
    ]
  }
}


#########################################
# CASP - createdinstance, prepare to be bastion
#########################################
resource "aws_instance" "casp" {
  connection {
    type = "ssh"
    user = "centos"
    private_key = "${file(var.private_key_path)}"
  }

  ami           = "${lookup(var.casp_amis, var.aws_region)}"
  instance_type = "t2.medium"

  key_name               = "${aws_key_pair.auth.id}"
  subnet_id              = "${aws_subnet.public.id}"
  vpc_security_group_ids = ["${aws_security_group.casp.id}"]

#  provisioner file {
#    source      = "${var.private_key_path}"
#    destination = "/home/centos/.ssh/id_rsa"
#  }
#
#  provisioner "remote-exec" {
#    inline = [
#      "chmod 600 /home/centos/.ssh/id_rsa",
#    ]
#  }

  tags = {
    Name = "${var.resource-group-name} CASP Server"
  }
}

#########################################
# CASP - install packages
#########################################
resource "null_resource" "casp_preconfig" {
  connection {
    type = "ssh"
    user = "centos"
    host = "${aws_instance.casp.public_ip}"
    private_key = "${file(var.private_key_path)}"
  }

  depends_on = ["aws_instance.casp"]

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl status casp",
      "sudo yum -y update",
      "sudo yum -y install yum install httpd mod_ssl",
      "sudo curl -sL https://rpm.nodesource.com/setup_10.x | sudo -E bash -",
      "sudo yum -y install nodejs",
      "sudo yum install wget",
      "sudo wget https://download.java.net/openjdk/jdk11/ri/openjdk-11+28_linux-x64_bin.tar.gz -O /tmp/openjdk-11+28_linux-x64_bin.tar.gz",
      "sudo tar -C /tmp/ -xvzf /tmp/openjdk-11+28_linux-x64_bin.tar.gz",
      "sudo mkdir /usr/java",
      "sudo mv /tmp/jdk-11 /usr/java",
      "sudo touch /etc/profile.d/java.sh",
      "echo 'export JAVA_HOME=/usr/java/jdk-11 export PATH=/usr/java/jdk-11/bin:$PATH' | sudo tee -a /etc/profile.d/java.sh",
      "cat /etc/profile.d/java.sh",
      "sudo chmod +x /etc/profile.d/java.sh",
      "/etc/profile.d/java.sh",
      "sudo java -version",
    ]
  }

  provisioner file {
    source      = "${var.local_path}${var.casp_rpm_version_name}"
    destination = "/home/centos/${var.casp_rpm_version_name}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo + sudo rpm -ivh /home/centos/${var.casp_rpm_version_name}",
      "sudo rpm -ivh /home/centos/${var.casp_rpm_version_name}",
    ]
  }
}

#########################################
# CASP - configure casp server
#########################################
resource "null_resource" "casp_config" {
  connection {
    type = "ssh"
    user = "centos"
    host = "${aws_instance.casp.public_ip}"
    private_key = "${file(var.private_key_path)}"
  }

  depends_on = ["aws_db_instance.caspdb", "aws_route53_record.caspdb", "null_resource.ekm_partitions_ep","null_resource.ekm_add-aux","null_resource.casp_preconfig"]

  provisioner "file" {
    destination = "/tmp/casp.conf"

    content = <<CASPCONF
# Database Settings (PostgreSQL) - Uncomment if using PostgreSQL
database.url=jdbc:postgresql://caspdb:5432/casp
database.user=postgres
database.password=${random_string.dbpasswd.result}
database.driver=org.postgresql.Driver
database.driverfile=/opt/casp/jdbc/postgresql-42.2.5.jar

# UKC Settings
ukc.url=https://ep/kmip
ukc.user=user@casp
ukc.password=${random_string.ukc-casp-user-passwd.result}

#Fire base
firebase.apikey="${var.firebase_apikey}"
# APNS Settings (for Apple push notification)
#apns.certificate.file=<APNS certificate>
#apns.certificate.password=<APNS certificate password>
#apns.production=<true if this is a production certificate>
CASPCONF
  }

#TODO: add info outputs
  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install postgresql",
      "PGPASSWORD=\"${random_string.dbpasswd.result}\" psql -h caspdb -U postgres -c 'CREATE DATABASE casp;'",
      "PGPASSWORD=\"${random_string.dbpasswd.result}\" psql -h caspdb -U postgres casp < /opt/casp/sql/casp-postgresql.sql",
      "sudo mv /tmp/casp.conf /etc/unbound/casp.conf",
      "sudo sed -e 's/<accesstoken>/${var.token-blockcypher-btc}/' -i /etc/unbound/btc.conf",
      "sudo sed -e 's/<accesstoken>/${var.token-blockcypher-btctest}/' -i /etc/unbound/btctest.conf",
      "sudo sed -e 's/disabled: true /disabled: false /' -i /opt/casp/providers/wallets/config/production.yaml",
      "sudo sed -e 's/token: '\\''#put your eth infura api-token here'\\''/token: ${var.token-infura-eth}/' -i /opt/casp/providers/wallets/config/production.yaml",
      "sudo sed -e 's/token: '\\''#put your ethtest-ropsten infura api-token here'\\''/token: ${var.token-infura-ethtest}/' -i /opt/casp/providers/wallets/config/production.yaml",
      "sudo sed -e 's/token: '\\''#put your BlockCypher token here'\\''/token: ${var.token-blockcypher-btc}/' -i /opt/casp/providers/wallets/config/production.yaml",
      "sudo sed -e 's/token: '\\''#put your BlockCypher token here'\\''/token: ${var.token-blockcypher-btctest}/' -i /opt/casp/providers/wallets/config/production.yaml",
      "sudo sed -e 's/level=\"off\"/level=\"debug\"/' -i /etc/unbound/log4j/casp.xml",

      "sleep 180",
      "sudo systemctl start casp.tomcat.service",
      "sudo systemctl start casp.wallets.service",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
      "sleep 30",
      "sudo su - -c 'nohup systemctl restart casp.tomcat.service &'",
      "sudo curl -k https://localhost/casp/api/v1.0/mng/status?withDetails=true",
    ]
  }
}

resource "aws_route53_record" "casp" {
  zone_id = "${aws_route53_zone.unbound.zone_id}"
  name    = "casp"
  type    = "A"
  ttl     = "5"
  records = ["${aws_instance.casp.private_ip}"]
}

resource "aws_instance" "ep" {
  connection {
    type = "ssh"
    user = "centos"
    private_key = "${file(var.private_key_path)}"
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "centos"
    bastion_private_key = "${file(var.private_key_path)}"
    host = "${aws_instance.ep.private_ip}"
  }

  ami           = "${lookup(var.ukc_amis, var.aws_region)}"
  instance_type = "t2.medium"

  key_name               = "${aws_key_pair.auth.id}"
  subnet_id              = "${aws_subnet.private1.id}"
  vpc_security_group_ids = ["${aws_security_group.ukc.id}"]

  depends_on = ["aws_instance.casp"]

  tags = {
    Name = "${var.resource-group-name} UKC EP"
  }

  provisioner file {
    source      = "${var.local_path}${var.ukc_rpm_version_name}"
    destination = "/home/centos/${var.ukc_rpm_version_name}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo + sudo rpm -ivh /home/centos/${var.ukc_rpm_version_name}",
      "sudo rpm -ivh /home/centos/${var.ukc_rpm_version_name}",
      "echo + Save UKC root, CASP so and user passwords",
      "sudo sh -c 'echo -n ${random_string.ukc-root-passwd.result} > /etc/ekm/root.passwd'",
      "sudo sh -c 'echo -n ${random_string.ukc-casp-so-passwd.result} > /etc/ekm/caspso.passwd'",
      "sudo sh -c 'echo -n ${random_string.ukc-casp-user-passwd.result} > /etc/ekm/caspuser.passwd'",
    ]
  }
}

resource "aws_route53_record" "ep" {
  zone_id = "${aws_route53_zone.unbound.zone_id}"
  name    = "ep"
  type    = "A"
  ttl     = "5"
  records = ["${aws_instance.ep.private_ip}"]
}

resource "aws_instance" "partner" {
  connection {
    type = "ssh"
    user = "centos"
    private_key = "${file(var.private_key_path)}"
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "centos"
    bastion_private_key = "${file(var.private_key_path)}"
    host = "${aws_instance.partner.private_ip}"
  }

  ami           = "${lookup(var.ukc_amis, var.aws_region)}"
  instance_type = "t2.small"

  key_name               = "${aws_key_pair.auth.id}"
  subnet_id              = "${aws_subnet.private1.id}"
  vpc_security_group_ids = ["${aws_security_group.ukc.id}"]

  tags = {
    Name = "${var.resource-group-name} UKC Partner"
  }

  depends_on = ["aws_instance.casp"]

  provisioner file {
    source      = "${var.local_path}${var.ukc_rpm_version_name}"
    destination = "/home/centos/${var.ukc_rpm_version_name}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo + sudo rpm -ivh /home/centos/${var.ukc_rpm_version_name}",
      "sudo rpm -ivh /home/centos/${var.ukc_rpm_version_name}",
    ]
  }
}

resource "aws_route53_record" "partner" {
  zone_id = "${aws_route53_zone.unbound.zone_id}"
  name    = "partner"
  type    = "A"
  ttl     = "5"
  records = ["${aws_instance.partner.private_ip}"]
}

resource "aws_instance" "aux" {
  connection {
    type = "ssh"
    user = "centos"
    private_key = "${file(var.private_key_path)}"
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "centos"
    bastion_private_key = "${file(var.private_key_path)}"
    host = "${aws_instance.aux.private_ip}"
  }

  ami           = "${lookup(var.ukc_amis, var.aws_region)}"
  instance_type = "t2.small"

  key_name               = "${aws_key_pair.auth.id}"
  subnet_id              = "${aws_subnet.private1.id}"
  vpc_security_group_ids = ["${aws_security_group.ukc.id}"]

  tags = {
    Name = "${var.resource-group-name} UKC Aux"
  }

  depends_on = ["aws_instance.casp"]

  provisioner file {
    source      = "${var.local_path}${var.ukc_rpm_version_name}"
    destination = "/home/centos/${var.ukc_rpm_version_name}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo + sudo rpm -ivh /home/centos/${var.ukc_rpm_version_name}",
      "sudo rpm -ivh /home/centos/${var.ukc_rpm_version_name}",
    ]
  }
}

resource "aws_route53_record" "aux" {
  zone_id = "${aws_route53_zone.unbound.zone_id}"
  name    = "aux"
  type    = "A"
  ttl     = "5"
  records = ["${aws_instance.aux.private_ip}"]
}
