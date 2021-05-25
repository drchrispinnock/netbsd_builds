
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
  default     = "ami-0c799aeda60f4e2c4"
}

variable "debian-10-ami" {
  description = "AMI string of Debian in eu-west-2"
  type        = string
  default     = "ami-050949f5d3aede071"
}

