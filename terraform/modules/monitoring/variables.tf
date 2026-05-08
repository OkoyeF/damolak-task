variable "environment"  { type = string }
variable "cluster_name" { type = string }
variable "service_name" { type = string }

variable "alert_email" {
  type    = string
  default = ""
}
