locals {
  vpc_map = { for idx in range(1, length(var.vpc_cidr_blocks) + 1) : idx => { cidr = var.vpc_cidr_blocks[idx - 1], name = var.vpc_tags[idx - 1] } }

  subnets = flatten([
    for vpc_idx in range(1, length(var.vpc_cidr_blocks) + 1) : [
      for az_idx in range(0, 2) : {
        vpc_idx = vpc_idx
        vpc_id  = aws_vpc.fonsah-vpc[vpc_idx].id
        az      = var.availability_zones[az_idx]
        suffix  = var.subnet_suffixes[az_idx]
        vpc_cidr = var.vpc_cidr_blocks[vpc_idx - 1]
      }
    ]
  ])
}

resource "aws_vpc" "fonsah-vpc" {
  for_each   = local.vpc_map
  cidr_block = each.value.cidr

  tags = {
    Name = "fonsah-${each.value.name}"
  }
}

resource "aws_subnet" "fonsah-subnet" {
  for_each = {
    for subnet in local.subnets : "${subnet.vpc_idx}-${subnet.az}-${subnet.suffix}" => subnet
  }

  vpc_id            = each.value.vpc_id
  cidr_block        = cidrsubnet(each.value.vpc_cidr, 8, index(var.availability_zones, each.value.az) * length(var.subnet_suffixes) + index(var.subnet_suffixes, each.value.suffix))
  availability_zone = each.value.az

  tags = {
    Name = "fonsah-SN-${each.value.suffix}"
  }
}
