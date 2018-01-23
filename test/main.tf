data "aws_region" "current" {
  current = true
}

locals {
  azs = ["${data.aws_region.current.name}${var.az}"]
}

module "network" {
  source = "terraform-aws-modules/vpc/aws"
  version = ">= 1.11.0"

  azs = ["${local.azs}"]
  cidr = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support = true
  enable_nat_gateway = true
  name = "devsecops-example-mgmt"
  public_subnets = ["${var.public_subnet_cidr}"]
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*ubuntu-xenial-16.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["099720109477"] # Canonical
}

module "log_forwarding" {
  source = ".."

  vpc_id = "${module.network.vpc_id}"
  public_subnets = "${module.network.public_subnets}"
  private_subnets = "${module.network.private_subnets}"
  ami_id = "${data.aws_ami.ubuntu.id}"
  azs = ["${local.azs}"]
}
