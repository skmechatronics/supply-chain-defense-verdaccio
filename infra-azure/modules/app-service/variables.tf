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

variable "storage_share_quota_gb" {
  description = "Azure Files share size in GB."
  type        = number
  default     = 5
}

variable "acr_login_server" {
  description = "ACR login server hostname (e.g. vdcdacrause.azurecr.io)."
  type        = string
}

variable "acr_id" {
  description = "ACR resource ID — used to scope the AcrPull role assignment."
  type        = string
}

variable "docker_registry_url" {
  description = "Docker registry URL. Defaults to MCR placeholder — override with ACR URL once image is pushed."
  type        = string
  default     = "https://mcr.microsoft.com"
}

variable "docker_image_name" {
  description = "Image name and tag to deploy. Defaults to MCR placeholder — override with ACR image once pushed."
  type        = string
  default     = "appsvc/staticsite:latest"
}

variable "sku_name" {
  description = "App Service Plan SKU."
  type        = string
  default     = "B1"
}
