# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix AWS VPC | stass-transit
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_vpc" "stass_transit_vpc" {
  cloud_type           = 1
  account_name         = var.aws_account
  region               = var.aws_region
  name                 = "stass-transit"
  cidr                 = var.vpc_cidr.stass_transit_vpc
  aviatrix_transit_vpc = true
  aviatrix_firenet_vpc = false
}

# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Transit Gateway | stass-gw
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_transit_gateway" "stass_gw" {
  cloud_type   = 1
  account_name = var.aws_account
  gw_name      = "stass-gw"
  vpc_id       = aviatrix_vpc.stass_transit_vpc.vpc_id
  vpc_reg      = var.aws_region
  gw_size      = "t2.micro"
  subnet       = aviatrix_vpc.stass_transit_vpc.public_subnets[0].cidr
  #ha_subnet                = aviatrix_vpc.stass_transit_vpc.public_subnets[1].cidr
  #ha_gw_size               = "t2.micro"
  enable_hybrid_connection      = true
  connected_transit             = true
  single_az_ha                  = false
  local_as_number               = "65521"
  enable_active_mesh            = true
  enable_learned_cidrs_approval = true

  tags = {
    Organization = "Staging Shared-Services"
  }
}
/* 
# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Managed AWS TGW | stass-tgw
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_aws_tgw" "stass_tgw" {
  account_name                      = var.aws_account
  aws_side_as_number                = "65510"
  manage_vpc_attachment             = false
  manage_transit_gateway_attachment = false
  manage_security_domain            = false
  region                            = var.aws_region
  tgw_name                          = "stass-tgw"
}

# Create Security Domains based on var.tgw_domains
resource "aviatrix_aws_tgw_security_domain" "stass_default_domains" {
  for_each   = toset(var.tgw_domains)
  name       = each.value
  tgw_name   = aviatrix_aws_tgw.stass_tgw.tgw_name
  depends_on = [aviatrix_aws_tgw.stass_tgw]
}

# Create Security Domain Connections
resource "aviatrix_aws_tgw_security_domain_connection" "stass_default_connections" {
  for_each     = local.connections_map
  tgw_name     = aviatrix_aws_tgw.stass_tgw.tgw_name
  domain_name1 = each.value.domain1
  domain_name2 = each.value.domain2
  depends_on   = [aviatrix_aws_tgw_security_domain.stass_default_domains]
}

# ss-tgw to ss-gw attachment
resource "aviatrix_aws_tgw_transit_gateway_attachment" "stass_tgw_to_stass_gw_attachment" {
  tgw_name             = aviatrix_aws_tgw.stass_tgw.tgw_name
  region               = var.aws_region
  vpc_account_name     = var.aws_account
  vpc_id               = aviatrix_vpc.stass_transit_vpc.vpc_id
  transit_gateway_name = aviatrix_transit_gateway.stass_gw.gw_name
  depends_on           = [aviatrix_transit_gateway.stass_gw, aviatrix_aws_tgw.stass_tgw, aviatrix_aws_tgw_security_domain_connection.stass_default_connections]
} */