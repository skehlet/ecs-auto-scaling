resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr}"
  tags {
    Name = "${var.app_name}-${var.environment}-vpc"
    Environment = "${var.environment}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name = "${var.app_name}-${var.environment}-igw"
    Environment = "${var.environment}"
  }
}

resource "aws_subnet" "public" {
  count                   = "${length(var.public_subnet_cidrs)}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${element(var.public_subnet_cidrs, count.index)}"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = true
  tags {
    Name = "${var.app_name}-${var.environment}-${element(var.availability_zones, count.index)}-public-subnet"
    Environment = "${var.environment}"
    type = "public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
  tags {
    Name = "${var.app_name}-${var.environment}-public-route-table"
    Environment = "${var.environment}"
  }
}

resource "aws_route_table_association" "public" {
  count = "${length(var.public_subnet_cidrs)}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_subnet" "private" {
  count             = "${length(var.private_subnet_cidrs)}"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${element(var.private_subnet_cidrs, count.index)}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  tags {
    Name = "${var.app_name}-${var.environment}-${element(var.availability_zones, count.index)}-private-subnet"
    Environment = "${var.environment}"
    type = "private"
  }
}

resource "aws_security_group" "nat" {
  count       = "${length(var.private_subnet_cidrs)}"
  name        = "${var.app_name}-${var.environment}-nat${count.index}-sg"
  vpc_id      = "${aws_vpc.vpc.id}"
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${element(aws_subnet.private.*.cidr_block, count.index)}"]
  }
  tags {
    Name = "${var.app_name}-nat${count.index}-sg"
    Environment = "${var.environment}"
  }
}

resource "aws_instance" "nat" {
  count = "${length(var.private_subnet_cidrs)}"
  ami = "ami-35d6664d" # amzn-ami-vpc-nat-hvm-2017.09.1.20180115-x86_64-ebs
  availability_zone = "${element(var.availability_zones, count.index)}"
  instance_type = "${var.nat_instance_type}"
  key_name = "${var.ssh_key_name}"
  vpc_security_group_ids = ["${element(aws_security_group.nat.*.id, count.index)}"]
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  associate_public_ip_address = true
  source_dest_check = false
  tags {
    Name = "${var.app_name}-${var.environment}-nat${count.index}"
    Environment = "${var.environment}"
  }
}

resource "aws_cloudwatch_metric_alarm" "nat_recover" {
  count = "${length(var.private_subnet_cidrs)}"
  alarm_name = "${var.app_name}-${var.environment}-nat${count.index}-recover"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = "1"
  metric_name = "StatusCheckFailed_System"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Minimum"
  threshold = "0"
  alarm_actions = ["arn:aws:automate:${var.region}:ec2:recover"]
  dimensions = {
    InstanceId = "${element(aws_instance.nat.*.id, count.index)}"
  }
  depends_on = ["aws_instance.nat"]
}

resource "aws_route_table" "private" {
  count = "${length(var.private_subnet_cidrs)}"
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${element(aws_instance.nat.*.id, count.index)}"
  }
  tags {
    Name = "${var.app_name}-${var.environment}-private-route-table"
    Environment = "${var.environment}"
  }
}

resource "aws_route_table_association" "private" {
  count = "${length(var.private_subnet_cidrs)}"
  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}
