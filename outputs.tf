output "logging_host" {
  value = "${aws_alb.log_forwarding.dns_name}"
}
