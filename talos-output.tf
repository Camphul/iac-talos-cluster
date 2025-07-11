resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this,
  ]
  node = var.control_plane_first_ip

  #       = "https://10.10.80.12:${var.cluster_endpoint_port}"
  client_configuration = data.talos_client_configuration.this.client_configuration
}

resource "local_sensitive_file" "export_talosconfig" {
  depends_on = [data.talos_client_configuration.this]
  content    = data.talos_client_configuration.this.talos_config
  filename   = "${path.module}/output/talosconfig"
}

resource "local_sensitive_file" "export_kubeconfig" {
  depends_on = [talos_cluster_kubeconfig.this]
  content    = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename   = "${path.module}/output/kubeconfig"
}

data "external" "copy_talosconfig" {
  depends_on = [local_sensitive_file.export_talosconfig]
  program = [
    "go",
    "run",
    "${path.module}/cmd/cp-to-home",
    "${path.module}/output/talosconfig",
    "~/.talos/config",
  ]
}

data "external" "copy_kubeconfig" {
  depends_on = [local_sensitive_file.export_kubeconfig]

  program = [
    "go",
    "run",
    "${path.module}/cmd/cp-to-home",
    "${path.module}/output/kubeconfig",
    "~/.kube/config",
  ]
}

resource "null_resource" "talos-cluster-up" {
  depends_on = [
    data.external.copy_talosconfig,
    data.external.copy_kubeconfig,
  ]
}

output "talos_client_configuration" {
  value     = data.talos_client_configuration.this
  sensitive = true
}

output "talos_cluster_kubeconfig" {
  value     = talos_cluster_kubeconfig.this
  sensitive = true
}
