resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.app_name}-${var.environment}-ecs"
  force_detach_policies = true
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

//data "aws_iam_policy_document" "iam_policy_document_1" {
//  statement {
//    actions = [
//      "logs:CreateLogGroup",
//      "logs:CreateLogStream",
//      "logs:PutLogEvents",
//      "logs:DescribeLogStreams",
//    ]
//    resources = ["*"]
//  }
//
//  statement {
//    actions = ["ecs:*"]
//    resources = ["*"]
//  }
//
//  statement {
//    actions = ["ec2:DescribeInstances"]
//    resources = ["*"]
//  }
//
//  statement {
//    actions = [
//      "ecr:BatchCheckLayerAvailability",
//      "ecr:BatchGetImage",
//      "ecr:GetDownloadUrlForLayer",
//      "ecr:GetAuthorizationToken",
//    ]
//    resources = ["*"]
//  }
//}

//resource "aws_iam_role_policy" "iam_role_policy_1" {
//  name   = "${var.app_name}-${var.environment}-ecs"
//  role   = "${aws_iam_role.iam_role_1.id}"
//  policy = "${data.aws_iam_policy_document.iam_policy_document_1.json}"
//}

resource "aws_iam_role_policy_attachment" "iam_policy_attachment" {
  role = "${aws_iam_role.ecs_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.app_name}-${var.environment}"
  role = "${aws_iam_role.ecs_instance_role.name}"
}


resource "aws_security_group" "ecs_instance" {
  name        = "${var.app_name}-${var.environment}-ecs-sg"
  vpc_id      = "${aws_vpc.vpc.id}"
  ingress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = ["${var.vpc_cidr}"]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name        = "${var.app_name}-${var.environment}-ecs-sg"
    Environment = "${var.environment}"
  }
}



resource "aws_launch_configuration" "ecs_instance" {
  name_prefix          = "${var.app_name}-${var.environment}"
  image_id             = "${var.ecs_ami}"
  instance_type        = "${var.ecs_instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs_instance_profile.name}"
  key_name             = "${var.ssh_key_name}"
  security_groups      = ["${aws_security_group.ecs_instance.id}"]

  user_data = <<EOUSERDATA
#!/bin/bash
set -x

# redirect stdout/err to syslog so we can troubleshoot
exec 1> >(logger -s -t user-data) 2>&1

echo ECS_CLUSTER=${var.app_name}-${var.environment}-ecs-cluster >> /etc/ecs/ecs.config
echo ECS_LOGLEVEL=info >> /etc/ecs/ecs.config

start ecs

yum install -y aws-cli jq awslogs
EOUSERDATA

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "autoscaling_group_1" {
  name                 = "${var.app_name}-${var.environment}-ecs"
  vpc_zone_identifier  = ["${aws_subnet.private.*.id}"]
  max_size             = "${var.ecs_max_size}"
  min_size             = "${var.ecs_min_size}"
  desired_capacity     = "${var.ecs_desired_capacity}"
  launch_configuration = "${aws_launch_configuration.ecs_instance.name}"

//  health_check_grace_period = "${var.health_check_grace_period}"
//  health_check_type         = "${var.health_check_type}"
//  force_delete              = false
//  termination_policies      = "${var.termination_policies}"
//  wait_for_capacity_timeout = "10m"
//  protect_from_scale_in     = "${var.scale_in_protection}"

//  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]

  tag {
    key = "Name"
    propagate_at_launch = true
    value = "${var.app_name}-${var.environment}-ecs"
  }
  tag {
    key = "Environment"
    propagate_at_launch = true
    value = "${var.environment}"
  }
}


resource "aws_ecs_cluster" "cluster" {
  name = "${var.app_name}-${var.environment}-ecs-cluster"
}

resource "aws_ecr_repository" "ecr" {
  name = "${var.app_name}"
}
