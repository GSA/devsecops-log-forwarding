locals {
  logging_port = 514
  logging_protocol = "TCP"
}

resource "aws_launch_configuration" "log_forwarding" {
  name          = "log-forwarding"
  image_id      = "${var.ami_id}"
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "log_forwarding" {
  availability_zones = ["${var.azs}"]
  vpc_zone_identifier = ["${var.private_subnets}"]
  # will likely switch to Launch Template once available
  # https://github.com/terraform-providers/terraform-provider-aws/issues/2505
  launch_configuration      = "${aws_launch_configuration.log_forwarding.name}"

  max_size                  = 3
  min_size                  = 1
  desired_capacity          = 2

  target_group_arns = ["${aws_alb_target_group.log_forwarding.arn}"]

  tag {
    key                 = "Component"
    value               = "log-forwarding"
    propagate_at_launch = true
  }
}

resource "aws_alb" "log_forwarding" {
  # TODO make internal?
  # internal = true
  # https://aws.amazon.com/elasticloadbalancing/details/#compare
  load_balancer_type = "network"
  # TODO change to private
  subnets = ["${var.public_subnets}"]
}

resource "aws_alb_target_group" "log_forwarding" {
  vpc_id = "${var.vpc_id}"
  port = "${local.logging_port}"
  protocol = "${local.logging_protocol}"
}

resource "aws_alb_listener" "log_forwarding" {
  load_balancer_arn = "${aws_alb.log_forwarding.arn}"
  port = "${local.logging_port}"
  protocol = "${local.logging_protocol}"

  default_action {
    target_group_arn = "${aws_alb_target_group.log_forwarding.arn}"
    type = "forward"
  }
}
