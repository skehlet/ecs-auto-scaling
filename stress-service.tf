resource "aws_ecs_task_definition" "stress" {
  family = "${var.app_name}-${var.environment}-stress"
  # We specify 32 cpu units, which is 1/32 of a single CPU (1024).
  # Pegging a single CPU will therefore show up as "3200%".
  container_definitions = <<EOF
[
    {
        "command": ["-c", "1", "--timeout", "150"],
        "cpu": 32,
        "image": "519765885403.dkr.ecr.us-west-2.amazonaws.com/ecs-autoscaling-dev-timed-stress:latest",
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
              "awslogs-group": "${var.app_name}-${var.environment}-container",
              "awslogs-region": "${var.region}",
              "awslogs-stream-prefix": "${var.app_name}-${var.environment}-stress"
            }
        },
        "memoryReservation": 128,
        "name": "${var.app_name}-${var.environment}-stress"
    }
]
EOF
}

resource "aws_ecs_service" "stress" {
  name            = "${var.app_name}-${var.environment}-stress"
  cluster         = "${aws_ecs_cluster.cluster.id}"
  task_definition = "${aws_ecs_task_definition.stress.arn}"
  desired_count   = 1
}




resource "aws_cloudwatch_metric_alarm" "stress_high_cpu" {
  alarm_name          = "${var.app_name}-${var.environment}-stress-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "2400" # 75% of 3200%

  dimensions {
    ClusterName = "${aws_ecs_cluster.cluster.name}"
    ServiceName = "${aws_ecs_service.stress.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.stress_autoscale_out.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "stress_low_cpu" {
  alarm_name          = "${var.app_name}-${var.environment}-stress-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "800" # 25% of 3200%

  dimensions {
    ClusterName = "${aws_ecs_cluster.cluster.name}"
    ServiceName = "${aws_ecs_service.stress.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.stress_autoscale_in.arn}"]
}

resource "aws_appautoscaling_target" "stress_autoscaling_target" {
  min_capacity       = 1
  max_capacity       = 3
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.stress.name}"
  role_arn           = "${aws_iam_role.ecs_autoscaling_role.arn}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "stress_autoscale_out" {
  name               = "${var.app_name}-${var.environment}-stress-scale-out"
  policy_type        = "StepScaling"
  resource_id        = "${aws_appautoscaling_target.stress_autoscaling_target.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.stress_autoscaling_target.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.stress_autoscaling_target.service_namespace}"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = ["aws_appautoscaling_target.stress_autoscaling_target"]
}

resource "aws_appautoscaling_policy" "stress_autoscale_in" {
  name               = "${var.app_name}-${var.environment}-stress-scale-in"
  policy_type        = "StepScaling"
  resource_id        = "${aws_appautoscaling_target.stress_autoscaling_target.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.stress_autoscaling_target.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.stress_autoscaling_target.service_namespace}"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = ["aws_appautoscaling_target.stress_autoscaling_target"]
}

