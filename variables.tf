variable "vpc_id" {
  type = "string"
}

variable "lb_subnets" {
  type = "list"
}

variable "instance_subnets" {
  type = "list"
}

variable "ami_id" {
  type = "string"
}

variable "key_pair" {
  type = "string"
}

variable "ssh_cidr" {
  default = "0.0.0.0/0"
}

variable "logging_port" {
  default = 601
  description = "Incoming log port. Uses the default for syslog over TCP, as defined by IANA RFC3195. https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml?search=syslog"
}
