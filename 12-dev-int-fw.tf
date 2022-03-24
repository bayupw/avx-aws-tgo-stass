# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix AWS Security VPC | dev-int-fw
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_vpc" "dev_int_fw_vpc" {
  cloud_type           = 1
  account_name         = var.aws_account
  region               = var.aws_region
  name                 = "stass-dev-int-fw"
  cidr                 = var.vpc_cidr.dev_int_fw_vpc
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Transit Firenet Gateway | dev-int-fw-gw
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_transit_gateway" "dev_int_fw_gw" {
  cloud_type   = 1
  account_name = var.aws_account
  gw_name      = "dev-int-fw-gw"
  vpc_id       = aviatrix_vpc.dev_int_fw_vpc.vpc_id
  vpc_reg      = var.aws_region
  gw_size      = "c5.xlarge"
  subnet       = aviatrix_vpc.dev_int_fw_vpc.public_subnets[0].cidr
  #ha_subnet                = aviatrix_vpc.dev_transit_vpc.public_subnets[1].cidr
  #ha_gw_size               = "t2.micro"
  enable_hybrid_connection = true
  connected_transit        = true
  single_az_ha             = false
  enable_active_mesh       = true
  enable_firenet           = true

  depends_on = [aviatrix_vpc.dev_int_fw_vpc]
}

# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Transit Firenet Gateway Attachment
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_aws_tgw_vpc_attachment" "dev_firenet_tgw_attachment" {
  tgw_name             = aviatrix_aws_tgw.dev_tgw.tgw_name
  region               = var.aws_region
  security_domain_name = aviatrix_aws_tgw_security_domain.dev_firewall_domain["InternalFirewall"].name
  vpc_account_name     = var.aws_account
  vpc_id               = aviatrix_vpc.dev_int_fw_vpc.vpc_id
  depends_on           = [aviatrix_transit_gateway.dev_int_fw_gw, aviatrix_aws_tgw_security_domain_connection.dev_default_connections, aviatrix_aws_tgw_transit_gateway_attachment.dev_tgw_to_dev_gw_attachment]
}

# ---------------------------------------------------------------------------------------------------------------------
# Launch Firewall
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_firewall_instance" "dev_int_fw_instance" {
  vpc_id          = aviatrix_vpc.dev_int_fw_vpc.vpc_id
  firenet_gw_name = aviatrix_transit_gateway.dev_int_fw_gw.gw_name
  firewall_name   = "stass-dev-int-fw-instance-1"
  firewall_image  = "Fortinet FortiGate Next-Generation Firewall"
  firewall_size   = "t2.small"
  egress_subnet   = aviatrix_vpc.dev_int_fw_vpc.subnets[1].cidr
  #iam_role              = module.fortigate_bootstrap.aws_iam_role.name
  #bootstrap_bucket_name = module.fortigate_bootstrap.aws_s3_bucket.bucket
  #user_data  = local.dev_int_fw_init_conf
  user_data = templatefile("${path.module}/init.conf.tmpl",
    {
      "fw_admin_password" = var.fw_admin_password,
      "lan_gw_ip"         = cidrhost(aviatrix_transit_gateway.dev_int_fw_gw.lan_interface_cidr, 1)
    }
  )
  depends_on = [aviatrix_transit_gateway.dev_int_fw_gw]
}

# Associate an Aviatrix FireNet Gateway with a Firewall Instance
resource "aviatrix_firewall_instance_association" "dev_int_fw_instance_assoc" {
  vpc_id          = aviatrix_firewall_instance.dev_int_fw_instance.vpc_id
  firenet_gw_name = aviatrix_transit_gateway.dev_int_fw_gw.gw_name
  instance_id     = aviatrix_firewall_instance.dev_int_fw_instance.instance_id
  firewall_name   = aviatrix_firewall_instance.dev_int_fw_instance.firewall_name
  lan_interface   = aviatrix_firewall_instance.dev_int_fw_instance.lan_interface
  #management_interface = aviatrix_firewall_instance.dev_int_fw_instance.management_interface
  egress_interface = aviatrix_firewall_instance.dev_int_fw_instance.egress_interface
  attached         = true
}

# Create an Aviatrix FireNet
resource "aviatrix_firenet" "dev_int_fw_firenet" {
  vpc_id                               = aviatrix_firewall_instance.dev_int_fw_instance.vpc_id
  inspection_enabled                   = true
  egress_enabled                       = false
  keep_alive_via_lan_interface_enabled = false
  manage_firewall_instance_association = false
  depends_on                           = [aviatrix_firewall_instance_association.dev_int_fw_instance_assoc]
}