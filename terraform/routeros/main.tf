# MikroTik RouterOS infrastructure
#
# Devices managed:
#   rb5009   - RB5009UG+S+IN   (.1)  - Main router
#   crs309   - CRS309-1G-8S+IN (.11) - 10G SFP+ switch
#   crs326   - CRS326-24G-2S+RM (.12) - 24-port GbE switch
#   crs226   - CRS226-24G-2S+RM (.13) - 24-port GbE switch
#   hap-ax2a - hAP AX2          (.15) - WiFi AP
#   hap-ax2b - hAP AX2          (.16) - WiFi AP

provider "routeros" {
  hosturl  = var.routeros_devices["rb5009"].hosturl
  username = var.routeros_devices["rb5009"].username
  password = var.routeros_devices["rb5009"].password
  insecure = var.routeros_devices["rb5009"].insecure
}
