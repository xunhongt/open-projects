
variable "project_name" {
  description = "User's VRA Project name"
  type        = string
}

variable "catalog_item_name" {
  description = "VRA - Catalog Item Name"
  type        = string
  default     = "[IaC] Firewall - External Env to A"
}

variable "deployment_name" {
  description = "VRA - Deployment Name"
  type        = string
}

variable "fwName" {
  description = "Firewall Name"
  type        = string
}

variable "environment" {
  description = "Target Environment (where you want to open your firewall rules)"
  type        = string
}

variable "sourceVMList" {
  description = "Firewall Source - VM List"
  type        = string
}

variable "sourceIPList" {
  description = "Firewall Source - IP List"
  type        = string
}

variable "sourceSGList" {
  description = "Firewall Source - Security Group List"
  type        = string
}

variable "destVMList" {
  description = "Firewall Destination - VM List"
  type        = string

}

variable "protocols" {
  description = "Firewall Protocols"
  type        = string
}

variable "tcpPorts" {
  description = "TCP Ports to open"
  type        = string
}

variable "udpPorts" {
  description = "UDP Ports to open"
  type        = string
}
