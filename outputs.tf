output "logging_host" {
  value = "${aws_lb.log_forwarding.dns_name}"
}
