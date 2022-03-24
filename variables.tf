# ---------------------------------------------------------------------------------------------------------------------
# CIDR
# ---------------------------------------------------------------------------------------------------------------------

variable "vpc_cidr" {
  type = map(string)
  default = {
    stass_transit_vpc = "172.22.174.0/23"

    sta_transit_vpc = "172.22.176.0/23"

    dev_transit_vpc    = "172.22.178.0/23"
    dev_int_fw_vpc     = "172.22.40.0/23"
    dev_ext_fw_vpc     = "172.22.42.0/23"
    dev_banking_vpc    = "172.22.0.0/23"
    dev_it_service_vpc = "172.22.38.0/23"

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
  default     = "ap-east-1"
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

variable "fw_admin_password" {
  type        = string
  default     = "Aviatrix123#"
  description = "Firewall admin password"
}

variable "instance_username" {
  type        = string
  default     = "ec2-user"
  description = "Instance username"
}

variable "instance_password" {
  type        = string
  default     = "Aviatrix123#"
  description = "Instance password"
}

variable "ingress_ip" {
  type        = string
  default     = "0.0.0.0/0"
  description = "Ingress CIDR block for EC2 Security Group"
}

# ---------------------------------------------------------------------------------------------------------------------
# TGW
# ---------------------------------------------------------------------------------------------------------------------

variable "mandatory_domains" {
  type        = list(any)
  description = "Default Domain Name"
  default     = ["Default_Domain", "Shared_Service_Domain", "Aviatrix_Edge_Domain"]
}

variable "custom_security_domains" {
  type        = list(any)
  description = "Custom Domain Names"
  default     = null
}

variable "firewall_security_domains" {
  type        = list(any)
  description = "Firewall Domain Names"
  default     = ["InternalFirewall", "ExternalFirewall"]
}

locals {
  rfc1918             = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  ingress_cidr_blocks = concat(local.rfc1918, [var.ingress_ip])

  #Create connections based on var.tgw_domains
  connections = flatten([
    for domain in var.mandatory_domains : [
      for connected_domain in slice(var.mandatory_domains, index(var.mandatory_domains, domain) + 1, length(var.mandatory_domains)) : {
        domain1 = domain
        domain2 = connected_domain
      }
    ]
  ])

  #Create map to be used in for_each
  connections_map = {
    for connection in local.connections : "${connection.domain1}:${connection.domain2}" => connection
  }

  fw_domains = concat(var.mandatory_domains, var.firewall_security_domains)

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
}