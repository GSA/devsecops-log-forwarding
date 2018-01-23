locals {
  logging_port = 514
  logging_protocol = "TCP"
}

resource "aws_launch_configuration" "log_forwarding" {
  name_prefix = "log-forwarding-"
  image_id      = "${var.ami_id}"
  instance_type = "t2.micro"

  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html#using-with-autoscaling-groups
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "log_forwarding" {
  # force the autoscaling group to be recreated when the launch configuration changes
  # https://stackoverflow.com/a/40985996/358804
  name = "${aws_launch_configuration.log_forwarding.name}"

  vpc_zone_identifier = ["${var.instance_subnets}"]
  # will likely switch to Launch Template once available
  # https://github.com/terraform-providers/terraform-provider-aws/issues/2505
  launch_configuration      = "${aws_launch_configuration.log_forwarding.name}"

  max_size                  = 3
  min_size                  = 1
  desired_capacity          = 2

  target_group_arns = ["${aws_lb_target_group.log_forwarding.arn}"]

  tag {
    key                 = "Component"
    value               = "log-forwarding"
    propagate_at_launch = true
  }

  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html#using-with-autoscaling-groups
  lifecycle {
    create_before_destroy = true
  }
}
