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
