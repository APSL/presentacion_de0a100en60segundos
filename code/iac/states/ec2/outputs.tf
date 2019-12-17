output "elastic_ip_addr" {
  value = aws_eip.emili-darder-instance-ip.public_ip
}
