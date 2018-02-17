resource "aws_security_group" "jump_box" {
  name = "${var.app_name}-${var.environment}-jump-box"
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["${var.jump_box_ssh_cidr}"]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "${var.app_name}-${var.environment}-jump-box"
    Environment = "${var.environment}"
  }
}

resource "aws_launch_configuration" "jump_box" {
  name_prefix = "${var.app_name}-${var.environment}-jump-box"
  image_id = "${var.jump_box_ami}"
  instance_type = "${var.jump_box_instance_type}"
  key_name = "${var.ssh_key_name}"
  security_groups = ["${aws_security_group.jump_box.id}"]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "jump_box" {
  launch_configuration = "${aws_launch_configuration.jump_box.id}"
  vpc_zone_identifier  = ["${aws_subnet.public.*.id}"]
  min_size = 1
  max_size = 1
  tag {
    key = "Name"
    value = "jump-box"
    propagate_at_launch = true
  }
}
