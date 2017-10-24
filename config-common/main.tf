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
  key_pair_name         = "${var.key_pair_name}"
  key_pair_public_key   = "${var.key_pair_public_key}"
  instance_type         = "${var.instance_type}"
  ecs_aws_ami           = "${var.ecs_aws_ami}"
  health_check_path     = "${var.health_check_path}"
}

module "consul" {
  source = "git@github.com:WestlyEdge/terraform-modules//modules//ecs_services//consul"

  environment                     = "${var.environment}"
  cluster_name                    = "${var.cluster_name}"
  desired_capacity                = "${var.desired_capacity}"
  ecs_cluster_arn                 = "${module.ecs.ecs_cluster_arn}"
  vpc_id                          = "${module.ecs.network_vpc_id}"
  ecs_instance_security_group_id  = "${module.ecs.ecs_instance_security_group_id}"
  ecs_instance_role_name          = "${module.ecs.ecs_instance_role_name}"
  public_subnet_ids               = "${module.ecs.network_public_subnet_ids}"
}

module "vault" {
  source = "git@github.com:WestlyEdge/terraform-modules//modules//ecs_services//vault"

  environment                     = "${var.environment}"
  cluster_name                    = "${var.cluster_name}"
  desired_capacity                = "${var.desired_capacity}"
  ecs_cluster_arn                 = "${module.ecs.ecs_cluster_arn}"
  vpc_id                          = "${module.ecs.network_vpc_id}"
  ecs_instance_security_group_id  = "${module.ecs.ecs_instance_security_group_id}"
  ecs_instance_role_name          = "${module.ecs.ecs_instance_role_name}"
  public_subnet_ids               = "${module.ecs.network_public_subnet_ids}"
}