output "public_subnets" {
    value = aws_subnet.public_subnets
}

## This output needed by docdb to crate subnets-group
output "private_subnets" {
    value = aws_subnet.private_subnets
}