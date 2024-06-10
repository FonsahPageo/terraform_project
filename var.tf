variable "region" {
  description = "region to deploy resources to"
  type        = string
  default     = "us-east-2"
}

variable "availability_zones" {
  description = "List of availability zones whre our subnets will reside in"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "vpc_cidr_blocks" {
  description = "list of CIDR ranges for our different VPCs"
  type        = list(string)
  default     = ["120.0.0.0/16", "150.0.0.0/16", "180.0.0.0/16"]
}

variable "vpc_tags" {
  description = "List of name tags for our VPCs"
  type        = list(string)
  default     = ["vpc-1", "vpc-2", "vpc-3"]
}

variable "subnet_suffixes" {
  description = "list of suffixes for our subnets"
  type        = list(string)
  default     = ["a", "b"]
}

variable "ig_tag" {
  description = "tag for our internet gateway"
  type        = string
  default     = "fonsah-IG"
}

variable "rt_tags" {
  description = "tags for our route tables"
  type        = map(any)
  default = {
    Name = "fonsah-RT"
  }
}

variable "eip_tag" {
  description = "tag for our elastip IP address"
  type        = string
  default     = "fonsah-EIP"
}

variable "nat_tag" {
  description = "tag for our NAT Gateway"
  type        = string
  default     = "fonsah-NAT-GW"
}

variable "account_id" {
  description = "AWS account ID"
  type        = number
  default     = "869227219142"
}

variable "log_group_name" {
  description = "name of our CloudWatch Log Group"
  type        = string
  default     = "fonsah-project-log-group"
}

variable "log_retention_period" {
  description = "retention period in days for logs"
  type        = number
  default     = 30
}

variable "role_name" {
  description = "name of the IAM role to deliver VPC logs to CloudWatch"
  type        = string
  default     = "FonsahVPCFLowLogRule"
}

variable "instance_tag" {
  description = "name of the instance to be launched"
  type        = string
  default     = "fonsah-demo"
}

# variable "ami_id" {
#   description = "AMI ID for the instance to be launched"
#   type        = string
#   default     = "value"
# }

variable "sg_tag" {
  description = "name of our security group"
  type        = string
  default     = "fonsah-project-SG"
}

variable "sg_ingress_rules" {
  description = "defining the ingress rules of the security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "ssh"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "sg_egress_rules" {
  description = "defining the ingress rules of the security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/16" ]
    }
  ]
}

variable "instance_type" {
  description = "the type of server we want to launch"
  type = string
  default = "t2.micro"
}

variable "key_name" {
  description = "the key pair to connect to the instance"
  type = string
  default = "fonsah_chamberlain_ohio"
}