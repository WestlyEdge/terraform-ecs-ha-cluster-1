variable "environment" {}
variable "cluster_name" {}
variable "vpc_cidr" {}
variable "max_size" {}
variable "min_size" {}
variable "desired_capacity" {}
variable "instance_type" {}
variable "ecs_aws_ami" {}
variable "key_pair_name" {}
variable "key_pair_public_key" {}
variable "health_check_path" {}
variable "private_subnet_cidrs" { type = "list" }
variable "public_subnet_cidrs" { type = "list" }
variable "availability_zones" { type = "list" }
