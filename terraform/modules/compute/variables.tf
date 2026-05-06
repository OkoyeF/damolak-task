variable "environment"       { type = string }
variable "instance_type"     { type = string }
variable "ami_id"            { type = string }
variable "app_port"          { type = number }
variable "vpc_id"            { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "ecr_image_uri"     { type = string }