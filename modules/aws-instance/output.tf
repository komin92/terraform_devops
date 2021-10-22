output "instance_ip" {
    value = aws_instance.devops-server.public_ip
}

output "instance_id" {
  value = aws_instance.devops-server.id
}
