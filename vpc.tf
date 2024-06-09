resource "aws_vpc" "fonsah-vpc" {
  for_each   = { for idx, cidr in zip(var.vpc_cidr_blocks, var.vpc_tags) : idx => cidr }
  cidr_block = each.value

  tags = {
    Name = "fonsah-vpc-${each.key}"
  }
}

locals {
  subnets = flatten([
    for vpc_idx, vpc_cidr in var.vpc_cidr_blocks : [
      for az in var.availability_zones : [
        for suffix in var.subnet_suffixes : {
          vpc_idx  = vpc_idx
          vpc_id   = aws_vpc.fonsah_vpc[vpc_idx].id
          az       = az
          suffix   = suffix
          vpc_cidr = vpc_cidr
        }
      ]
    ]
  ])
}

resource "aws_subnet" "fonsah-subnet" {
  for_each = {
    for subnet in local.subnets : "${subnet.vpc_idx}-${subnet.az}-${subnet.suffix}" => subnet
  }

  vpc_id            = each.value.vpc_id
  cidr_block        = cidrsubnet(each.value.vpc_cidr, 8, index(var.availability_zones, each.value.az) * length(var.subnet_suffixes) + index(var.subnet_suffixes, each.value.suffix))
  availability_zone = each.value.az

  tags = {
    Name = "fonsah-subnet-${each.key}"
  }
}
