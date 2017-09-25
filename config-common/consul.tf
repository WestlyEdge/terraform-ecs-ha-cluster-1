
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
          "hostname": "consul-host-1",
          "disableNetworking": false,
          "privileged": true,
          "readonlyRootFilesystem": false,
          "portMappings": [
            {
              "containerPort": 8500,
              "hostPort": 8500
            }
          ],
          "environment" : [
              { "name" : "testname", "value" : "testvalue" }
          ]
      }
  ]
  DEFINITION

  placement_constraints {
    type = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-east-1a, us-east-1b, us-east-1c]"
  }
}

resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "ingress"
  from_port                = 8500
  to_port                  = 8500
  protocol                 = "TCP"
  source_security_group_id = "${module.ecs.alb_security_group_id}"
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

resource "aws_iam_role_policy_attachment" "ec2-admin-access-policy-attachment" {
  role = "${aws_iam_role.consul.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}