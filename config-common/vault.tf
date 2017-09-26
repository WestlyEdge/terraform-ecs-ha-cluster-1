
module "alb-vault" {

  source = "git@github.com:WestlyEdge/terraform-modules//modules//alb"

  alb_name          = "alb-vault"
  port              = 80
  protocol          = "HTTP"
  environment       = "${var.environment}"
  vpc_id            = "${module.ecs.network_vpc_id}"
  public_subnet_ids = "${module.ecs.network_public_subnet_ids}"
  health_check_path = "/v1/catalog/nodes"
}

resource "aws_ecs_service" "vault" {

  depends_on = ["aws_ecs_service.consul"]

  name            = "vault"
  cluster         = "${module.ecs.ecs_cluster_arn}"
  task_definition = "${aws_ecs_task_definition.vault.arn}"
  desired_count   = "${var.desired_capacity}"
  iam_role        = "${aws_iam_role.vault.arn}"

  load_balancer   = [
    {
      target_group_arn = "${module.alb-vault.alb_target_group}",
      container_name = "vault",
      container_port = 8200
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

resource "aws_ecs_task_definition" "vault" {
  family = "vault"
  task_role_arn = "${aws_iam_role.vault.arn}"
  network_mode = "host"

  container_definitions = <<DEFINITION
  [
      {
          "name": "vault",
          "image": "vault",
          "essential": true,
          "memory": 500,
          "disableNetworking": false,
          "privileged": true,
          "readonlyRootFilesystem": false,
          "portMappings": [
            { "containerPort": 8200, "hostPort": 8200 }
          ],
          "environment" : [
              { "name" : "testname", "value" : "testvalue" }
          ],
          "command": [],
          "logConfiguration": {
              "logDriver": "awslogs",
              "options": {
                  "awslogs-group": "${var.cluster_name}/vault",
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

resource "aws_iam_role" "vault" {
  name = "vault"

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

resource "aws_iam_role_policy_attachment" "vault-container-service-role-attachment" {
  role = "${aws_iam_role.vault.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_security_group_rule" "alb-vault-to-ecs-instance" {
  type                     = "ingress"
  from_port                = 8200
  to_port                  = 8200
  protocol                 = "TCP"
  source_security_group_id = "${module.alb-vault.alb_security_group_id}"
  security_group_id        = "${module.ecs.ecs_instance_security_group_id}"
}

resource "aws_security_group_rule" "vault-to-vault" {
  type                     = "ingress"
  from_port                = 8300
  to_port                  = 8301
  protocol                 = "TCP"
  self                     = true
  security_group_id        = "${module.ecs.ecs_instance_security_group_id}"
}

resource "aws_iam_policy" "vault-describe-instances-policy" {
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

resource "aws_iam_role_policy_attachment" "vault-ecs-decribe-instances-pa" {
  role = "${module.ecs.ecs_instance_role_name}"
  policy_arn = "${aws_iam_policy.vault-describe-instances-policy.arn}"
}

resource "aws_cloudwatch_log_group" "vault" {
  name              = "${var.cluster_name}/vault"
  retention_in_days = 30
}
