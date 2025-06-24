locals {
  talos_ccm_manifest_url      = replace(var.talos_ccm_manifest_url, "%", var.talos_ccm_version)
  metrics_server_manifest_url = replace(var.metrics_server_manifest_url, "%", var.metrics_server_version)
  argocd_manifest_url         = replace(var.argocd_manifest_url, "%", var.argocd_version)
}

# download and kustomize talos ccm manifests
resource "synclocal_url" "talos_ccm_manifest" {
  depends_on = [
    data.external.talos-nodes-ready,
    proxmox_virtual_environment_vm.talos-worker-node,
    proxmox_virtual_environment_vm.talos-control-plane
  ]
  url      = local.talos_ccm_manifest_url
  filename = "${path.module}/manifests/talos-ccm/talos-ccm.yaml"
}

data "external" "kustomize_talos-ccm" {
  depends_on = [proxmox_virtual_environment_vm.talos-worker-node,
  proxmox_virtual_environment_vm.talos-control-plane]
  program = [
    "go",
    "run",
    "${path.module}/cmd/kustomize",
    "--",
    "${path.module}/manifests/talos-ccm",
  ]
}

# kustomize cilium manifests
resource "local_file" "cilium_kustomization" {
  filename = "${path.module}/manifests/cilium/base/kustomization.yaml"
  content = templatefile("${path.module}/manifests/cilium/base/kustomization.yaml.tpl", {
    cilium_version = var.cilium_version
  })
}
# kustomize  csr approver manifests
resource "local_file" "csr_kustomization" {
  filename = "${path.module}/manifests/csr-approver/kustomization.yaml"
  content = templatefile("${path.module}/manifests/csr-approver/kustomization.yaml.tpl", {
    # cilium_version = var.cilium_version
  })
}
data "external" "kustomize_cilium" {
  depends_on = [local_file.cilium_kustomization]
  program = [
    "go",
    "run",
    "${path.module}/cmd/kustomize",
    "--",
    "--enable-helm",
    "${path.module}/manifests/cilium/base",
  ]
}
data "external" "kustomize_csr" {
  depends_on = [local_file.csr_kustomization]
  program = [
    "go",
    "run",
    "${path.module}/cmd/kustomize",
    "--",
    "--enable-helm",
    "${path.module}/manifests/csr-approver",
  ]
}

resource "local_file" "export_inline-manifests" {
  depends_on = [terraform_data.inline-manifests]
  content    = yamlencode(terraform_data.inline-manifests.output)
  filename   = "${path.module}/output/inline-manifests.yaml"
}
