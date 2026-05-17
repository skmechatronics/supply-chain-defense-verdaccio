module "common" {
  source = "../modules/common"

  prefix                 = var.prefix
  location               = var.location
  location_abbr          = var.location_abbr
  storage_share_quota_gb = var.storage_share_quota_gb
}
