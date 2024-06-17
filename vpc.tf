locals {
  vpc_map = { for idx in range(1, length(var.vpc_cidr_blocks) + 1) : idx => { cidr = var.vpc_cidr_blocks[idx - 1], name = var.vpc_tags[idx - 1] } }

  vpc_id_to_key = {
    for key, vpc in aws_vpc.fonsah_vpc : vpc.id => key
  }

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

# VPCs
resource "aws_vpc" "fonsah_vpc" {
  for_each   = local.vpc_map
  cidr_block = each.value.cidr

  tags = {
    Name = "fonsah-${each.value.name}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "fonsah_ig" {
  vpc_id = aws_vpc.fonsah_vpc[1].id

  tags = {
    Name = var.ig_tag
  }
}

# Subnets
resource "aws_subnet" "fonsah_subnet" {
  for_each = {
    for subnet in local.subnets : "${subnet.vpc_idx}${subnet.suffix}" => subnet
  }

  vpc_id            = each.value.vpc_id
  cidr_block        = cidrsubnet(each.value.vpc_cidr, 8, index(var.availability_zones, each.value.az) * length(var.subnet_suffixes) + index(var.subnet_suffixes, each.value.suffix))
  availability_zone = each.value.az
  map_public_ip_on_launch = each.key == "1a"

  tags = {
    Name = "fonsah-SN-${each.key}"
  }
}

# route tables
resource "aws_route_table" "fonsah_rt" {
  for_each = local.vpc_map

  vpc_id = aws_vpc.fonsah_vpc[each.key].id

  tags = merge(var.rt_tags, {
    Name = "fonsah-RT-${each.key}"
  })
}

# NAT Gateway route table
resource "aws_route_table" "fonsah_nat_rt" {
  vpc_id = aws_vpc.fonsah_vpc[1].id

  tags = {
    Name = var.nat_rt_tag
  }
}

# routes
# VPC routes
resource "aws_route" "fonsah_route" {
  count = 1
  route_table_id = element([for rt in aws_route_table.fonsah_rt : rt.id if rt.vpc_id == aws_vpc.fonsah_vpc[1].id], 0)
  # route_table_id = aws_route_table.fonsah_rt[1].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.fonsah_ig.id
}

# NAT Gateway Route
resource "aws_route" "fonsat_nat_route" {
  count = 1
  route_table_id = aws_route_table.fonsah_nat_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.fonsah_nat_gw.id
  depends_on = [aws_nat_gateway.fonsah_nat_gw]
}

# route table associations
resource "aws_route_table_association" "fonsah_associate_rt" {
  for_each = aws_subnet.fonsah_subnet

  subnet_id = each.value.id
  route_table_id = aws_route_table.fonsah_rt[local.vpc_id_to_key[each.value.vpc_id]].id
}

# NAT Gateway route table associations
resource "aws_route_table_association" "fonsah_associate_nat_rt" {
  count = length(var.availability_zones)
  subnet_id = element([for subnet in aws_subnet.fonsah_subnet : subnet.id if substr(subnet.availability_zone, -1, 1) == "b"], count.index)
  route_table_id = aws_route_table.fonsah_nat_rt.id
}

# elastic IP
resource "aws_eip" "fonsah_eip" {
  tags = {
    Name = var.eip_tag
  }
}

# NAT Gateway
resource "aws_nat_gateway" "fonsah_nat_gw" {
  depends_on = [ aws_internet_gateway.fonsah_ig ]
  allocation_id = aws_eip.fonsah_eip.id
  subnet_id     = aws_subnet.fonsah_subnet["1a"].id
  tags = {
    Name = var.nat_tag
  }
}

# Flow logs role
resource "aws_iam_role" "fonsah_role" {
  name = var.iam_role_name
  assume_role_policy = jsonencode({
    Version: "2012-10-17"
    Statement: [
      {
        Effect: "Allow",
        Principal: {
          Service: "vpc-flow-logs.amazonaws.com"
        },
        Action: "sts:AssumeRole"
      },
    ]
  })
}

# flow logs role policy
resource "aws_iam_role_policy" "fonsah_policy" {
  name = var.iam_policy_name
  role = aws_iam_role.fonsah_role.id
  policy = jsonencode({
    Version: "2012-10-17"
    Statement: [
      {
        Effect: "Allow",
        Action: [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource: "*"
      }
    ]
  })
}

# cloudwatch log group
resource "aws_cloudwatch_log_group" "fonsah_log_group" {
  name = var.log_group_name
  retention_in_days = var.log_retention_period
}

resource "aws_flow_log" "fonsah_flow_log" {
  vpc_id = aws_vpc.fonsah_vpc[1].id

  log_destination = "arn:aws:logs:${var.region}:${var.account_id}:log-group:${var.log_group_name}"
  traffic_type = "ALL"
  iam_role_arn = aws_iam_role.fonsah_role.arn
  depends_on = [ aws_iam_role.fonsah_role ]

  tags = {
    Name = var.flow_log_name
  }
}

# S3 endpoint
resource "aws_vpc_endpoint" "fonsah_s3_endpoint" {
  vpc_id = aws_vpc.fonsah_vpc["1"].id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [for rt in aws_route_table.fonsah_rt : rt.id if rt.vpc_id == aws_vpc.fonsah_vpc["1"].id]

  tags = {
    Name = var.endpoint_name
  }
}