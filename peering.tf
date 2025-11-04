# creating peering connection between roboshop-dev vpc and default vpc

resource "aws_vpc_peering_connection" "default" {
  peer_vpc_id   = data.aws_vpc.default.id  # acceptor vpc which is default here
  vpc_id        = aws_vpc.main.id  # requestor

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  auto_accept = true

  tags = merge(
    var.vpc_peering_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-default"
    }
  )
}

# adding routes with destination of default vpc CIDR in roboshop route tables (public, private, database) routes
# we will add routes in only required route tables

resource "aws_route" "public_peering" {
  count = var.is_peering_required ? 1 : 0
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}

resource "aws_route" "private_peering" {
  count = var.is_peering_required ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}

resource "aws_route" "database_peering" {
  count = var.is_peering_required ? 1 : 0
  route_table_id         = aws_route_table.database.id
  destination_cidr_block = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}

# we must add peering connection in default vpc main route table too

resource "aws_route" "default_peering" {
  count = var.is_peering_required ? 1 : 0
  route_table_id         = data.aws_route_table.main.id
  destination_cidr_block = var.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}