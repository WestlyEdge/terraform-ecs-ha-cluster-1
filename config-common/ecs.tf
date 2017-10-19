
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
  health_check_path     = "${var.health_check_path}"
}

module "ecs_debug_mode" {
  source = "git@github.com:WestlyEdge/terraform-modules//modules//ecs_debug_mode"

  cluster_name              = "${var.cluster_name}"
  security_group_id         = "${module.ecs.ecs_instance_security_group_id}"
  vpc_internet_gateway_id   = "${module.ecs.vpc_internet_gateway_id}"
}

resource "aws_key_pair" "ecs" {
  key_name   = "${var.aws_key_pair_name}"
  public_key = "${var.aws_key_pair_public_key}"
}

variable "environment" {}
variable "cluster_name" {}
variable "vpc_cidr" {}
variable "max_size" {}
variable "min_size" {}
variable "desired_capacity" {}
variable "instance_type" {}
variable "ecs_aws_ami" {}
variable "aws_key_pair_name" {}
variable "aws_key_pair_public_key" {}
variable "health_check_path" {}

variable "private_subnet_cidrs" {
  type = "list"
}

variable "public_subnet_cidrs" {
  type = "list"
}

variable "availability_zones" {
  type = "list"
}

output "cluster_name" {
  value = "${var.cluster_name}"
}

output "ecs_instance_security_group_id" {
  value = "${module.ecs.ecs_instance_security_group_id}"
}

output "vpc_internet_gateway_id" {
  value = "${module.ecs.vpc_internet_gateway_id}"
}