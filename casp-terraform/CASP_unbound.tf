#
# unbound.tf -- Create stand-alone Unbound infrastructure from VPC
#

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.aws_region}"
}

data "aws_availability_zones" "available" {}

data "aws_ami" "centos" {
  owners      = ["679593333241"]
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_key_pair" "auth_ep" {
  key_name   = "${var.key_name_0}"
  public_key = "${file(var.ep_public_key_path)}"
}

resource "aws_key_pair" "auth_partner_aux" {
  key_name   = "${var.key_name_1}"
  public_key = "${file(var.partner_public_key_path)}"
}

resource "aws_vpc" "unbound" {
  cidr_block           = "10.138.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.resource-group-name}: VPC"
  }
}

locals {
  domain = "${var.resource-group-name}.unboundtech.local"
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
  cidr_block              = "10.138.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "${var.resource-group-name}: Public subnet 0"
  }
}

resource "aws_subnet" "private1" {
  vpc_id                  = "${aws_vpc.unbound.id}"
  cidr_block              = "10.138.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  depends_on              = ["aws_route53_zone.unbound"]

  tags = {
    Name = "${var.resource-group-name}: Private subnet 1"
  }
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

resource "aws_security_group" "word-casp" {
  name        = "WORD-CASP"
  description = "Security group beetwen word and CASP"
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.resource-group-name}: Security group beetwen word and CASP server"
  }
}

resource "aws_security_group" "casp-ukc" {
  name        = "CASP-UKC"
  description = "Security group beetwen CASP and EP, Partner, AUX"
  vpc_id      = "${aws_vpc.unbound.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.138.0.0/24"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.138.0.0/24"]
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

resource "aws_security_group" "ukc-ukc" {
  name        = "UKC-UKC"
  description = "Security group beetwen EP, Partner and AUX"
  vpc_id      = "${aws_vpc.unbound.id}"

  ingress {
    # test environment only: access from CASP
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.138.0.0/24"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.138.1.0/24"]
  }

  ingress {
    from_port   = 6603
    to_port     = 6603
    protocol    = "tcp"
    cidr_blocks = ["10.138.1.0/24"]
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

#########################################
# Install UKC
#########################################
resource "null_resource" "install_ukc_on_aux" {
  connection {
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "${var.os_user_0}"
    bastion_private_key = "${file(var.casp_private_key_path)}"
    host         = "${aws_instance.aux.private_ip}"
    type         = "ssh"
    user         = "${var.os_user_0}"
    private_key  = "${file(var.partner_private_key_path)}"
  }

  depends_on = [
    "null_resource.install_java_aux",
  ]

  provisioner file {
    source      = "${var.ukc_pac}"
    destination = "/home/${var.os_user_0}/ukc.rpm"
  }

  provisioner "remote-exec" {
    inline = [
      "echo + sudo rpm -i /home/${var.os_user_0}/ukc.rpm",
      "sudo rpm -i /home/${var.os_user_0}/ukc.rpm",
    ]
  }
}

resource "null_resource" "install_ukc_on_partner" {
  connection {
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "${var.os_user_0}"
    bastion_private_key = "${file(var.casp_private_key_path)}"
    host         = "${aws_instance.partner.private_ip}"
    type         = "ssh"
    user         = "${var.os_user_0}"
    private_key  = "${file(var.partner_private_key_path)}"
  }

  depends_on = [
    "null_resource.install_java_partner",
  ]

  provisioner file {
    source      = "${var.ukc_pac}"
    destination = "/home/${var.os_user_0}/ukc.rpm"
  }

  provisioner "remote-exec" {
    inline = [
      "echo + sudo rpm -i /home/${var.os_user_0}/ukc.rpm",
      "sudo rpm -i /home/${var.os_user_0}/ukc.rpm",
    ]
  }
}

resource "null_resource" "install_ukc_on_ep" {
  connection {
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "${var.os_user_0}"
    bastion_private_key = "${file(var.casp_private_key_path)}"
    host         = "${aws_instance.ep.private_ip}"
    type         = "ssh"
    user         = "${var.os_user_0}"
    private_key  = "${file(var.ep_private_key_path)}"
  }

  depends_on = [
    "null_resource.install_java_ep",
  ]

  provisioner file {
    source      = "${var.ukc_pac}"
    destination = "/home/${var.os_user_0}/ukc.rpm"
  }

  provisioner "remote-exec" {
    inline = [
      "echo + sudo rpm -i /home/${var.os_user_0}/ukc.rpm",
      "sudo rpm -i /home/${var.os_user_0}/ukc.rpm",
    ]
  }
}


#########################################
# Install Java
#########################################
resource "null_resource" "install_java_aux" {
  connection {
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "${var.os_user_0}"
    bastion_private_key = "${file(var.casp_private_key_path)}"
    host         = "${aws_instance.aux.private_ip}"
    type         = "ssh"
    user         = "${var.os_user_0}"
    private_key  = "${file(var.partner_private_key_path)}"
  }

  depends_on = [
    "aws_instance.ep",
    "aws_route53_record.ep",
    "aws_instance.aux",
    "aws_route53_record.aux",
  ]

  provisioner "remote-exec" {
    inline = [
      "echo + sudo yum -y install java",
      "sudo yum -y install java",
    ]
  }
}

resource "null_resource" "install_java_partner" {
  connection {
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "${var.os_user_0}"
    bastion_private_key = "${file(var.casp_private_key_path)}"
    host         = "${aws_instance.partner.private_ip}"
    type         = "ssh"
    user         = "${var.os_user_0}"
    private_key  = "${file(var.partner_private_key_path)}"
  }

  depends_on = [
    "aws_instance.ep",
    "aws_route53_record.ep",
    "aws_instance.partner",
    "aws_route53_record.partner",
  ]

  provisioner "remote-exec" {
    inline = [
      "echo + sudo yum -y install java",
      "sudo yum -y install java",
    ]
  }
}

resource "null_resource" "install_java_ep" {
  connection {
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "${var.os_user_0}"
    bastion_private_key = "${file(var.casp_private_key_path)}"
    host         = "${aws_instance.ep.private_ip}"
    type         = "ssh"
    user         = "${var.os_user_0}"
    private_key  = "${file(var.ep_private_key_path)}"
  }

  depends_on = [
    "aws_instance.ep",
    "aws_route53_record.ep",
  ]

  provisioner "remote-exec" {
    inline = [
      "echo + sudo yum -y install java",
      "sudo yum -y install java",
    ]
  }
}

#########################################
# EP
#########################################
resource "aws_instance" "ep" {
  ami           = data.aws_ami.centos.id
  instance_type = "${var.instance_type_ukc}"

  key_name               = "${aws_key_pair.auth_ep.id}"
  subnet_id              = "${aws_subnet.private1.id}"
  vpc_security_group_ids = ["${aws_security_group.casp-ukc.id}",
			    "${aws_security_group.ukc-ukc.id}"]

  tags = {
    Name = "${var.resource-group-name}: UKC EP"
  }
}

#########################################
# Copy ssh keys to bastion
# if "provide_ssh" defined
# $ terraform plan -var="provide_ssh=true"
#########################################
resource "null_resource" "copy_id_rsa_to_bastion" {
  connection {
    host         = "${aws_instance.casp.public_ip}"
    type         = "ssh"
    user         = "${var.os_user_0}"
    private_key  = "${file(var.casp_private_key_path)}"
  }

  depends_on = ["null_resource.casp_config"]

  count = "${var.provide_ssh ? 1 : 0}"

  provisioner file {
    source      = "${var.ep_private_key_path}"
    destination = "/home/${var.os_user_0}/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/${var.os_user_0}/.ssh/id_rsa",
    ]
  }

}

#########################################
# UKC bootstrup
#########################################
resource "null_resource" "ekm_boot_partner" {
  connection {
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "${var.os_user_0}"
    bastion_private_key = "${file(var.casp_private_key_path)}"
    host         = "${aws_instance.partner.private_ip}"
    type         = "ssh"
    user         = "${var.os_user_0}"
    private_key  = "${file(var.partner_private_key_path)}"
  }

  depends_on = [
    "null_resource.install_ukc_on_ep",
    "null_resource.install_ukc_on_partner",
  ]

  provisioner "remote-exec" {
    inline = [
      "echo + sudo /opt/ekm/bin/ekm_boot_partner.sh -s partner -p ep -f",
      "sudo /opt/ekm/bin/ekm_boot_partner.sh -s partner -p ep -f",
      "echo + sleep 20",
      "sleep 20",
      "echo + sudo su - -c 'nohup service ekm start &'",
      "sudo su - -c 'nohup service ekm start &'",
      "echo \"+ ps -ef | grep tomcat\"",
      "ps -ef | grep tomcat",
      "echo + sleep 20",
      "sleep 20",
      "echo \"+ ps -ef | grep tomcat\"",
      "ps -ef | grep tomcat",
    ]
  }
}

resource "null_resource" "ekm_boot_ep" {
  connection {
    bastion_host = "${aws_instance.casp.public_ip}"
    bastion_user = "${var.os_user_0}"
    bastion_private_key = "${file(var.casp_private_key_path)}"
    host         = "${aws_instance.ep.private_ip}"
    type         = "ssh"
    user         = "${var.os_user_0}"
    private_key  = "${file(var.ep_private_key_path)}"
  }

  depends_on = [
    "null_resource.install_ukc_on_ep",
    "null_resource.install_ukc_on_partner",
  ]

  provisioner "remote-exec" {
    inline = [
      "echo + sudo /opt/ekm/bin/ekm_boot_ep.sh -s ep -p partner -w ${var.password1} -f",
      "sudo /opt/ekm/bin/ekm_boot_ep.sh -s ep -p partner -w ${var.password1} -f",
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
    bastion_host 	= "${aws_instance.casp.public_ip}"
    bastion_user 	= "${var.os_user_0}"
    bastion_private_key = "${file(var.casp_private_key_path)}"
    host         	= "${aws_instance.partner.private_ip}"
    type         	= "ssh"
    user         	= "${var.os_user_0}"
    private_key  	= "${file(var.partner_private_key_path)}"
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
    bastion_host 	= "${aws_instance.casp.public_ip}"
    bastion_user 	= "${var.os_user_0}"
    bastion_private_key = "${file(var.casp_private_key_path)}"
    host                = "${aws_instance.ep.private_ip}"
    type                = "ssh"
    user                = "${var.os_user_0}"
    private_key         = "${file(var.ep_private_key_path)}"
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
  depends_on = [
    "null_resource.ekm_service_ep",
    "aws_route53_record.aux",
    "null_resource.install_ukc_on_aux",
  ]

  #------------------
  # AUX: bootstrup
  #------------------
  provisioner "remote-exec" {
    connection {
      bastion_host 	= "${aws_instance.casp.public_ip}"
      bastion_user 	= "${var.os_user_0}"
      bastion_private_key = "${file(var.casp_private_key_path)}"
      host         	= "${aws_instance.aux.private_ip}"
      type         	= "ssh"
      user         	= "${var.os_user_0}"
      private_key  	= "${file(var.partner_private_key_path)}"
    }

    inline = [
      "uname -a",
      "echo + sudo /opt/ekm/bin/ekm_boot_additional_server.sh -s aux",
      "sudo /opt/ekm/bin/ekm_boot_additional_server.sh -s aux",
      "echo + sleep 20; sleep 20",
      "echo + sudo su - -c 'nohup service ekm start &'",
      "sudo su - -c 'nohup service ekm start &'",
      "echo + sleep 30; sleep 30",
    ]
  }

  #------------------
  # EP: add aux
  #------------------
  provisioner "remote-exec" {
    connection {
      bastion_host 	= "${aws_instance.casp.public_ip}"
      bastion_user 	= "${var.os_user_0}"
      bastion_private_key = "${file(var.casp_private_key_path)}"
      host              = "${aws_instance.ep.private_ip}"
      type              = "ssh"
      user              = "${var.os_user_0}"
      private_key       = "${file(var.ep_private_key_path)}"
    }

    inline = [
      "uname -a",
      "echo + sudo ucl server create -a aux -w ${var.password1}",
      "yes Y | sudo ucl server create -a aux -w ${var.password1}",
    ]
  }

  #------------------
  # AUX: restart
  #------------------
  provisioner "remote-exec" {
    connection {
      bastion_host 	= "${aws_instance.casp.public_ip}"
      bastion_user 	= "${var.os_user_0}"
      bastion_private_key = "${file(var.casp_private_key_path)}"
      host         	= "${aws_instance.aux.private_ip}"
      type         	= "ssh"
      user         	= "${var.os_user_0}"
      private_key  	= "${file(var.partner_private_key_path)}"
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
    bastion_host 	= "${aws_instance.casp.public_ip}"
    bastion_user 	= "${var.os_user_0}"
    bastion_private_key = "${file(var.casp_private_key_path)}"
    host                = "${aws_instance.ep.private_ip}"
    type                = "ssh"
    user                = "${var.os_user_0}"
    private_key         = "${file(var.ep_private_key_path)}"
  }

  depends_on = ["null_resource.ekm_service_ep","null_resource.ekm_service_partner","null_resource.ekm_add-aux"]

  provisioner "remote-exec" {
    inline = [
      "echo + ucl server test",
      "ucl server test",
      "echo + sudo ucl partition create -p partition1 -w ${var.password1} -s ${var.password1}",
      "sudo ucl partition create -p partition1 -w ${var.password1} -s ${var.password1}",
      "echo + sudo ucl user reset-pwd -p partition1 -n user -w ${var.password1} -d ${var.password1}",
      "sudo ucl user reset-pwd -p partition1 -n user -w ${var.password1} -d ${var.password1}",
      "echo + sudo ucl system-settings set -k no-cert -v 1 -w ${var.password1}",
      "sudo ucl system-settings set -k no-cert -v 1 -w ${var.password1}",
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
  ami           = data.aws_ami.centos.id
  instance_type = "${var.instance_type_ukc}"

  key_name               = "${aws_key_pair.auth_partner_aux.id}"
  subnet_id              = "${aws_subnet.private1.id}"
  vpc_security_group_ids = ["${aws_security_group.ukc-ukc.id}"]

  tags = {
    Name = "${var.resource-group-name}: Partner UKC"
  }

  depends_on = ["aws_instance.ep"]
}

resource "aws_route53_record" "partner" {
  zone_id = "${aws_route53_zone.unbound.zone_id}"
  name    = "partner"
  type    = "A"
  ttl     = "5"
  records = ["${aws_instance.partner.private_ip}"]
}

resource "aws_instance" "aux" {
  ami           = data.aws_ami.centos.id
  instance_type = "${var.instance_type_ukc}"

  key_name               = "${aws_key_pair.auth_partner_aux.id}"
  subnet_id              = "${aws_subnet.private1.id}"
  vpc_security_group_ids = ["${aws_security_group.ukc-ukc.id}"]

  tags = {
    Name = "${var.resource-group-name}: Aux UKC"
  }

  depends_on = ["aws_instance.ep"]
}

resource "aws_route53_record" "aux" {
  zone_id = "${aws_route53_zone.unbound.zone_id}"
  name    = "aux"
  type    = "A"
  ttl     = "5"
  records = ["${aws_instance.aux.private_ip}"]
}

#########################################################
# CASP section start here
#########################################################
resource "aws_key_pair" "auth_casp" {
  key_name   = "${var.key_name_3}"
  public_key = "${file(var.casp_public_key_path)}"
}

resource "aws_subnet" "private2" {
  vpc_id                  = "${aws_vpc.unbound.id}"
  cidr_block              = "10.138.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"
  depends_on              = ["aws_route53_zone.unbound"]

  tags = {
    Name = "${var.resource-group-name} unbound-private2"
  }
}

resource "aws_db_subnet_group" "caspdb" {
  name        = "unbound-dbprivate_${lower(var.resource-group-name)}"
  description = "Subnets for database"
  subnet_ids  = ["${aws_subnet.private1.id}", "${aws_subnet.private2.id}"]
}

resource "aws_security_group" "caspdb" {
  name        = "CASP Database"
  description = "Default Postgres access from CASP server only"
  vpc_id      = " ${aws_vpc.unbound.id}"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.138.0.0/24"]
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
  name = "CASP"
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

resource "aws_db_instance" "caspdb" {
  engine                  = "postgres"
  allocated_storage       = 20
  backup_retention_period = 1
  instance_class          = "db.${var.instance_type_casp}"
  apply_immediately       = true
  db_subnet_group_name    = "${aws_db_subnet_group.caspdb.id}"
  multi_az                = false
  username                = "postgres"
  password                = "${var.password1}"
  storage_encrypted       = true
  storage_type            = "standard"
  vpc_security_group_ids  = ["${aws_security_group.caspdb.id}"]
  skip_final_snapshot     = true
  tags = {
    Name = "${var.resource-group-name} CASP Database"
  }
}

resource "aws_route53_record" "caspdb" {
  zone_id = "${aws_route53_zone.unbound.zone_id}"
  name = "caspdb"
  type = "CNAME"
  ttl  = "5"
  records = ["${aws_db_instance.caspdb.address}"]
}

#####################################################################
# CASP - createdinstance, prepare to CASP  to become bastion
#####################################################################
resource "aws_instance" "casp" {
  depends_on = ["aws_key_pair.auth_casp"]

  ami                    = data.aws_ami.centos.id
  instance_type          = "${var.instance_type_casp}"
  key_name               = "${aws_key_pair.auth_casp.id}"
  subnet_id              = "${aws_subnet.public.id}"
  vpc_security_group_ids = ["${aws_security_group.casp.id}"]

  tags = {
    Name = "${var.resource-group-name}: CASP Server / Bastion"
  }
}

#########################################
# CASP - install packages
#########################################
resource "null_resource" "casp_preconfig" {
  connection {
    type        = "ssh"
    user        = "centos"
    host        = "${aws_instance.casp.public_ip}"
    private_key = "${file(var.casp_private_key_path)}"
  }

  depends_on = ["aws_instance.casp"]

  provisioner "remote-exec" {
    inline = [
      "echo + sudo hostnamectl status casp",
      "sudo hostnamectl status casp",
      "echo + sudo yum -y update",
      "sudo yum -y update",
      "echo + sudo yum -y install yum install httpd mod_ssl java",
      "sudo yum -y install yum install httpd mod_ssl java",
      "echo + sudo curl -sL https://rpm.nodesource.com/setup_10.x",
      "echo + sudo -E bash setup_10.x",
      "sudo curl -sL https://rpm.nodesource.com/setup_10.x | sudo -E bash -",
      "echo + sudo yum -y install nodejs",
      "sudo yum -y install nodejs",
    ]
  }

  provisioner file {
    source      = "${var.casp_pac}"
    destination = "/home/${var.os_user_0}/casp.rpm"
  }

  provisioner "remote-exec" {
    inline = [
      "echo + sudo rpm -ivh /home/${var.os_user_0}/casp.rpm",
      "sudo rpm -ivh /home/${var.os_user_0}/casp.rpm",
    ]
  }
}

#########################################
# CASP - configure casp server
#########################################
resource "null_resource" "casp_config" {
  connection {
    type        = "ssh"
    user        = "centos"
    host        = "${aws_instance.casp.public_ip}"
    private_key = "${file(var.casp_private_key_path)}"
  }
  depends_on = ["aws_db_instance.caspdb", "aws_route53_record.caspdb", "null_resource.ekm_partitions_ep","null_resource.ekm_add-aux","null_resource.casp_preconfig"]

  provisioner "remote-exec" {
    inline = [
      "echo + fill /tmp/casp.conf",
    ]
  }

  provisioner "file" {
    destination = "/tmp/casp.conf"
    content = <<CASPCONF
# Database Settings (PostgreSQL) - Uncomment if using PostgreSQL
database.url=jdbc:postgresql://caspdb:5432/casp
database.user=postgres
database.password=${var.password1}
database.driver=org.postgresql.Driver
database.driverfile=/opt/casp/jdbc/postgresql-42.2.5.jar
# UKC Settings
ukc.url=https://ep/kmip
ukc.user=user@casp
ukc.password=${var.password1}
#Fire base
firebase.apikey=${var.firebase_apikey}
# APNS Settings (for Apple push notification) apns.certificate.file=<APNS certificate> apns.certificate.password=<APNS certificate password> apns.production=<true if this is a production
#certificate>
CASPCONF
  }

  provisioner "remote-exec" {
    inline = [
      "echo + sudo yum -y install postgresql",
      "sudo yum -y install postgresql",
      "PGPASSWORD=\"${var.password1}\" psql -h caspdb -U postgres -c 'CREATE DATABASE casp;'",
      "PGPASSWORD=\"${var.password1}\" psql -h caspdb -U postgres casp < /opt/casp/sql/casp-postgresql.sql",
      "echo + sudo mv /tmp/casp.conf /etc/unbound/casp.conf",
      "sudo mv /tmp/casp.conf /etc/unbound/casp.conf",
      "echo + edit /etc/unbound/btc.conf",
      "sudo sed -e 's/<accesstoken>/${var.token-blockcypher-btc}/' -i /etc/unbound/btc.conf",
      "echo + edit /etc/unbound/btctest.conf",
      "sudo sed -e 's/<accesstoken>/${var.token-blockcypher-btctest}/' -i /etc/unbound/btctest.conf",
      "echo + edit /etc/unbound/btctest.conf",
      "sudo sed -e 's/disabled: true /disabled: false /' -i /opt/casp/providers/wallets/config/production.yaml",
      "sudo sed -e 's/token: '\\''#put your eth infura api-token here'\\''/token: ${var.token-infura-eth}/' -i /opt/casp/providers/wallets/config/production.yaml",
      "sudo sed -e 's/token: '\\''#put your ethtest-ropsten infura api-token here'\\''/token: ${var.token-infura-ethtest}/' -i /opt/casp/providers/wallets/config/production.yaml",
      "sudo sed -e 's/token: '\\''#put your BlockCypher token here'\\''/token: ${var.token-blockcypher-btc}/' -i /opt/casp/providers/wallets/config/production.yaml",
      "sudo sed -e 's/token: '\\''#put your BlockCypher token here'\\''/token: ${var.token-blockcypher-btctest}/' -i /opt/casp/providers/wallets/config/production.yaml",
      "echo + edit /etc/unbound/log4j/casp.xml",
      "sudo sed -e 's/level=\"off\"/level=\"debug\"/' -i /etc/unbound/log4j/casp.xml",
      "echo + sleep 180",
      "sleep 180",
      "echo + sudo systemctl start casp.tomcat.service",
      "sudo systemctl start casp.tomcat.service",
      "echo + sudo systemctl start casp.wallets.service",
      "sudo systemctl start casp.wallets.service",
      "echo + sudo systemctl start httpd",
      "sudo systemctl start httpd",
      "echo + sudo systemctl enable httpd",
      "sudo systemctl enable httpd",
      "echo + sleep 30",
      "sleep 30",
      "echo + nohup systemctl restart casp.tomcat.service",
      "sudo su - -c 'nohup systemctl restart casp.tomcat.service &'",
      "echo + sudo /usr/bin/casp_setup_ukc --ukc-url https://ep --ukc-user user@partition1 --ukc-password ...",
      "sudo /usr/bin/casp_setup_ukc --ukc-url https://ep --ukc-user user@partition1 --ukc-password ${var.password1}",
      "echo + sudo /usr/bin/casp_setup_db --db-url jdbc:postgresql://caspdb:5432/casp --db-user postgres --db-password ...",
      "sudo /usr/bin/casp_setup_db --db-url jdbc:postgresql://caspdb:5432/casp --db-user postgres --db-password ${var.password1} --db-driver org.postgresql.Driver --db-driver-path /opt/casp/jdbc/postgresql-42.2.5.jar",
      "echo +  curl -k https://localhost/casp/api/v1.0/mng/status?withDetails=true",
      "curl -k https://localhost/casp/api/v1.0/mng/status?withDetails=true",
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

#########################################
# EKM - set offline backup
#########################################
resource "null_resource" "ekm_set_offline_backup_ep" {
  connection {
    bastion_host        = "${aws_instance.casp.public_ip}"
    bastion_user        = "${var.os_user_0}"
    bastion_private_key = "${file(var.casp_private_key_path)}"
    host                = "${aws_instance.ep.private_ip}"
    type                = "ssh"
    user                = "${var.os_user_0}"
    private_key         = "${file(var.ep_private_key_path)}"
  }

  depends_on = ["null_resource.ekm_partitions_ep","null_resource.ekm_add-aux","null_resource.casp_config"]

  provisioner file {
    source      = "${var.casp_backup_key_path}"
    destination = "/home/${var.os_user_0}/casp_backup.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "echo + sudo /opt/ekm/bin/ekm_set_offline_backup_key.sh -k /home/${var.os_user_0}/casp_backup.pem",
      "sudo /opt/ekm/bin/ekm_set_offline_backup_key.sh -k /home/${var.os_user_0}/casp_backup.pem",
    ]
  }
}

resource "null_resource" "ekm_set_offline_backup_partner" {
  connection {
    bastion_host        = "${aws_instance.casp.public_ip}"
    bastion_user        = "${var.os_user_0}"
    bastion_private_key = "${file(var.casp_private_key_path)}"
    host                = "${aws_instance.partner.private_ip}"
    type                = "ssh"
    user                = "${var.os_user_0}"
    private_key         = "${file(var.partner_private_key_path)}"
  }

  depends_on = ["null_resource.ekm_partitions_ep","null_resource.ekm_add-aux","null_resource.casp_config"]

  provisioner file {
    source      = "${var.casp_backup_key_path}"
    destination = "/home/${var.os_user_0}/casp_backup.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "echo + sudo /opt/ekm/bin/ekm_set_offline_backup_key.sh -k /home/${var.os_user_0}/casp_backup.pem",
      "sudo /opt/ekm/bin/ekm_set_offline_backup_key.sh -k /home/${var.os_user_0}/casp_backup.pem",
    ]
  }
}
