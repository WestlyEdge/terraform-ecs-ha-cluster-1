# terraform-ecs-ha-cluster-1

Apply this terraform project to create a self contained, highly available, production-ready ECS host cluster.
- with ha Consul
- with ha Vault

![ECS infra](img/ecs-infra.png)

## What are we creating?

* VPC with a /16 ip address range and an internet gateway
* We are choosing a region and a number of availability zones we want to use. For high-availability we need at least two
* In every availability zone we are creating a private and a public subnet with a /24 ip address range
  * Public subnet convention is 10.x.0.x and 10.x.1.x etc..
  * Private subnet convention is 10.x.50.x and 10.x.51.x etc..
* In the public subnet we place a NAT gateway and the LoadBalancer
* The private subnets are used in the autoscale group which places instances in them
* We create an ECS cluster where the instances connect to

## How to create it?

The project layout is designed in such a way that we can easily manage this infrastructure within many different aws accounts.
- the */config-common/* directory contains the .tf files to create the infrastructure, but we'll never apply terraform directly against the files in this directory
- the */config-sandbox-us-east-1/* directory contains symlinks to the tf files that exist within */config-common/*, this is where we will run "terraform apply"
- [direnv](https://direnv.net/) is used to supply the correct aws creds, direnv is an environment switcher for the shell, check out [config-sandbox-us-east-1/envrc](config-sandbox-us-east-1/envrc) for instructions

using the default terraform flow:

```bash
cd config-sandbox-us-east-1
terraform get -update=true
terraform plan
terraform apply
```