variable "app_name" {
  default = "ecs-autoscaling"
}

variable "environment" {
  default = "dev"
}

variable "region" {
  default = "us-west-2"
}

variable "vpc_cidr" {
  default = "172.19.0.0/16"
}

variable "availability_zones" {
  type = "list"
  default = [
    "us-west-2a",
    "us-west-2b"
  ]
}

variable "public_subnet_cidrs" {
  type = "list"
  default = [
    "172.19.0.0/21",
    "172.19.8.0/21"
  ]
}

variable "private_subnet_cidrs" {
  type = "list"
  default = [
    "172.19.24.0/21",
    "172.19.32.0/21"
  ]
}

variable "nat_instance_type" {
  default = "t2.micro"
}

variable "ssh_key_name" {}

variable "ecs_ami" {
  default = "ami-10ed6968" # us-west-2 amzn-ami-2017.09.h-amazon-ecs-optimized
}

variable "ecs_instance_type" {
  default = "t2.micro"
}

variable "ecs_min_size" {
  default = 1
}

variable "ecs_max_size" {
  default = 4
}

variable "ecs_desired_capacity" {
  default = 3
}

variable "jump_box_ami" {
  default = "ami-f2d3638a" # us-west-2 Amazon Linux AMI 2017.09.1 (HVM), SSD Volume Type
}

variable "jump_box_ssh_cidr" {
  default = "0.0.0.0/0"
}

variable "jump_box_instance_type" {
  default = "t2.micro"
}
