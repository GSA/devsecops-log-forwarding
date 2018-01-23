variable "vpc_id" {
  type = "string"
}

variable "public_subnets" {
  type = "list"
}

variable "private_subnets" {
  type = "list"
}

variable "ami_id" {
  type = "string"
}

variable "azs" {
  type = "list"
}
