locals {
  talos_iso_image_location = "${var.talos_iso_destination_storage_pool}:iso/${replace(var.talos_iso_destination_filename, "%", var.talos_version)}"

  //noinspection HILUnresolvedReference
  vm_control_planes = flatten([
    for name, host in var.proxmox_servers : [
      for i in range(host.control_planes_count) : name
    ]
  ])
  vm_control_planes_count = length(local.vm_control_planes)
}

# this keeps bitching about the file already exists... i know, just skip it then
#
# resource "proxmox_virtual_environment_file" "talos-iso" {
#   content_type = "iso"
#   datastore_id = var.talos_iso_destination_storage_pool
#   node_name    = var.talos_iso_destination_server != "" ? var.talos_iso_destination_server : keys(var.proxmox_servers)[0]
#   overwrite = false
#
#   source_file {
#     path      = replace(var.talos_iso_download_url, "%", var.talos_version)
#     file_name = replace(var.talos_iso_destination_filename, "%", var.talos_version)
#   }
# }

resource "macaddress" "talos-control-plane" {
  count = length(local.vm_control_planes)
}

resource "proxmox_virtual_environment_vm" "talos-control-plane" {
  depends_on = [
    # proxmox_virtual_environment_file.talos-iso,
    macaddress.talos-control-plane
  ]
  for_each = {
    for i, x in local.vm_control_planes : i => x
  }

  name                = "${var.control_plane_name_prefix}-${each.key + 1}"
  vm_id               = each.key + var.control_plane_first_id
  node_name           = each.value
  on_boot             = true
  machine             = "q35"
  scsi_hardware       = "virtio-scsi-single"
  bios                = "ovmf"
  tablet_device       = false
  timeout_stop_vm     = 300
  timeout_shutdown_vm = 900
  agent {
    enabled = true
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${cidrhost(var.network_cidr, each.key + var.control_plane_first_ip)}/${split("/", var.network_cidr)[1]}"
        gateway = var.network_gateway
      }
    }
  }
  tags            = ["talos", "terraform"]
  stop_on_destroy = true
  boot_order      = ["scsi0", "ide3"]
  cdrom {
    interface = "ide3"
    file_id   = replace(local.talos_iso_image_location, "%", var.talos_version)
  }

  cpu {
    type    = "x86-64-v3"
    flags   = ["+aes"]
    sockets = 1
    cores   = var.control_plane_cpu_cores
  }

  memory {
    dedicated = var.control_plane_memory * 1024
    floating  = var.control_plane_memory * 1024
  }

  network_device {
    enabled     = true
    model       = "virtio"
    bridge      = var.proxmox_servers[each.value].network_bridge
    mac_address = macaddress.talos-control-plane[each.key].addres
    vlan_id     = var.network_vlan
    firewall    = false
  }

  operating_system {
    type = "l26" # Linux kernel type
  }

  disk {
    size         = var.control_plane_disk_size
    datastore_id = var.proxmox_servers[each.value].disk_storage_pool
    interface    = "scsi0"
    iothread     = true
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
    backup       = false
  }
}

output "talos_control_plane_mac_addrs" {
  value = macaddress.talos-control-plane
}
