resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg-${var.location_abbr}"
  location = var.location
}

resource "azurerm_storage_account" "verdaccio" {
  name                            = "${var.prefix}stacc${var.location_abbr}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_share" "verdaccio" {
  name               = "verdaccio-storage"
  storage_account_id = azurerm_storage_account.verdaccio.id
  quota              = var.storage_share_quota_gb
}

resource "azurerm_container_registry" "main" {
  name                = "${var.prefix}acr${var.location_abbr}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false
}
