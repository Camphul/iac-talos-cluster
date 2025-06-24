locals {
  cluster_endpoint_internal = "https://${var.cluster_domain}:${var.cluster_endpoint_port}"
  cluster_endpoint          = "https://${var.cluster_vip}:${var.cluster_endpoint_port}"
  storage_mnt               = "/var/mnt/storage"

  # default talos_machine_configuration values
  talos_mc_defaults = {
    topology_region     = var.cluster_name,
    talos_version       = var.talos_version,
    network_gateway     = var.network_gateway,
    install_disk_device = var.install_disk_device,
    install_image_url   = data.talos_image_factory_urls.this.urls.installer_secureboot

    #    harbor_url      = var.harbor_url,
    #    harbor_domain   = split("://", var.harbor_url)[1]
    #    harbor_username = var.harbor_username
    #    harbor_password = var.harbor_password
  }
  pve_node_fallback = keys(var.proxmox_servers)[0]
}

resource "talos_machine_secrets" "this" {}

data "talos_client_configuration" "this" {
  //noinspection HILUnresolvedReference
  client_configuration = talos_machine_secrets.this.client_configuration
  cluster_name         = var.cluster_name
  endpoints = concat([var.cluster_vip], [
    for i in range(
      var.control_plane_first_ip, var.control_plane_first_ip + local.vm_control_planes_count
    ) : cidrhost(var.network_cidr, i)
  ])
}

data "talos_machine_configuration" "cp" {
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  cluster_name       = var.cluster_name
  cluster_endpoint   = local.cluster_endpoint
  talos_version      = local.full_talos_version
  kubernetes_version = local.full_k8s_version
  docs               = true
  examples           = false

  config_patches = [
    templatefile("${path.module}/talos-config/default.yaml.tpl", local.talos_mc_defaults),
  ]
}
data "talos_image_factory_urls" "this" {
  talos_version = "v${var.talos_version}"
  schematic_id  = var.talos_schematic_id
  platform      = var.talos_schematic_platform
  architecture  = "amd64"
}
data "talos_machine_configuration" "wn" {
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  cluster_name       = var.cluster_name
  cluster_endpoint   = local.cluster_endpoint
  talos_version      = "v${var.talos_version}"
  kubernetes_version = "v${var.k8s_version}"
  docs               = true
  examples           = false

  config_patches = [
    templatefile("${path.module}/talos-config/default.yaml.tpl", local.talos_mc_defaults),
  ]
}
