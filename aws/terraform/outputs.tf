
#output "dns_name_o" {
#  description = "Name of the OpenBSD EC2 instance"
#  value       = aws_instance.openbsd.public_dns
#}

output "dns_name_freebsd_13" {
  description = "Name of the FreeBSD EC2 instance"
  value       = aws_instance.freebsd-13.public_dns
}

output "dns_name_debian" {
  description = "Name of the Debian instance"
  value       = aws_instance.debian-10.public_dns
}
