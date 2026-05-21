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

variable "storage_share_quota_gb" {
  description = "Azure Files share size in GB."
  type        = number
  default     = 5
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
