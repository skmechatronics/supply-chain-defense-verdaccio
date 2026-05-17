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
  acr_id               = data.terraform_remote_state.shared.outputs.acr_id
  docker_registry_url  = var.docker_registry_url
  docker_image_name    = var.docker_image_name
  sku_name             = var.sku_name
}
