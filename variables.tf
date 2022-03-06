# ---------------------------------------------------------------------------------------------------------------------
# CIDR
# ---------------------------------------------------------------------------------------------------------------------

variable "vpc_cidr" {
  type = map(string)
  default = {
    stass_transit_vpc = "172.20.174.0/23"
    sta_transit_vpc   = "172.20.176.0/23"
    stass_transit_vpc = "172.20.174.0/23"
    dev_transit_vpc   = "172.20.178.0/23"
    dev_firenet_vpc   = "172.20.180.0/23"
    dev_spoke1_vpc    = "172.18.12.0/23"
    dev_spoke2_vpc    = "172.18.14.0/23"
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
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "amzn2-ami-hvm*"
}
variable "create_ec2" {
  type        = bool
  default     = false
  description = "Create EC2 instance"
}

variable "key_name" {
  type        = string
  default     = null
  description = "Existing SSH public key name"
}

variable "admin_password" {
  type        = string
  default     = "Aviatrix123#"
  description = "Admin password for Firewall"
}


# ---------------------------------------------------------------------------------------------------------------------
# TGW
# ---------------------------------------------------------------------------------------------------------------------

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

  fw_domains = concat(var.tgw_domains, ["Firewall"])

  #Create connections based on local.fw_domains
  fw_connections = flatten([
    for domain in local.fw_domains : [
      for connected_domain in slice(local.fw_domains, index(local.fw_domains, domain) + 1, length(local.fw_domains)) : {
        domain1 = domain
        domain2 = connected_domain
      }
    ]
  ])

  #Create map to be used in for_each
  fw_connections_map = {
    for connection in local.fw_connections : "${connection.domain1}:${connection.domain2}" => connection
  }

  # Fortigate boostrap config
  init_conf = <<EOF
config system admin
    edit admin
        set password ${var.admin_password}
end
config system global
    set hostname fg
    set timezone 04
end
config firewall policy
    edit 1
        set name allow_all
        set srcintf port2
        set dstintf port2
        set srcaddr all
        set dstaddr all
        set action accept
        set schedule always
        set service ALL
    next
end
EOF
}