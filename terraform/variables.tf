variable "env" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type = string
}

variable "service_name" {
  type    = string
  default = "clientx"
}