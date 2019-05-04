
terraform {
  required_version = ">= 0.11.8"
}

provider "aws" {
  version = ">= 2.6.0"
  region  = "${var.region}"
}

provider "random" {
  version = "= 1.3.1"
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = "${var.cluster-name}"

   worker_groups_launch_template = [
    {
      instance_type                            = "t3.medium"
      additional_userdata                      = "echo foo bar"
      subnets                                  = "${join(",", module.vpc.private_subnets)}"
      additional_security_group_ids            = "${aws_security_group.worker_group_mgmt_one.id},${aws_security_group.worker_group_mgmt_two.id}"
      asg_desired_capacity                     = "2"
      asg_min_size                             = "2"
      asg_max_size                             = "3"
      root_encrypted                           = ""
    },
  ]

  
  tags = {
    Environment = "${var.tag}"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "${var.cluster-name}-worker_group_mgmt_one"
  description = "SG to be applied to all *nix machines in ${var.cluster-name}"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
}

resource "aws_security_group" "worker_group_mgmt_two" {
  name_prefix = "${var.cluster-name}-worker_group_mgmt_two"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "192.168.0.0/16",
    ]
  }
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "${var.cluster-name}-all_worker_management"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
}

module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "1.60.0"
  name               = "${var.cluster-name}-vpc"
  cidr               = "10.0.0.0/16"
  azs                = ["${data.aws_availability_zones.available.names[0]}", "${data.aws_availability_zones.available.names[1]}", "${data.aws_availability_zones.available.names[2]}"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
  tags               = "${merge(local.tags, map("kubernetes.io/cluster/${local.cluster_name}", "shared", "kubernetes.io/role/internal-elb", "", "kubernetes.io/role/elb", ""))}"
  public_subnet_tags               = "${merge(map("kubernetes.io/role/elb", "1"))}"
  private_subnet_tags               = "${merge(map("kubernetes.io/role/internal-elb", "1"))}"
}

module "eks" {
  source                               = "terraform-aws-modules/eks/aws"
  cluster_name                         = "${local.cluster_name}"
  subnets                              = ["${module.vpc.private_subnets}"]
  tags                                 = "${local.tags}"
  vpc_id                               = "${module.vpc.vpc_id}"
  worker_groups_launch_template        = "${local.worker_groups_launch_template}"
  worker_group_launch_template_count   = "1"
  worker_group_count   = "0"
  worker_additional_security_group_ids = ["${aws_security_group.all_worker_mgmt.id}"]
}