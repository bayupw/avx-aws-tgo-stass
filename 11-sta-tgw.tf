# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix AWS VPC | sta-transit
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_vpc" "sta_transit_vpc" {
  cloud_type           = 1
  account_name         = var.aws_account
  region               = var.aws_region
  name                 = "sta-transit"
  cidr                 = var.vpc_cidr.sta_transit_vpc
  aviatrix_transit_vpc = true
  aviatrix_firenet_vpc = false
}

# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Transit Gateway | sta-gw
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_transit_gateway" "sta_gw" {
  cloud_type   = 1
  account_name = var.aws_account
  gw_name      = "sta-gw"
  vpc_id       = aviatrix_vpc.sta_transit_vpc.vpc_id
  vpc_reg      = var.aws_region
  gw_size      = "t2.micro"
  subnet       = aviatrix_vpc.sta_transit_vpc.public_subnets[0].cidr
  #ha_subnet                = aviatrix_vpc.sta_transit_vpc.public_subnets[1].cidr
  #ha_gw_size               = "t2.micro"
  enable_hybrid_connection = true
  connected_transit        = true
  single_az_ha             = false
  enable_active_mesh       = true

  tags = {
    Organization = "Production"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Managed AWS TGW | sta-tgw
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_aws_tgw" "sta_tgw" {
  account_name                      = var.aws_account
  aws_side_as_number                = "65521"
  manage_vpc_attachment             = false
  manage_transit_gateway_attachment = false
  manage_security_domain            = false
  region                            = var.aws_region
  tgw_name                          = "sta-tgw"
}

# Create Security Domains based on var.tgw_domains
resource "aviatrix_aws_tgw_security_domain" "sta_default_domains" {
  for_each = toset(var.tgw_domains)
  name     = each.value
  tgw_name = aviatrix_aws_tgw.sta_tgw.tgw_name
    depends_on   = [aviatrix_aws_tgw.sta_tgw]
}

# Create Security Domain Connections
resource "aviatrix_aws_tgw_security_domain_connection" "sta_default_connections" {
  for_each     = local.connections_map
  tgw_name     = aviatrix_aws_tgw.sta_tgw.tgw_name
  domain_name1 = each.value.domain1
  domain_name2 = each.value.domain2
  depends_on   = [aviatrix_aws_tgw_security_domain.sta_default_domains]
}

# sta-tgw to sta-gw attachment
resource "aviatrix_aws_tgw_transit_gateway_attachment" "sta_tgw_to_sta_gw_attachment" {
  tgw_name             = aviatrix_aws_tgw.sta_tgw.tgw_name
  region               = var.aws_region
  vpc_account_name     = var.aws_account
  vpc_id               = aviatrix_vpc.sta_transit_vpc.vpc_id
  transit_gateway_name = aviatrix_transit_gateway.sta_gw.gw_name
  depends_on = [aviatrix_transit_gateway.sta_gw, aviatrix_aws_tgw.sta_tgw,aviatrix_aws_tgw_security_domain_connection.sta_default_connections]
}