# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix AWS Security VPC | dev-firenet
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_vpc" "dev_firenet_vpc" {
  cloud_type           = 1
  account_name         = var.aws_account
  region               = var.aws_region
  name                 = "dev-firenet"
  cidr                 = local.dev_transit_vpc
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Firewall Security Domain | dev-firenet
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_aws_tgw_security_domain" "firenet_sec_domain" {
  name              = "East-West-Firewall"
  tgw_name          = aviatrix_aws_tgw.dev_tgw.tgw_name
  aviatrix_firewall = true
  depends_on   = [aviatrix_aws_tgw_security_domain.dev_default_domains]
}

# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Transit Firenet Gateway | dev-fw-gw
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_transit_gateway" "dev_fw_gw" {
  cloud_type   = 1
  account_name = var.aws_account
  gw_name      = "dev-fw-gw"
  vpc_id       = aviatrix_vpc.dev_firenet_vpc.vpc_id
  vpc_reg      = var.aws_region
  gw_size      = "c5.xlarge"
  subnet       = aviatrix_vpc.dev_transit_vpc.public_subnets[0].cidr
  #ha_subnet                = aviatrix_vpc.dev_transit_vpc.public_subnets[1].cidr
  #ha_gw_size               = "t2.micro"
  enable_hybrid_connection = true
  connected_transit        = true
  single_az_ha             = false
  enable_active_mesh       = true
  enable_firenet           = true

  tags = {
    Organization = "Development"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Transit Firenet Gateway | dev-fw-gw
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_aws_tgw_vpc_attachment" "firenet_tgw_attachment" {
  tgw_name             = aviatrix_aws_tgw.dev_tgw.tgw_name
  region               = var.aws_region
  security_domain_name = aviatrix_aws_tgw_security_domain.firenet_sec_domain.name
  vpc_account_name     = var.aws_account
  vpc_id               = aviatrix_vpc.dev_firenet_vpc.vpc_id
}

# ---------------------------------------------------------------------------------------------------------------------
# Launch Firewall
# ---------------------------------------------------------------------------------------------------------------------
/* resource "aviatrix_firewall_instance" "ew_firewall_instance" {
  vpc_id            = aviatrix_vpc.dev_firenet_vpc.vpc_id
  firenet_gw_name   = aviatrix_transit_gateway.dev_fw_gw.gw_name
  firewall_name     = "ew-fortigate-instance"
  firewall_image    = "Fortinet FortiGate Next-Generation Firewall"
  firewall_size     = "m5.xlarge"
  management_subnet = "10.4.0.16/28"
  egress_subnet     = "10.4.0.32/28"
} */