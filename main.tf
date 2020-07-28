terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = "~> 2.0"
  region = "eu-west-2"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"

  name = "${var.prefix}-f5-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-2a"]

  # 10.0.0.0/24 = f5-1 Mgmt

  # 10.0.1.0/24 = f5-1 Public

  # 10.0.2.0/24 = f5-1 Internal
  
  public_subnets  = ["10.0.0.0/24","10.0.1.0/24"]
  private_subnets = ["10.0.2.0/24"]

  # Need the NAT gateway to allow BIG-IP outbound to download onboarding artifacts.
  enable_nat_gateway     = true
  one_nat_gateway_per_az = true

  tags = {
    Name = "${var.prefix}-f5"
  }
}

resource "aws_network_interface" "f5-mgmt" {
  subnet_id   = module.vpc.public_subnets[0]
  private_ips = ["10.0.0.10"]
  security_groups = [ aws_security_group.f5_ext.id ]

  tags = {
    Name = "${var.prefix}-f5-mgmt"
  }
}

resource "aws_eip" "f5-mgmt" {
  vpc                       = true
  network_interface         = aws_network_interface.f5-mgmt.id
  associate_with_private_ip = "10.0.0.10"
  tags = {
    Name = "${var.prefix}-f5"
  }
}

resource "aws_network_interface" "f5-public" {
  subnet_id   = module.vpc.public_subnets[1]
  private_ips = [ "10.0.1.10" ]
  security_groups = [ aws_security_group.f5_ext.id ]

  tags = {
    Name = "${var.prefix}-f5-public"
  }
}

resource "aws_eip" "f5-public" {
  vpc                       = true
  network_interface         = aws_network_interface.f5-public.id
  associate_with_private_ip = "10.0.1.10"

  tags = {
    Name = "${var.prefix}-f5"
  }
}

data "aws_ami" "f5_ami" {
  most_recent = true
  owners  = ["679593333241"]

  filter {
      name = "name"
      values = [var.f5_ami_search_name]
  }
}

resource "random_string" "password" {
  length = 10
  special = false
}

data "template_file" "f5_init" {
  template = file("f5_onboard.tmpl")

  vars = {
    password    = random_string.password.result
    doVersion   = "latest"
    as3Version  = "latest" 
    tsVersion   = "latest"
    cfVersion   = "latest"
    fastVersion = "latest"
    libs_dir    = var.libs_dir
    onboard_log = var.onboard_log
    projectPrefix =  var.prefix
  }
}
resource "aws_instance" "Bigip-1" {
  ami           = data.aws_ami.f5_ami.id
 # ami           = "ami-0fe284d68b7936ab6"
  instance_type = "m5.xlarge"
  key_name      =  var.ssh_key_name
  user_data = data.template_file.f5_init.rendered

  network_interface {
      network_interface_id = aws_network_interface.f5-mgmt.id
      device_index         = 0
  }
  network_interface {
      network_interface_id = aws_network_interface.f5-public.id
      device_index         = 1
  }
  
  provisioner "local-exec" {
    command = "while [[ \"$(curl -skiu ${var.username}:${random_string.password.result} https://${self.public_ip}:${var.port}/mgmt/shared/appsvcs/declare | grep -Eoh \"^HTTP/1.1 204\")\" != \"HTTP/1.1 204\" ]]; do sleep 5; done"
  }
  
  tags = {
    Name = "${var.prefix}-f5"
    UK-SE = var.uk_se_name
  }
}

resource "aws_security_group" "f5_ext" {
  name   = "${var.prefix}-f5_ext"
  vpc_id = module.vpc.vpc_id

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

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
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
    Name = "${var.prefix}-f5"
  }
}

resource "aws_security_group" "f5_internal" {
  name   = "${var.prefix}-f5_internal"
  vpc_id = module.vpc.vpc_id

    ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.prefix}-f5"
  }
}

output "f5_user" {
  value = var.username
}

output "f5_password" {
  value = random_string.password.result
}

output "f5_ui" {
  value = "https://${aws_eip.f5-mgmt.public_ip}"
}