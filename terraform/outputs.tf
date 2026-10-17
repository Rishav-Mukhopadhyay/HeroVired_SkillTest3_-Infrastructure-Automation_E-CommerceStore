output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.app.public_dns
}

output "frontend_url" {
  description = "Open this in your browser"
  value       = "http://${aws_instance.app.public_dns}"
}

output "frontend_status_url" {
  value = "http://${aws_instance.app.public_ip}/status"
}

output "backend_urls" {
  value = {
    user    = "http://${aws_instance.app.public_ip}:3001"
    product = "http://${aws_instance.app.public_ip}:3002"
    cart    = "http://${aws_instance.app.public_ip}:3003"
    order   = "http://${aws_instance.app.public_ip}:3004"
  }
}

output "ssh_command" {
  value = "ssh -i <path-to>/ecommerce-key.pem ubuntu@${aws_instance.app.public_ip}"
}
