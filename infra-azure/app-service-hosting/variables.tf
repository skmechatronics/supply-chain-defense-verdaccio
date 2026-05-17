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

variable "verdaccio_image_tag" {
  description = "Tag of the verdaccio-cooldown image to deploy from ACR."
  type        = string
  default     = "latest"
}

variable "sku_name" {
  description = "App Service Plan SKU (e.g. B1, B2, S1)."
  type        = string
  default     = "B1"
}

variable "storage_share_quota_gb" {
  description = "Azure Files share size in GB."
  type        = number
  default     = 5
}
