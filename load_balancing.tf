resource "aws_lb" "log_forwarding" {
  # TODO make internal
  # internal = true

  # this is actually an NLB
  # https://aws.amazon.com/elasticloadbalancing/details/#compare
  load_balancer_type = "network"
  subnets = ["${var.lb_subnets}"]
}

resource "aws_lb_target_group" "log_forwarding" {
  vpc_id = "${var.vpc_id}"
  port = "${var.logging_port}"
  protocol = "${local.logging_protocol}"
}

resource "aws_lb_listener" "log_forwarding" {
  load_balancer_arn = "${aws_lb.log_forwarding.arn}"
  port = "${var.logging_port}"
  protocol = "${local.logging_protocol}"

  default_action {
    target_group_arn = "${aws_lb_target_group.log_forwarding.arn}"
    type = "forward"
  }
}
