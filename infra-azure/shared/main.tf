resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg-${var.location_abbr}"
  location = var.location
}

resource "azurerm_container_registry" "main" {
  name                = "${var.prefix}acr${var.location_abbr}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false
}
