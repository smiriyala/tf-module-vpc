#create a VPC
#STEP 1 - CREATE VPC                   --- DONE
# the variable values are being passed from parent module
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    var.tags,
    { Name = "${var.env}-vpc" }
  )
}


#adding public subnet resource
#STEP 2.1: CREATE PRIVATE & PUBLIC SUBNET  --- DONE
resource "aws_subnet" "public_subnets" {
  vpc_id = aws_vpc.main.id

  for_each          = var.public_subnets
  cidr_block        = each.value["cidr_block"]
  availability_zone = each.value["availability_zone"]
  tags = merge(
    var.tags,
    { Name = "${var.env}-${each.value["name"]}" }
  )

}

#STEP 2.2:CREATE PRIVATE & PUBLIC SUBNET  --- DONE
#adding private subnet resource
resource "aws_subnet" "private_subnets" {
  vpc_id = aws_vpc.main.id

  for_each          = var.private_subnets
  cidr_block        = each.value["cidr_block"]
  availability_zone = each.value["availability_zone"]
  tags = merge(
    var.tags,
    { Name = "${var.env}-${each.value["name"]}" }
  )

}


#STEP 3.1: CREATE PUBLIC ROUTE TABLES      ---- DONE
##Createing Public Routing tables 
resource "aws_route_table" "public-route-table" {
  vpc_id   = aws_vpc.main.id

  #this route is adding inpart of STEP5.1
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internetGateWay.id
  }

  #this route is adding inpart of STEP 7 - Peering VPC
  route {
    cidr_block = data.aws_vpc.default_vpc.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }

  for_each = var.public_subnets
  tags = merge(
    var.tags,
    { Name = "${var.env}-${each.value["name"]}" }
  )
}


#STEP 3.2: CREATE PRIVATE ROUTE TABLES      ---- DONE
##Createing Private Routing tables 
resource "aws_route_table" "private-route-table" {
  vpc_id   = aws_vpc.main.id
  for_each = var.private_subnets

  #IN Part of STEP 5.3, NAT Gateway routing adding here. 
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateways["public-${split("-", each.value["name"])[1]}"].id

  }

  #this route is adding inpart of STEP 7 - Peering VPC
  route {
    cidr_block = data.aws_vpc.default_vpc.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }

  tags = merge(
    var.tags,
    { Name = "${var.env}-${each.value["name"]}" }
  )
}


#STEP 4.1: Associate route tables wto appropriate public subnets
resource "aws_route_table_association" "public-association" {
  for_each = var.public_subnets
  # Get public subnetID for each subnit by referring above subnet create resource

  # there is other way to use in terraform - LOOKUP function
  /* subnet_id      = aws_subnet.public_subnets[each.value["name"]].id */
  subnet_id      = lookup(lookup(aws_subnet.public_subnets, each.value["name"], null), "id", null)
  route_table_id = aws_route_table.public-route-table[each.value["name"]].id
}

#STEP 4.2: Associate route tables to appropriate private subnets
resource "aws_route_table_association" "private-association" {
  for_each = var.private_subnets
  # Get public subnetID for each subnit by referring above subnet create resource

  # there is other way to use in terraform - LOOKUP function
  /* subnet_id      = aws_subnet.public_subnets[each.value["name"]].id */
  subnet_id      = lookup(lookup(aws_subnet.private_subnets, each.value["name"], null), "id", null)
  route_table_id = aws_route_table.private-route-table[each.value["name"]].id
  
}


#STEP 5.1: Add Internet GatewaY TO VPC and Public subnet route table
# STEP 3.1 - second part on above added to "Public subnet route table"
resource "aws_internet_gateway" "internetGateWay" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.tags,
    { Name = "${var.env}-igw" }
  )
}

# STEP 6.1 CREATE A NAT GATEWAY Which is part of the PUBLIC SUBNET
resource "aws_nat_gateway" "nat-gateways" {

  # need to create two NAT gateways for each foe public subnets
  for_each = var.public_subnets
  allocation_id = aws_eip.nat[each.value["name"]].id
  subnet_id     = aws_subnet.public_subnets[each.value["name"]].id

  tags = merge(
    var.tags,
    { Name = "${var.env}-${each.value["name"]}" }
  )
}

# IN Part of STEP6.2, ELASTIC IP Address required to connect internet through NAT gateway
# Each public subnet must have separate ElasticIP for NAT gateway purpose. 
resource "aws_eip" "nat" {
  for_each = var.public_subnets
  vpc = true
}

# STEP 6.3 - ADD route in private subnet.
  # IN Part of STEP6.3, ELASTIC IP Address, lets create
  # ONCE NAT GATEWAY CREATED, route table  must be added to private route table
  # UPDATED IN STEP 3.2: for private route table wiht matching availability zone. 


# STEP 7.1 - Adding Peering connection to default VPC
resource "aws_vpc_peering_connection" "peer" {
  peer_owner_id = data.aws_caller_identity.account.account_id
  peer_vpc_id   = var.default_vpc_id
  vpc_id        = aws_vpc.main.id
  
  # Auto accept can be given for my VPC account
  # auto accept cannt be done with someone own's vpc account 
  auto_accept   = true
  tags = merge(
    var.tags,
    { Name = "${var.env}-peer" }
  )
}

# STEP 8 - ADD Peering entry in private and public route tables. 
  # Entries of route added in both private and public routes

##Step 9 - route to default VPC for peering to work
resource "aws_route" "route" {
  route_table_id = var.default_route_table
  destination_cidr_block = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}