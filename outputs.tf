output "public_subnets" {
    for_each = aws_subnet.public_subnets
    value = aws_subnet.public_subnets.[each.value["name"]].id
}