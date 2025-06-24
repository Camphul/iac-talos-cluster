locals {
  vm_worker_nodes = flatten([
    for i, worker in var.worker_nodes : [
      for j in range(worker.count) : {
        index         = i
        target_server = coalesce(worker.target_server, local.pve_node_fallback)
        node_labels   = merge(var.proxmox_servers[coalesce(worker.target_server, local.pve_node_fallback)].node_labels, worker.node_labels)
        cpu_cores     = worker.cpu_cores > 0 ? worker.cpu_cores : var.worker_node_cpu_cores
        memory        = worker.memory > 0 ? worker.memory : var.worker_node_memory
        disk_size     = worker.disk_size > 0 ? worker.disk_size : var.worker_node_disk_size
        data_disks    = worker.data_disks
      }
    ]
  ])
}

resource "macaddress" "talos-worker-node" {
  count = length(local.vm_worker_nodes)
}

resource "proxmox_virtual_environment_vm" "talos-worker-node" {
  depends_on = [
    proxmox_virtual_environment_download_file.talos-iso,
    local.pve_node_fallback,
    local.vm_worker_nodes
  ]
  for_each = {
    for i, x in local.vm_worker_nodes : i => x
  }

  name                = "${var.worker_node_name_prefix}-${each.key + 1}"
  vm_id               = each.key + var.worker_node_first_id
  node_name           = coalesce(each.value.target_server, local.pve_node_fallback)
  on_boot             = true
  machine             = "q35"
  scsi_hardware       = "virtio-scsi-single"
  bios                = "ovmf"
  tablet_device       = false
  timeout_create      = 480
  timeout_stop_vm     = 300
  timeout_shutdown_vm = 900
  startup {
    up_delay = 15 + each.key
    order    = 3
  }
  agent {
    enabled = true
  }
  efi_disk {
    datastore_id      = var.datastore-vmdata
    pre_enrolled_keys = false
    file_format       = "raw"
    type              = "4m"
  }
  tpm_state {
    datastore_id = var.datastore-vmdata
    version      = "v2.0"
  }
  initialization {
    ip_config {
      ipv4 {
        address = "${cidrhost(var.network_cidr, each.key + var.worker_node_first_ip)}/${split("/", var.network_cidr)[1]}"
        gateway = var.network_gateway
      }
    }
    dns {
      servers = var.network_nameservers
      domain  = var.network_search_domains[0]
    }
  }
  tags            = ["talos", "terraform"]
  stop_on_destroy = true
  boot_order      = ["scsi0", "ide3"]
  cdrom {
    interface = "ide3"
    file_id   = proxmox_virtual_environment_download_file.talos-iso.id
  }

  cpu {
    type    = "x86-64-v3"
    flags   = ["+aes"]
    sockets = 1
    cores   = each.value.cpu_cores
  }

  memory {
    dedicated = each.value.memory * 1024
    floating  = each.value.memory * 1024
  }

  network_device {
    bridge      = var.proxmox_servers[each.value.target_server].network_bridge
    mac_address = macaddress.talos-worker-node[each.key].address
    vlan_id     = var.network_vlan
    firewall    = false
  }

  operating_system {
    type = "l26" # Linux kernel type
  }

  disk {
    size         = each.value.disk_size
    datastore_id = var.datastore-vmdata
    interface    = "scsi0"
    iothread     = true
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
    backup       = false
  }

  dynamic "disk" {
    for_each = var.worker_nodes[each.value.index].data_disks

    content {
      interface    = "scsi${each.value.index + 1}"
      size         = disk.value.size
      datastore_id = var.datastore-vmdata
      # file_format  = "raw"
      # cache        = "none"
      iothread = true
      cache    = "writethrough"
      discard  = "on"
      ssd      = true
      backup   = false
    }
  }
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

output "talos_worker_node_mac_addrs" {
  value = macaddress.talos-worker-node
}
