#creating vpc roboshop-dev

resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  enable_dns_hostnames = "true"

  tags = merge (
    var.vpc_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}"
    }
  )
}

#creating IGW  roboshop-dev

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.igw_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}"
    }
  )
}

# create public subnets

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]

  availability_zone = local.az_names[count.index]
  map_public_ip_on_launch = true                    #as it is private subent we need to write this

  tags = merge(
    var.public_subnet_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-public-${local.az_names[count.index]}"
    }
  )
}

# create private subnets

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]

  availability_zone = local.az_names[count.index]

  tags = merge(
    var.private_subnet_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-private-${local.az_names[count.index]}"
    }
  )
}

# create database subnets

resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  cidr_block = var.database_subnet_cidrs[count.index]

  availability_zone = local.az_names[count.index]

  tags = merge(
    var.database_subnet_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-database-${local.az_names[count.index]}"
    }
  )
}

# create elastic ip (eip)

resource "aws_eip" "nat" {
  domain   = "vpc"

  tags = merge(
    var.eip_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}"
    }
  )
}


# create nat gateway and attach eip

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id  # here we are taking 1a as we mostly use 1a region

  tags = merge(
    var.nat_gateway_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}"
    }
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}

# create public route tables

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id # Reference to your VPC ID
  
  tags = merge(
    var.public_route_table_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-public"
    }
  )
}

# adding internet as route through IGW

resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"   # as it is public we are giving internet cidr
  gateway_id                = aws_internet_gateway.main.id   # internet gateway (IGW)
}

# attaching to public-1a and public-1b (route table association)

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# create private route tables

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id # Reference to your VPC ID
  
  tags = merge(
    var.private_route_table_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-private"
    }
  )
}

# adding egress internet (outbound traffic) as route through NAT

resource "aws_route" "private" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"   # as it is private we are giving outgoing internet cidr through NAT
  gateway_id                = aws_nat_gateway.main.id   # NAT gateway (NAT)
}

# attaching to private-1a and private-1b (route table association)

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}


# create database route tables (which is also private)

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id # Reference to your VPC ID
  
  tags = merge(
    var.database_route_table_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-database"
    }
  )
}

# adding egress internet (outbound traffic) as route through NAT

resource "aws_route" "database" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"   # as it is private we are giving outgoing internet cidr through NAT
  gateway_id                = aws_nat_gateway.main.id   # NAT gateway (NAT)
}

# attaching to database-1a and database-1b (route table association)

resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

