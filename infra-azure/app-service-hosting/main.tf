module "app_service" {
  source = "../modules/app-service"

  prefix                 = var.prefix
  location               = var.location
  location_abbr          = var.location_abbr
  storage_share_quota_gb = var.storage_share_quota_gb
  allowed_cidr_ranges    = var.allowed_cidr_ranges
  sku_name               = var.sku_name
}
