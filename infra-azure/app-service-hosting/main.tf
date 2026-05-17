module "app_service" {
  source = "../modules/app-service"

  prefix               = var.prefix
  location             = var.location
  location_abbr        = var.location_abbr
  resource_group_name  = var.resource_group_name
  storage_share_quota_gb = var.storage_share_quota_gb
  acr_login_server     = var.acr_login_server
  acr_id               = var.acr_id
  docker_registry_url  = var.docker_registry_url
  docker_image_name    = var.docker_image_name
  sku_name             = var.sku_name
}
