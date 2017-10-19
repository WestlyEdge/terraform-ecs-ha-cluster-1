
module "alb_consul" {
  source = "git@github.com:WestlyEdge/terraform-modules//modules//alb"

  alb_name          = "alb-consul"
  port              = 80
  protocol          = "HTTP"
  environment       = "${var.environment}"
  vpc_id            = "${module.ecs.network_vpc_id}"
  public_subnet_ids = "${module.ecs.network_public_subnet_ids}"
  health_check_path = "/v1/catalog/nodes"
}

resource "aws_ecs_service" "consul" {

  depends_on = ["module.ecs"]

  name            = "consul"
  cluster         = "${module.ecs.ecs_cluster_arn}"
  task_definition = "${aws_ecs_task_definition.consul.arn}"
  desired_count   = "${var.desired_capacity}"
  iam_role        = "${aws_iam_role.consul.arn}"

  load_balancer   = [
    {
      target_group_arn = "${module.alb_consul.alb_target_group}",
      container_name = "consul",
      container_port = 8500
    }
  ]

  placement_strategy {
    field = "instanceId"
    type  = "spread"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-east-1a, us-east-1b, us-east-1c]"
  }
}

resource "aws_ecs_task_definition" "consul" {
  family = "consul"
  task_role_arn = "${aws_iam_role.consul.arn}"
  network_mode = "host"

  container_definitions = <<DEFINITION
  [
      {
          "name": "consul",
          "image": "consul:0.9.3",
          "essential": true,
          "memory": 500,
          "disableNetworking": false,
          "privileged": true,
          "readonlyRootFilesystem": false,
          "portMappings": [
            { "containerPort": 8300, "hostPort": 8300 },
            { "containerPort": 8301, "hostPort": 8301 },
            { "containerPort": 8500, "hostPort": 8500 }
          ],
          "environment" : [
              { "name" : "CONSUL_BIND_INTERFACE", "value" : "eth0" }
          ],
          "command": [
              "agent",
              "-server",
              "-client=0.0.0.0",
              "-bootstrap-expect=3",
              "-ui",
              "-datacenter=dc0",
              "-retry-join-ec2-tag-key=Cluster",
              "-retry-join-ec2-tag-value=${var.cluster_name}"
          ],
          "logConfiguration": {
              "logDriver": "awslogs",
              "options": {
                  "awslogs-group": "${var.cluster_name}/consul",
                  "awslogs-region": "us-east-1",
                  "awslogs-stream-prefix": "${var.cluster_name}"
              }
          }
      }
  ]
  DEFINITION

  placement_constraints {
    type = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-east-1a, us-east-1b, us-east-1c]"
  }
}

resource "aws_security_group_rule" "alb-consul-to-ecs-instance" {
  type                     = "ingress"
  from_port                = 8500
  to_port                  = 8500
  protocol                 = "TCP"
  source_security_group_id = "${module.alb_consul.alb_security_group_id}"
  security_group_id        = "${module.ecs.ecs_instance_security_group_id}"
}

resource "aws_security_group_rule" "consul-to-consul" {
  type                     = "ingress"
  from_port                = 8300
  to_port                  = 8301
  protocol                 = "TCP"
  self                     = true
  security_group_id        = "${module.ecs.ecs_instance_security_group_id}"
}

resource "aws_iam_role" "consul" {
  name = "consul"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": [
                    "ecs.amazonaws.com",
                    "ec2.amazonaws.com",
                    "ecs-tasks.amazonaws.com"
                ]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "consul-container-service-role-attachment" {
  role = "${aws_iam_role.consul.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_iam_policy" "consul-describe-instances-policy" {
  name = "consul-describe-instances-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:DescribeInstances",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "consul-ecs-decribe-instances-pa" {
  role = "${module.ecs.ecs_instance_role_name}"
  policy_arn = "${aws_iam_policy.consul-describe-instances-policy.arn}"
}

resource "aws_cloudwatch_log_group" "consul" {
  name              = "${var.cluster_name}/consul"
  retention_in_days = 30
}

output "consul_alb_dns_name" {
  value = "${module.alb_consul.alb_dns_name}"
}