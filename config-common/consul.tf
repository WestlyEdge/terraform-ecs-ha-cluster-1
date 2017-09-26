
resource "aws_ecs_service" "consul" {

  depends_on = ["module.ecs"]

  name            = "consul"
  cluster         = "${module.ecs.ecs_cluster_arn}"
  task_definition = "${aws_ecs_task_definition.consul.arn}"
  desired_count   = "${var.desired_capacity}"
  iam_role        = "${aws_iam_role.consul.arn}"

  load_balancer   = [
    {
      target_group_arn = "${module.ecs.alb_target_group}",
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
          "image": "consul",
          "essential": true,
          "memory": 500,
          "disableNetworking": false,
          "privileged": true,
          "readonlyRootFilesystem": false,
          "portMappings": [
            { "containerPort": 8600, "hostPort": 8600 },
            { "containerPort": 8500, "hostPort": 8500 },
            { "containerPort": 8300, "hostPort": 8300 },
            { "containerPort": 8301, "hostPort": 8301 }
          ],
          "environment" : [
              { "name" : "testname", "value" : "testvalue" },
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

resource "aws_security_group_rule" "alb-to-ecs" {
  type                     = "ingress"
  from_port                = 8500
  to_port                  = 8500
  protocol                 = "TCP"
  source_security_group_id = "${module.ecs.alb_security_group_id}"
  security_group_id        = "${module.ecs.ecs_instance_security_group_id}"
}

resource "aws_security_group_rule" "consul-to-consul" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 10000
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

resource "aws_iam_role_policy_attachment" "ec2-service-role-access-policy-attachment" {
  role = "${aws_iam_role.consul.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_iam_policy" "describe-instances" {
  name = "describe-instances"

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

resource "aws_iam_role_policy_attachment" "ecs-decribe-instances" {
  role = "${module.ecs.ecs_instance_role_name}"
  policy_arn = "${aws_iam_policy.describe-instances.arn}"
}

resource "aws_cloudwatch_log_group" "consul" {
  name              = "${var.cluster_name}/consul"
  retention_in_days = 30
}