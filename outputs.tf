output "ip" {
  value = "${azurerm_public_ip.publicip.ip_address}"
}
