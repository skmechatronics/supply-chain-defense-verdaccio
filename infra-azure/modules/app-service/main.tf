locals {
  resource_group_name           = "${var.prefix}-rg-${var.location_abbr}"
  ip_restriction_default_action = length(var.allowed_cidr_ranges) > 0 ? "Deny" : "Allow"
}

data "azurerm_container_registry" "main" {
  name                = "${var.prefix}acr${var.location_abbr}"
  resource_group_name = local.resource_group_name
}

resource "azurerm_storage_account" "verdaccio" {
  name                            = "${var.prefix}stacc${var.location_abbr}"
  resource_group_name             = local.resource_group_name
  location                        = var.location
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

resource "azurerm_service_plan" "main" {
  name                = "${var.prefix}-asp-${var.location_abbr}"
  resource_group_name = local.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
}

resource "azurerm_linux_web_app" "verdaccio" {
  name                = "${var.prefix}-app-${var.location_abbr}"
  resource_group_name = local.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      docker_image_name   = var.docker_image_name
      docker_registry_url = var.docker_registry_url
    }

    ip_restriction_default_action = local.ip_restriction_default_action

    dynamic "ip_restriction" {
      for_each = var.allowed_cidr_ranges
      content {
        ip_address = ip_restriction.value
        action     = "Allow"
        priority   = 100 + ip_restriction.key
        name       = "allow-${ip_restriction.key}"
      }
    }
  }

  app_settings = {
    VERDACCIO_PORT   = "4873"
    WEBSITES_PORT    = "4873"
    DOCKER_ENABLE_CI = "true"
  }

  storage_account {
    name         = "verdaccio-storage"
    type         = "AzureFiles"
    account_name = azurerm_storage_account.verdaccio.name
    share_name   = azurerm_storage_share.verdaccio.name
    access_key   = azurerm_storage_account.verdaccio.primary_access_key
    mount_path   = "/verdaccio/storage"
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_linux_web_app.verdaccio.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.main.id
}
