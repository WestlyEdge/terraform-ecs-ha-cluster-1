vpc_cidr = "10.10.0.0/16"

environment = "sandbox"

cluster_name = "ecs-ha-cluster-1"

public_subnet_cidrs = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]

private_subnet_cidrs = ["10.10.50.0/24", "10.10.51.0/24", "10.10.52.0/24"]

availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

max_size = 3

min_size = 3

desired_capacity = 3

instance_type = "t2.micro"

ecs_aws_ami = "ami-04351e12"
