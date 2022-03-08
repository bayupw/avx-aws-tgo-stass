# ---------------------------------------------------------------------------------------------------------------------
# dev VPCs
# ---------------------------------------------------------------------------------------------------------------------

# dev spoke vpc 1
module "dev_spoke1_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "dev-spoke1"
  cidr = var.vpc_cidr.dev_spoke1_vpc

  azs             = ["${var.aws_region}a"]
  private_subnets = [cidrsubnet(var.vpc_cidr.dev_spoke1_vpc, 1, 1)]
  public_subnets  = [cidrsubnet(var.vpc_cidr.dev_spoke1_vpc, 1, 0)]
  enable_ipv6     = false
}

# dev spoke vpc 2
module "dev_spoke2_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "dev-spoke2"
  cidr = var.vpc_cidr.dev_spoke2_vpc

  azs             = ["${var.aws_region}a"]
  private_subnets = [cidrsubnet(var.vpc_cidr.dev_spoke2_vpc, 1, 1)]
  public_subnets  = [cidrsubnet(var.vpc_cidr.dev_spoke2_vpc, 1, 0)]
  enable_ipv6     = false
}

# dev-transit TGW - spoke 1 attachment
resource "aviatrix_aws_tgw_vpc_attachment" "dev_spoke_1_tgw_attachment" {
  tgw_name             = aviatrix_aws_tgw.dev_tgw.tgw_name
  region               = var.aws_region
  security_domain_name = "Default_Domain"
  vpc_account_name     = var.aws_account
  vpc_id               = module.dev_spoke1_vpc.vpc_id
  depends_on           = [module.dev_spoke1_vpc, aviatrix_aws_tgw_security_domain.dev_default_domains]

  # ignore changes to allow migration
  lifecycle {
    ignore_changes = all
  }
}

# ss-transit TGW - spoke 2 attachment
resource "aviatrix_aws_tgw_vpc_attachment" "dev_spoke2_tgw_attachment" {
  tgw_name             = aviatrix_aws_tgw.dev_tgw.tgw_name
  region               = var.aws_region
  security_domain_name = "Shared_Service_Domain"
  vpc_account_name     = var.aws_account
  vpc_id               = module.dev_spoke2_vpc.vpc_id
  depends_on           = [module.dev_spoke2_vpc, aviatrix_aws_tgw_security_domain.dev_default_domains]

  # ignore changes to allow migration
  lifecycle {
    ignore_changes = all
  }
}