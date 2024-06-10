locals {
  vpc_map = { for idx in range(1, length(var.vpc_cidr_blocks) + 1) : idx => { cidr = var.vpc_cidr_blocks[idx - 1], name = var.vpc_tags[idx - 1] } }

  subnets = flatten([
    for vpc_idx in range(1, length(var.vpc_cidr_blocks) + 1) : [
      for az_idx in range(0, length(var.availability_zones)) : {
        vpc_idx  = vpc_idx
        vpc_id   = aws_vpc.fonsah_vpc[vpc_idx].id
        az       = var.availability_zones[az_idx]
        suffix   = var.subnet_suffixes[az_idx]
        vpc_cidr = var.vpc_cidr_blocks[vpc_idx - 1]
      }
    ]
  ])
}

resource "aws_vpc" "fonsah_vpc" {
  for_each   = local.vpc_map
  cidr_block = each.value.cidr

  tags = {
    Name = "fonsah-${each.value.name}"
  }
}

resource "aws_internet_gateway" "fonsah_ig" {
  vpc_id = aws_vpc.fonsah_vpc[1].id

  tags = {
    Name = var.ig_tag
  }
}

resource "aws_subnet" "fonsah_subnet" {
  for_each = {
    for subnet in local.subnets : "${subnet.vpc_idx}-${subnet.suffix}" => subnet
  }

  vpc_id            = each.value.vpc_id
  cidr_block        = cidrsubnet(each.value.vpc_cidr, 8, index(var.availability_zones, each.value.az) * length(var.subnet_suffixes) + index(var.subnet_suffixes, each.value.suffix))
  availability_zone = each.value.az

  tags = {
    Name = "fonsah-SN-${each.key}"
  }
}

resource "aws_route_table" "fonsah_rt" {
  for_each = aws_subnet.fonsah_subnet

  vpc_id = each.value.vpc_id

  tags = merge(var.rt_tags, {
    Name = "fonsah-RT-${each.key}"
  })
}

resource "aws_route" "fonsah_route" {
  count = 1
  route_table_id = element([for rt in aws_route_table.fonsah_rt : rt.id if rt.vpc_id == aws_vpc.fonsah_vpc[1].id], 0)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.fonsah_ig.id
}

resource "aws_route_table_association" "fonsah_associate_rt" {
  for_each = aws_subnet.fonsah_subnet

  subnet_id = each.value.id
  route_table_id = aws_route_table.fonsah_rt[each.key].id
}

resource "aws_eip" "fonsah_eip" {
  tags = {
    Name = var.eip_tag
  }
}

resource "aws_nat_gateway" "fonsah_nat_gw" {
  depends_on = [ aws_internet_gateway.fonsah_ig ]
  allocation_id = aws_eip.fonsah_eip.id
  subnet_id     = aws_subnet.fonsah_subnet["1-a"].id
  tags = {
    Name = var.nat_tag
  }
}

resource "aws_route" "fonsat_nat_route" {
  route_table_id = aws_route_table.fonsah_rt["1-b"].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.fonsah_nat_gw.id
  depends_on = [aws_nat_gateway.fonsah_nat_gw]
}