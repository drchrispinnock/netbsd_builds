
variable "region" {
  description = "Value of the EC2 region"
  type        = string
  default     = "eu-west-2"
}

variable "openbsd-ami" {
  description = "AMI string of OpenBSD in eu-west-2"
  type        = string
  default     = "ami-e3809387"
}

variable "freebsd-13-ami" {
  description = "AMI string of FreeBSD 13 (x86) in eu-west-2"
  type        = string
  default     = "ami-0008f3d6d4c41d1f1"
}

variable "freebsd-12-ami" {
  description = "AMI string of FreeBSD 12 (x86) in eu-west-2"
  type        = string
  default     = "ami-0008f3d6d4c41d1f1"
}
