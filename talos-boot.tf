resource "terraform_data" "inline-manifests" {
  depends_on = [
    data.external.kustomize_talos-ccm,
    data.external.kustomize_cilium
  ]

  input = [
    {
      # required, is used as CNI and is needed for Talos to report nodes as ready
      name     = "cilium"
      contents = data.external.kustomize_cilium.result.manifests
    },
    {
      # required to approve CSR
      name     = "csr-approver"
      contents = data.external.kustomize_csr.result.manifests
    },
    {
      # required, prevents certificate errors
      name     = "talos-ccm"
      contents = data.external.kustomize_talos-ccm.result.manifests
    } # {
    #   name     = "cilium-bgp-peering-policy"
    #   contents = templatefile("${path.module}/manifests/cilium/bgp-peering-policy.yaml.tpl", {
    #     cilium_asn = var.cilium_asn,
    #     router_ip  = var.router_ip != "" ? var.router_ip : var.network_gateway,
    #     router_asn = var.router_asn,
    #   })
    # }
  ]
}

resource "talos_machine_configuration_apply" "control-planes" {
  depends_on = [
    # data.external.mac-to-ip,
    data.talos_machine_configuration.cp,
    terraform_data.inline-manifests,
    proxmox_virtual_environment_vm.talos-control-plane
  ]
  for_each = {
    for i, x in local.vm_control_planes : i => x
  }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.cp.machine_configuration
  node                        = local.talos_cp_endpoints[each.key]

  config_patches = [
    templatefile("${path.module}/talos-config/control-plane.yaml.tpl", {
      topology_zone     = each.value
      cluster_domain    = var.cluster_domain
      cluster_endpoint  = local.cluster_endpoint
      network_interface = "eth0"
      network_ip_prefix = var.network_ip_prefix
      network_gateway   = var.network_gateway
      hostname          = "${var.control_plane_name_prefix}-${each.key + 1}"
      ipv4_local        = cidrhost(var.network_cidr, each.key + var.control_plane_first_ip)
      ipv4_vip          = var.cluster_vip
      inline_manifests  = jsonencode(terraform_data.inline-manifests.output)
      name_servers      = var.network_nameservers
      search_domains    = var.network_search_domains
    }),
  ]
}

resource "talos_machine_configuration_apply" "worker-nodes" {
  depends_on = [
    # data.external.mac-to-ip,
    data.talos_machine_configuration.wn,
    proxmox_virtual_environment_vm.talos-worker-node,
    terraform_data.inline-manifests,
  ]
  for_each = {
    for i, x in local.vm_worker_nodes : i => x
  }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.wn.machine_configuration

  node = local.talos_worker_nodes[each.key]
  #data.external.mac-to-ip.result[macaddress.talos-worker-node[each.key].address]

  config_patches = concat([
    templatefile("${path.module}/talos-config/worker-node.yaml.tpl", {
      topology_zone     = each.value.target_server
      cluster_domain    = var.cluster_domain
      network_interface = "eth0"
      network_ip_prefix = var.network_ip_prefix
      network_gateway   = var.network_gateway
      hostname          = "${var.worker_node_name_prefix}-${each.key + 1}"
      ipv4_local        = cidrhost(var.network_cidr, each.key + var.worker_node_first_ip)
      ipv4_vip          = var.cluster_vip
      name_servers      = var.network_nameservers
      search_domains    = var.network_search_domains
    }),
    templatefile("${path.module}/talos-config/node-labels.yaml.tpl", {
      node_labels = jsonencode(each.value.node_labels)
    })
    ],
    [
      for disk in coalesce(each.value.data_disks, []) : templatefile(
        "${path.module}/talos-config/worker-node-disk.yaml.tpl",
        {
          disk_device = "/dev/${coalesce(disk.device_name, "default-device")}",
          mount_point = coalesce(disk.mount_point, "/default-mount"),
        }
      )
    ]
  )
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    proxmox_virtual_environment_vm.talos-worker-node,
    proxmox_virtual_environment_vm.talos-control-plane,
    talos_machine_configuration_apply.control-planes,
    talos_machine_configuration_apply.worker-nodes,
  ]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = cidrhost(var.network_cidr, var.control_plane_first_ip)
}

# unfortunately, this does not really check, wait and retry for the cluster to
# be ready but instead errors and fails when unable to connect to nodes that
# are in the process of getting ready
#
data "talos_cluster_health" "ready" {
  depends_on             = [null_resource.talos-cluster-up]
  skip_kubernetes_checks = true
  client_configuration   = talos_machine_secrets.this.client_configuration
  endpoints              = local.talos_cp_endpoints
  control_plane_nodes    = local.talos_cp_endpoints
  worker_nodes           = local.talos_worker_nodes
}
