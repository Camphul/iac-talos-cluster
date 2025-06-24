

variable "talos_iso_destination_server" {
  description = "Proxmox server to store the Talos iso image on"
  type        = string
  default     = ""
}

variable "talos_iso_destination_storage_pool" {
  description = "Proxmox storage to store the Talos iso image on"
  type        = string
  default     = "local"
}

variable "talos_schematic_id" {
  description = "Talos Imager Schematic ID"
  type        = string
  nullable    = false
}

variable "talos_schematic_platform" {
  description = "Which platform in use"
  type        = string
  default     = "nocloud"
}

variable "datastore-vmdata" {
  default     = "local-vmdata"
  description = "Datastore for VM disks"
  type        = string
}
