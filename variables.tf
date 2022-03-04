# ---------------------------------------------------------------------------------------------------------------------
# CIDR
# ---------------------------------------------------------------------------------------------------------------------
# Subnetting
locals {
  stass_transit_vpc = "172.20.174.0/23"
  sta_transit_vpc   = "172.20.176.0/23"
  dev_transit_vpc   = "172.20.178.0/23"
}

variable "tgw_domains" {
  description = "Default Domain Name"
  default = [
    "Default_Domain",
    "Shared_Service_Domain",
    "Aviatrix_Edge_Domain"
  ]
}

locals {
  #Create connections based on var.tgw_domains
  connections = flatten([
    for domain in var.tgw_domains : [
      for connected_domain in slice(var.tgw_domains, index(var.tgw_domains, domain) + 1, length(var.tgw_domains)) : {
        domain1 = domain
        domain2 = connected_domain
      }
    ]
  ])

  #Create map to be used in for_each
  connections_map = {
    for connection in local.connections : "${connection.domain1}:${connection.domain2}" => connection
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CSP Accounts
# ---------------------------------------------------------------------------------------------------------------------
variable "aws_account" {
  type        = string
  description = "AWS access account"
}

# ---------------------------------------------------------------------------------------------------------------------
# CSP Regions
# ---------------------------------------------------------------------------------------------------------------------
variable "aws_region" {
  type        = string
  default     = "ap-southeast-2"
  description = "AWS region"
}

# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Transit & Spoke Gateway
# ---------------------------------------------------------------------------------------------------------------------
variable "aws_instance_size" {
  type        = string
  default     = "t2.micro" #hpe "c5.xlarge"
  description = "AWS gateway instance size"
}

# ---------------------------------------------------------------------------------------------------------------------
# AWS EC2
# ---------------------------------------------------------------------------------------------------------------------
variable "create_ec2" {
  type        = bool
  default     = false
  description = "Create EC2 instance"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "amzn2-ami-hvm*"
}

variable "key_name" {
  type        = string
  default     = null
  description = "Existing SSH public key name"
}