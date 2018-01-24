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
  default = 514
  description = "Incoming log port"
}
