variable "network_ip_prefix" {
  description = "Network IP network prefix"
  type        = number
  default     = 24
}

variable "network_cidr" {
  description = "Network address in CIDR notation"
  type        = string
  default     = "10.0.0.0/24"
}

variable "network_vlan" {
  default     = 80
  type        = number
  description = "Vlan to configure on the network device"
}

variable "network_nameservers" {
  type        = list(string)
  description = "List of name servers"
  default     = []
}

variable "network_search_domains" {
  type        = list(string)
  description = "Search domain"
  default     = []
}

variable "network_gateway" {
  description = "Gateway of the network"
  type        = string
  default     = "10.0.0.1"
}
