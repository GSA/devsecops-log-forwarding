output "vpc_id" {
  value = "${module.network.vpc_id}"
}

output "logging_host" {
  value = "${module.log_forwarding.logging_host}"
}
