locals {
  logging_protocol = "TCP"
}

resource "aws_security_group" "public" {
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = "${var.logging_port}"
    to_port = "${var.logging_port}"
    protocol = "${local.logging_protocol}"
    # TODO change to VPC CIDR
    cidr_blocks = ["${var.ssh_cidr}"]
  }
  # SSH
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.ssh_cidr}"]
  }

  egress {
    # allow all
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "setup" {
  template = "${file("${path.module}/templates/setup.sh")}"
  vars {
    incoming_port = "${var.logging_port}"
  }
}

resource "aws_launch_configuration" "log_forwarding" {
  name_prefix = "log-forwarding-"
  image_id      = "${var.ami_id}"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.public.id}"]
  key_name = "${var.key_pair}"
  user_data = "${data.template_file.setup.rendered}"

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
  # TODO increase
  desired_capacity          = 1

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
