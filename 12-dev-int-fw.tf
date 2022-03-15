locals {
  # Dev Fortigate Firewall bootstrap config
  dev_fw_init_conf = <<EOF
config system admin
    edit admin
        set password ${var.fw_admin_password}
end
config system global
    set hostname fg
    set timezone 04
end
config system interface
    edit port2
    set allowaccess ping https
end
config router static
    edit 1
        set dst 10.0.0.0 255.0.0.0
        set gateway ${cidrhost(aviatrix_transit_gateway.dev_int_fw_gw.lan_interface_cidr, 1)}
        set device port2
    next
    edit 2
        set dst 172.16.0.0 255.240.0.0
        set gateway ${cidrhost(aviatrix_transit_gateway.dev_int_fw_gw.lan_interface_cidr, 1)}
        set device port2
    next
    edit 3
        set dst 192.168.0.0 255.255.0.0
        set gateway ${cidrhost(aviatrix_transit_gateway.dev_int_fw_gw.lan_interface_cidr, 1)}
        set device port2
    next
end
config firewall policy
    edit 1
        set name allow-all-LAN-to-LAN
        set srcintf port2
        set dstintf port2
        set srcaddr all
        set dstaddr all
        set action accept
        set schedule always
        set service ALL
        set logtraffic all
        set logtraffic-start enable
    next
end
EOF
}
# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix AWS Security VPC | dev-int-fw
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_vpc" "dev_int_fw_vpc" {
  cloud_type           = 1
  account_name         = var.aws_account
  region               = var.aws_region
  name                 = "dev-int-fw"
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
  gw_name      = "dev-fw-gw"
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

  tags = {
    Organization = "Development"
  }

  depends_on = [aviatrix_vpc.dev_int_fw_vpc]
}

# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Transit Firenet Gateway Attachment
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_aws_tgw_vpc_attachment" "dev_firenet_tgw_attachment" {
  tgw_name             = aviatrix_aws_tgw.dev_tgw.tgw_name
  region               = var.aws_region
  security_domain_name = aviatrix_aws_tgw_security_domain.dev_firewall_domain.name
  vpc_account_name     = var.aws_account
  vpc_id               = aviatrix_vpc.dev_int_fw_vpc.vpc_id
  depends_on           = [aviatrix_transit_gateway.dev_int_fw_gw, aviatrix_aws_tgw_security_domain_connection.dev_connections, aviatrix_aws_tgw_transit_gateway_attachment.dev_tgw_to_dev_gw_attachment]
}

# ---------------------------------------------------------------------------------------------------------------------
# Launch Firewall
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_firewall_instance" "dev_int_fw_instance" {
  vpc_id          = aviatrix_vpc.dev_int_fw_vpc.vpc_id
  firenet_gw_name = aviatrix_transit_gateway.dev_int_fw_gw.gw_name
  firewall_name   = "dev-ew-fg-instance-1"
  firewall_image  = "Fortinet FortiGate Next-Generation Firewall"
  firewall_size   = "t2.small"
  egress_subnet   = aviatrix_vpc.dev_int_fw_vpc.subnets[1].cidr
  #iam_role              = module.fortigate_bootstrap.aws_iam_role.name
  #bootstrap_bucket_name = module.fortigate_bootstrap.aws_s3_bucket.bucket
  user_data  = local.dev_fw_init_conf
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