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
