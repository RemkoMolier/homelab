# Horaco managed switches
#
# Devices managed:
#   sw-10g  - 8-port 10G  (.20)
#   sw-2g5  - 8-port 2.5G (.21)

provider "hrui" {
  url      = var.horaco_devices["sw-10g"].url
  username = var.horaco_devices["sw-10g"].username
  password = var.horaco_devices["sw-10g"].password
}
