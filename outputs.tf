output "docker-server-ip" {
  value = "http://${aws_instance.docker-server.public_ip}"
}

output "docker-server-dns" {
  value = "http://${aws_instance.docker-server.public_dns}"
}

output "add-task-ip" {
  value = "http://${aws_instance.docker-server.public_ip}/addtask"
}

output "remove-task-ip" {
  value = "http://${aws_instance.docker-server.public_ip}/removetask"
}
