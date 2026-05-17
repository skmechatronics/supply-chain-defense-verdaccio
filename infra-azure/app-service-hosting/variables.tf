variable "prefix" {
  description = "Resource naming prefix."
  type        = string
  default     = "vdcd"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "australiaeast"
}

variable "location_abbr" {
  description = "Short region code used in resource names (e.g. ause, eus)."
  type        = string
  default     = "ause"
}

variable "resource_group_name" {
  description = "Resource group to deploy into. Copy from: terraform output -raw resource_group_name (in shared/)."
  type        = string
}

variable "storage_account_name" {
  description = "Storage account name for the Azure Files mount. Copy from: terraform output -raw storage_account_name (in shared/)."
  type        = string
}

variable "storage_account_key" {
  description = "Storage account access key. Copy from: terraform output -raw storage_account_key (in shared/)."
  type        = string
  sensitive   = true
}

variable "storage_share_name" {
  description = "Azure Files share name. Copy from: terraform output -raw storage_share_name (in shared/)."
  type        = string
}

variable "acr_login_server" {
  description = "ACR login server hostname. Copy from: terraform output -raw acr_login_server (in shared/)."
  type        = string
}

variable "acr_id" {
  description = "ACR resource ID. Copy from: terraform output -raw acr_id (in shared/)."
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
  description = "App Service Plan SKU (e.g. B1, B2, S1)."
  type        = string
  default     = "B1"
}
