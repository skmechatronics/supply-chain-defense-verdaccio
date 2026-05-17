output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "resource_group_location" {
  value = azurerm_resource_group.main.location
}

output "storage_account_name" {
  value = azurerm_storage_account.verdaccio.name
}

output "storage_account_key" {
  value     = azurerm_storage_account.verdaccio.primary_access_key
  sensitive = true
}

output "storage_share_name" {
  value = azurerm_storage_share.verdaccio.name
}

output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "acr_id" {
  value = azurerm_container_registry.main.id
}

