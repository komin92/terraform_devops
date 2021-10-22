output "nat_gateway_ip" {
  value = aws_eip.allocation-ngw.public_ip
}

output "devops_private_subnets" {
    value = aws_subnet.devops_private_subnet.*.id
}



output "devops_public_subnets" {
    value = aws_subnet.devops_public_subnet.*.id
}

output "devops-internet-gw" {
  value = aws_internet_gateway.devops-igw.id
}

output "nat-gateway" {
  value = aws_nat_gateway.devops-ngw.id
}


