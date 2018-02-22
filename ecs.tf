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

resource "aws_autoscaling_group" "ecs_instance" {
  name_prefix          = "${var.app_name}-${var.environment}-ecs"
  vpc_zone_identifier  = ["${aws_subnet.private.*.id}"]
  max_size             = "${var.ecs_max_size}"
  min_size             = "${var.ecs_min_size}"
  desired_capacity     = "${var.ecs_desired_capacity}"
  launch_configuration = "${aws_launch_configuration.ecs_instance.name}"
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



resource "aws_iam_role" "ecs_autoscaling_role" {
  name = "${var.app_name}-${var.environment}-ecs-autoscaling-role"
  force_detach_policies = true
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "application-autoscaling.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_autoscaling_policy" {
  name = "${var.app_name}-${var.environment}-ecs-autoscaling-policy"
  role = "${aws_iam_role.ecs_autoscaling_role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:DeleteAlarms",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:PutMetricAlarm",
                "ecs:DescribeServices",
                "ecs:UpdateService"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}




resource "aws_ecs_cluster" "cluster" {
  name = "${var.app_name}-${var.environment}-ecs-cluster"
}

resource "aws_ecr_repository" "ecr_timed_stress" {
  name = "${var.app_name}-${var.environment}-timed-stress"
}

resource "aws_cloudwatch_log_group" "container" {
  name              = "${var.app_name}-${var.environment}-container"
  retention_in_days = "3"
}

// revisit this if putting services behind a load balancer
//resource "aws_iam_role" "ecs_container_role" {
//  name = "${var.app_name}-${var.environment}-ecs-container-role"
//  force_detach_policies = true
//  assume_role_policy = <<EOF
//{
//  "Version": "2008-10-17",
//  "Statement": [
//    {
//      "Sid": "",
//      "Effect": "Allow",
//      "Principal": {
//        "Service": [
//          "ecs.amazonaws.com",
//          "ecs-tasks.amazonaws.com"
//        ]
//      },
//      "Action": "sts:AssumeRole"
//    }
//  ]
//}
//EOF
//}
//
//resource "aws_iam_role_policy" "ecs_policy" {
//  name = "${var.app_name}-${var.environment}-ecs-container-policy"
//  role = "${aws_iam_role.ecs_container_role.id}"
//  policy = <<EOF
//{
//  "Version": "2012-10-17",
//  "Statement": [
//    {
//      "Effect": "Allow",
//      "Action": [
//        "ec2:Describe*",
//        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
//        "elasticloadbalancing:DeregisterTargets",
//        "elasticloadbalancing:Describe*",
//        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
//        "elasticloadbalancing:RegisterTargets"
//      ],
//      "Resource": "*"
//    }
//  ]
//}
//EOF
//}
//
//resource "aws_iam_role_policy_attachment" "iam_policy_attachment" {
//  role = "${aws_iam_role.ecs_container_role.name}"
//  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
//}
