output "app_url" {
  value = module.app_service.app_url
}

output "acr_login_server" {
  value = var.acr_login_server
}
