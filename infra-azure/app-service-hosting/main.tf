module "app_service" {
  source = "../modules/app-service"

  prefix               = var.prefix
  location             = var.location
  location_abbr        = var.location_abbr
  resource_group_name  = var.resource_group_name
  storage_account_name = var.storage_account_name
  storage_account_key  = var.storage_account_key
  storage_share_name   = var.storage_share_name
  acr_login_server     = var.acr_login_server
  acr_id               = var.acr_id
  docker_registry_url  = var.docker_registry_url
  docker_image_name    = var.docker_image_name
  sku_name             = var.sku_name
}
