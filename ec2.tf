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
  tags = merge(var.sg_tag,{
    Name = "fonsah-SG-${each.key}"
  })
}

data "aws_ami" "ubuntu" {
  most_recent = true
}

resource "aws_instance" "fonsah_instance" {
  for_each = aws_subnet.fonsah_subnet

  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name
  subnet_id = each.value.id
  
  tags = {
    Name = "fonsah-server-${each.key}"
  }
}
