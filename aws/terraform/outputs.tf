
#output "dns_name_o" {
#  description = "Name of the OpenBSD EC2 instance"
#  value       = aws_instance.openbsd.public_dns
#}

output "dns_name_f" {
  description = "Name of the FreeBSD EC2 instance"
  value       = aws_instance.freebsd.public_dns
}
