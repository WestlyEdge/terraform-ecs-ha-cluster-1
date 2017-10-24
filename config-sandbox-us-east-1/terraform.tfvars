vpc_cidr = "10.10.0.0/16"

environment = "sandbox"

cluster_name = "ecs-ha-cluster-1"

public_subnet_cidrs = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]

private_subnet_cidrs = ["10.10.50.0/24", "10.10.51.0/24", "10.10.52.0/24"]

availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

max_size = 3

min_size = 3

desired_capacity = 3

instance_type = "m4.large"

ecs_aws_ami = "ami-9eb4b1e5"

health_check_path = "/v1/catalog/nodes"

key_pair_name = "sandbox-ecs-ha-cluster-1-kp"

key_pair_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyezSWhgmnG+FOqORDJUBOG5s9c1farcXK1+Mi5oUwqjd+ysw8YyVozmN0CZaI7dwUiWQRDRYfwFSjcXDsXVyQuEo34IWCmxVeiT/5gQPQTdeoP2umK0T+CSyPQ3SfipAgsGchYTeKf3yKijIw5lQldBALDiZQhJkRPBSPMf5dcLnc0vTUPEYoWjEWDS6Muq4eZqRK5KOSM7QI1WF/PtlGTVeukG6z3nFQ/PTbHz/hI7C3peAsa4OM1z7U9dywV9M3QwXUvj3Ff1qSwmNB9nfzLWjHMXJ22oj7XFVFl/L6QLl7yszNEinY2DfdarZF8bqfTJyTu5grm38IuzCjworr wesedge@Wess-MacBook-Pro-4.local"

