variable "project_name" {
  description = "User's VRA Project name"
  type        = string
}

variable "catalog_item_name" {
  description = "VRA - Catalog Item Name"
  type        = string
  default     = "1) VM - RedHat"
}

variable "deployment_name" {
  description = "VRA - Deployment Name"
  type        = string
}

variable "vm_name" {
  description = "VM Hostname Suffix"
  type        = string

  validation {
    condition     = length(var.vm_name) < 6
    error_message = "VM Hostname Suffix cannot be more than 5 characters"
  }
}

variable "vm_size" {
  description = "Size of Virtual Machine"
  type        = string

  validation {
    condition     = var.vm_size == "small" || var.vm_size == "medium" || var.vm_size == "large"
    error_message = "Please select an appropriate VM Size (Small, Medium, Large)"
  }
}
