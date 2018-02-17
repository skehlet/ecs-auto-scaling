resource "aws_ecs_task_definition" "stress" {
  family = "${var.app_name}-${var.environment}-stress"
  container_definitions = <<EOF
[
    {
        "command": ["-c", "1"],
        "cpu": 1024,
        "image": "progrium/stress",
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
              "awslogs-group": "${var.app_name}-${var.environment}-container",
              "awslogs-region": "${var.region}",
              "awslogs-stream-prefix": "${var.app_name}-${var.environment}-stress"
            }
        },
        "memoryReservation": 512,
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
