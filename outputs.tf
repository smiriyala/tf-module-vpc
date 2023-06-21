output "public_subnets" {
    value = aws_subnet.public_subnets
}

## This output needed by docdb to crate subnets-group
output "private_subnets" {
    value = aws_subnet.private_subnets
}

## This output returned VPC ID to be used in App Module to create Security Group.
output "vpc_id" {
    value = aws_vpc.main.id
}