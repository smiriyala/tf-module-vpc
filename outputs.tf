output "public_subnets" {
    value = aws_subnet.public_subnets[0].id
}