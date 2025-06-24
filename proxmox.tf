locals {
  local_talos_iso_file_name = "talos-v${var.talos_version}-${var.talos_schematic_id}-${var.talos_schematic_platform}-amd64-secureboot.iso"
}

resource "proxmox_virtual_environment_download_file" "talos-iso" {
  content_type        = "iso"
  datastore_id        = var.talos_iso_destination_storage_pool
  node_name           = var.talos_iso_destination_server
  url                 = data.talos_image_factory_urls.this.urls.iso_secureboot
  file_name           = local.local_talos_iso_file_name
  overwrite_unmanaged = true
  overwrite           = false
  upload_timeout      = 600
}
