# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Transit Gateway Transit Peering
# ---------------------------------------------------------------------------------------------------------------------

/* resource "aviatrix_transit_gateway_peering" "stass_sta_peering" {
  transit_gateway_name1           = aviatrix_transit_gateway.stass_gw.gw_name
  transit_gateway_name2           = aviatrix_transit_gateway.sta_gw.gw_name
  gateway1_excluded_network_cidrs = ["0.0.0.0/0"]
  gateway2_excluded_network_cidrs = ["0.0.0.0/0"]
} */

resource "aviatrix_transit_gateway_peering" "stass_dev_peering" {
  transit_gateway_name1           = aviatrix_transit_gateway.stass_gw.gw_name
  transit_gateway_name2           = aviatrix_transit_gateway.dev_gw.gw_name
  gateway1_excluded_network_cidrs = ["0.0.0.0/0"]
  gateway2_excluded_network_cidrs = ["0.0.0.0/0"]
}