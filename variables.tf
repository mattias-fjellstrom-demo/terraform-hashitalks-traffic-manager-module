variable "resource_group" {
  description = "Azure resource group object"
  type = object({
    name     = string,
    location = string,
    tags     = map(string)
  })
}

variable "name_suffix" {
  description = "Name suffix for Traffic Manager Profile"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{1}[a-z0-9.-]*[a-z0-9]$", var.name_suffix))
    error_message = "Use alphanumerics, hyphen, periods. Start and end with alphanumeric."
  }

  validation {
    condition     = length("tm-${var.name_suffix}") <= 63
    error_message = "Name suffix is too long, should be at most 60 characters long."
  }
}

variable "endpoints" {
  description = "List of endpoints to add to the traffic manager profile"
  type = list(object({
    name     = string
    target   = string
    priority = number
    enabled  = bool
  }))
}
