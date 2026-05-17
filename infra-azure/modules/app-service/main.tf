resource "azurerm_service_plan" "main" {
  name                = "${var.prefix}-asp-${var.location_abbr}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
}

resource "azurerm_linux_web_app" "verdaccio" {
  name                = "${var.prefix}-app-${var.location_abbr}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      docker_image_name        = "verdaccio-cooldown:${var.verdaccio_image_tag}"
      docker_registry_url      = "https://${var.acr_login_server}"
      docker_registry_username = var.acr_admin_username
      docker_registry_password = var.acr_admin_password
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
    account_name = var.storage_account_name
    share_name   = var.storage_share_name
    access_key   = var.storage_account_key
    mount_path   = "/verdaccio/storage"
  }
}
