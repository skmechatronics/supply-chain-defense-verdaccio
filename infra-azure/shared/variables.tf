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
