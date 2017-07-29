provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {}
}

module "ecs" {
  source = "git@github.com:WestlyEdge/terraform-modules//modules//ecs"

  environment           = "${var.environment}"
  cluster_name          = "${var.cluster_name}"
  cloudwatch_prefix     = "${var.cluster_name}"
  vpc_cidr              = "${var.vpc_cidr}"
  public_subnet_cidrs   = "${var.public_subnet_cidrs}"
  private_subnet_cidrs  = "${var.private_subnet_cidrs}"
  availability_zones    = "${var.availability_zones}"
  max_size              = "${var.max_size}"
  min_size              = "${var.min_size}"
  desired_capacity      = "${var.desired_capacity}"
  key_name              = "${aws_key_pair.ecs.key_name}"
  instance_type         = "${var.instance_type}"
  ecs_aws_ami           = "${var.ecs_aws_ami}"
}

resource "aws_key_pair" "ecs" {
  key_name   = "${var.environment}-${var.cluster_name}-kp"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyezSWhgmnG+FOqORDJUBOG5s9c1farcXK1+Mi5oUwqjd+ysw8YyVozmN0CZaI7dwUiWQRDRYfwFSjcXDsXVyQuEo34IWCmxVeiT/5gQPQTdeoP2umK0T+CSyPQ3SfipAgsGchYTeKf3yKijIw5lQldBALDiZQhJkRPBSPMf5dcLnc0vTUPEYoWjEWDS6Muq4eZqRK5KOSM7QI1WF/PtlGTVeukG6z3nFQ/PTbHz/hI7C3peAsa4OM1z7U9dywV9M3QwXUvj3Ff1qSwmNB9nfzLWjHMXJ22oj7XFVFl/L6QLl7yszNEinY2DfdarZF8bqfTJyTu5grm38IuzCjworr wesedge@Wess-MacBook-Pro-4.local"
}

variable "environment" {}
variable "cluster_name" {}
variable "vpc_cidr" {}
variable "max_size" {}
variable "min_size" {}
variable "desired_capacity" {}
variable "instance_type" {}
variable "ecs_aws_ami" {}

variable "private_subnet_cidrs" {
  type = "list"
}

variable "public_subnet_cidrs" {
  type = "list"
}

variable "availability_zones" {
  type = "list"
}

output "default_alb_target_group" {
  value = "${module.ecs.default_alb_target_group}"
}