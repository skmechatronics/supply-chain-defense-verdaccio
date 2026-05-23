module "app_service" {
  source = "../modules/app-service"

  prefix                 = var.prefix
  location               = var.location
  location_abbr          = var.location_abbr
  storage_share_quota_gb = var.storage_share_quota_gb
  allowed_cidr_ranges    = var.allowed_cidr_ranges
  docker_registry_url    = var.docker_registry_url
  docker_image_name      = var.docker_image_name
  sku_name               = var.sku_name
}
