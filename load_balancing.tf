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
