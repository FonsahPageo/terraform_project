resource "aws_security_group" "fonsah_sg" {
  for_each = local.vpc_map

  name   = "fonsah-project-SG"
  vpc_id = aws_vpc.fonsah_vpc[each.key].id

  dynamic "ingress" {
    for_each = var.sg_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.sg_egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
  tags = merge(var.sg_tag, {
    Name = "fonsah-SG-${each.key}"
  })
}

data "aws_ami" "fonsah_ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "fonsah_instance" {
  for_each = aws_subnet.fonsah_subnet

  ami           = data.aws_ami.fonsah_ubuntu.id
  instance_type = var.instance_type
  key_name      = var.instance_key
  subnet_id     = each.value.id
  vpc_security_group_ids = [
    aws_security_group.fonsah_sg[local.vpc_id_to_key[each.value.vpc_id]].id
  ]

  tags = {
    Name = "fonsah-server-${each.key}"
  }
}
