variable "region" {
  description = "region to deploy resources to"
  type        = string
  default     = "us-east-2"
}

variable "availability_zones" {
  description = "List of availability zones whre our subnets will reside in"
  type = list(string)
  default = [ "us-east-2a", "us-east-2b", "us-east-2c" ]
}

variable "vpc_cidr_blocks" {
  description = "list of CIDR ranges for our different VPCs"
  type        = list(string)
  default     = ["120.0.0.0/16", "150.0.0.0/16", "180.0.0.0/16"]
}

variable "vpc_tags" {
  description = "List of name tags for our VPCs"
  type = list(string)
  default = [ "fonsah-vpc-1", "fonsah-vpc-2", "fonsah-vpc-3"  ]
}

variable "subnet_suffixes" {
  description = "list of names for our subnets"
  type = list(string)
  default = [ "fonsah-SN-1", "fonsah-SN-2"]
}