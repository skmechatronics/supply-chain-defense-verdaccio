output "app_url" {
  value = "https://${azurerm_linux_web_app.verdaccio.default_hostname}"
}

output "app_name" {
  value = azurerm_linux_web_app.verdaccio.name
}
