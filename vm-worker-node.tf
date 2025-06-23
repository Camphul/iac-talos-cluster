locals {
  vm_worker_nodes = flatten([
    for i, worker in var.worker_nodes : [
      for j in range(worker.count) : {
        index         = i
        target_server = worker.target_server
        node_labels   = merge(var.proxmox_servers[worker.target_server].node_labels, worker.node_labels)
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
    #     proxmox_virtual_environment_file.talos-iso,
    macaddress.talos-worker-node
  ]
  for_each = {
    for i, x in local.vm_worker_nodes : i => x
  }

  name                = "${var.worker_node_name_prefix}-${each.key + 1}"
  vm_id               = each.key + var.worker_node_first_id
  node_name           = each.value.target_server
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
        address = "${cidrhost(var.network_cidr, each.key + var.worker_node_first_ip)}/${split("/", var.network_cidr)[1]}"
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
    cores   = each.value.cpu_cores
  }

  memory {
    dedicated = each.value.memory * 1024
    floating  = each.value.memory * 1024
  }

  network_device {
    enabled     = true
    model       = "virtio"
    bridge      = var.proxmox_servers[each.value.target_server].network_bridge
    mac_address = macaddress.talos-worker-node[each.key].address
    firewall    = false
  }

  operating_system {
    type = "l26" # Linux kernel type
  }

  disk {
    size         = each.value.disk_size
    datastore_id = var.proxmox_servers[each.value.target_server].disk_storage_pool
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
      interface    = "virtio${each.value.index + 1}"
      size         = disk.value.size
      datastore_id = disk.value.storage_pool != "" ? disk.value.storage_pool : var.proxmox_servers[each.value.target_server].disk_storage_pool
      file_format  = "raw"
      cache        = "none"
      iothread     = true
      backup       = false
    }
  }
}

output "talos_worker_node_mac_addrs" {
  value = macaddress.talos-worker-node
}
