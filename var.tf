variable "region" {
  description = "region to deploy resources to"
  type        = string
  default     = "us-east-2"
}

variable "availability_zones" {
  description = "List of availability zones whre our subnets will reside in"
  type = list(string)
  default = [ "us-east-2a", "us-east-2b"]
}

variable "vpc_cidr_blocks" {
  description = "list of CIDR ranges for our different VPCs"
  type        = list(string)
  default     = ["120.0.0.0/16", "150.0.0.0/16", "180.0.0.0/16"]
}

variable "vpc_tags" {
  description = "List of name tags for our VPCs"
  type = list(string)
  default = [ "vpc-1", "vpc-2", "vpc-3"  ]
}

variable "subnet_suffixes" {
  description = "list of suffixes for our subnets"
  type = list(string)
  default = [ "a", "b"]
}

variable "ig_tag" {
  description = "tag for our internet gateway"
  type = string
  default = "fonsah-IG"
}

variable "rt_tags" {
  description = "tags for our route tables"
  type = map(any)
  default = {
    Name = "fonsah-RT"
  }
}