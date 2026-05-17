module "common" {
  source = "../modules/common"

  prefix                 = var.prefix
  location               = var.location
  location_abbr          = var.location_abbr
  storage_share_quota_gb = var.storage_share_quota_gb
}

module "app_service" {
  source = "../modules/app-service"

  prefix               = var.prefix
  location             = var.location
  location_abbr        = var.location_abbr
  resource_group_name  = module.common.resource_group_name
  storage_account_name = module.common.storage_account_name
  storage_account_key  = module.common.storage_account_key
  storage_share_name   = module.common.storage_share_name
  acr_login_server     = module.common.acr_login_server
  acr_admin_username   = module.common.acr_admin_username
  acr_admin_password   = module.common.acr_admin_password
  verdaccio_image_tag  = var.verdaccio_image_tag
  sku_name             = var.sku_name
}
