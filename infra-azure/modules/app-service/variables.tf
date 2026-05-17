variable "prefix" {
  description = "Resource naming prefix."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "location_abbr" {
  description = "Short region code used in resource names (e.g. ause, eus)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy into."
  type        = string
}

variable "storage_account_name" {
  description = "Storage account name for the Azure Files mount."
  type        = string
}

variable "storage_account_key" {
  description = "Primary access key for the storage account."
  type        = string
  sensitive   = true
}

variable "storage_share_name" {
  description = "Azure Files share name to mount as Verdaccio storage."
  type        = string
}

variable "acr_login_server" {
  description = "ACR login server URL (e.g. vdcdacrause.azurecr.io)."
  type        = string
}

variable "acr_admin_username" {
  description = "ACR admin username."
  type        = string
  sensitive   = true
}

variable "acr_admin_password" {
  description = "ACR admin password."
  type        = string
  sensitive   = true
}

variable "verdaccio_image_tag" {
  description = "Tag of the verdaccio-cooldown image to deploy."
  type        = string
  default     = "latest"
}

variable "sku_name" {
  description = "App Service Plan SKU."
  type        = string
  default     = "B1"
}
