#create a VPC
# the variable values are being passed from parent module
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge( 
    var.tags, 
    { Name = "${var.env}-vpc" }
  )
}


#adding public subnet resource
resource "aws_subnet" "public_subnets" {
  vpc_id = aws_vpc.main.id
  
  for_each = var.public_subnets
  cidr_block = each.value[ "cidr_block" ]
  availability_zone = each.value["availability_zone"]
    tags = merge( 
    var.tags, 
    { Name = "${var.env}-${each.value["name"]}" }
  )
  
}

#adding private subnet resource
resource "aws_subnet" "private_subnets" {
  vpc_id = aws_vpc.main.id
  
  for_each = var.private_subnets
  cidr_block = each.value[ "cidr_block" ]
  availability_zone = each.value["availability_zone"]
  tags = merge( 
    var.tags, 
    { Name = "${var.env}-${each.value["name"]}" }
  )
  
}