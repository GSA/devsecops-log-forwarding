output "logging_host" {
  value = "${aws_lb.log_forwarding.dns_name}"
}

output "logging_port" {
  value = "${var.logging_port}"
}
