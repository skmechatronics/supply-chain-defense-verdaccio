data "terraform_remote_state" "shared" {
  backend = "azurerm"
  config = {
    resource_group_name  = "vdcd-rg-tfstate-ause"
    storage_account_name = "vdcdtfstateause"
    container_name       = "tfstate"
    key                  = "shared.tfstate"
  }
}

module "app_service" {
  source = "../modules/app-service"

  prefix               = var.prefix
  location             = var.location
  location_abbr        = var.location_abbr
  resource_group_name  = data.terraform_remote_state.shared.outputs.resource_group_name
  storage_account_name = data.terraform_remote_state.shared.outputs.storage_account_name
  storage_account_key  = data.terraform_remote_state.shared.outputs.storage_account_key
  storage_share_name   = data.terraform_remote_state.shared.outputs.storage_share_name
  acr_login_server     = data.terraform_remote_state.shared.outputs.acr_login_server
  acr_admin_username   = data.terraform_remote_state.shared.outputs.acr_admin_username
  acr_admin_password   = data.terraform_remote_state.shared.outputs.acr_admin_password
  verdaccio_image_tag  = var.verdaccio_image_tag
  sku_name             = var.sku_name
}
