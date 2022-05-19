variable "vpc_cidr_block" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tag_name" {
  description = "All resources are tagged with the same name"
  type        = string
  default     = "ClirTest"
}

variable "eip_vpc" {
  description = "this variable will define my vpc within eip"
  type        = bool
  default     = true
}
