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

variable "allowed_cidr_ranges" {
  description = "CIDR blocks allowed to reach the registry. At least one range must be specified."
  type        = list(string)
  validation {
    condition     = length(var.allowed_cidr_ranges) > 0
    error_message = "At least one CIDR range must be specified. Set allowed_cidr_ranges in terraform.tfvars."
  }
}

variable "sku_name" {
  description = "App Service Plan SKU (e.g. B1, B2, S1)."
  type        = string
  default     = "B1"
}
