output "resource_group_name" {
  value = module.common.resource_group_name
}

output "resource_group_location" {
  value = module.common.resource_group_location
}

output "storage_account_name" {
  value = module.common.storage_account_name
}

output "storage_account_key" {
  value     = module.common.storage_account_key
  sensitive = true
}

output "storage_share_name" {
  value = module.common.storage_share_name
}

output "acr_login_server" {
  value = module.common.acr_login_server
}

output "acr_id" {
  value = module.common.acr_id
}

