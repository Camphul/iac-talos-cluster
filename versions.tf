locals {
  full_talos_version = "v${var.talos_version}"
  full_k8s_version   = "v${var.k8s_version}"
}

variable "talos_version" {
  # https://github.com/siderolabs/talos/releases
  description = "Talos version to use"
  type        = string
  default     = "1.10.0"
}

variable "talos_machine_install_image_url" {
  # https://www.talos.dev/v1.7/talos-guides/install/boot-assets/
  description = "The URL of the Talos machine install image"
  type        = string
  # % is replaced by talos_version
  default = "factory.talos.dev/metal-installer-secureboot/eebdd12b24d4c9492a6bee2c863922c54b35af63d215ea07284d93180b97fd88:v%"
  # default = "ghcr.io/siderolabs/installer:v%" // = default, when not using system extensions
}

variable "k8s_version" {
  # https://www.talos.dev/v1.7/introduction/support-matrix/
  description = "Kubernetes version to use"
  type        = string
  default     = "1.33.0"
}

variable "talos_ccm_version" {
  # https://github.com/siderolabs/talos-cloud-controller-manager/releases
  description = "Talos Cloud Controller Manager version to use"
  type        = string
  default     = "1.10.0"
}

variable "cilium_version" {
  # https://helm.cilium.io/
  description = "Cilium Helm version to use"
  type        = string
  default     = "1.17.4"
}

variable "argocd_version" {
  # https://github.com/argoproj/argo-cd/releases
  description = "ArgoCD version to use"
  type        = string
  default     = "3.0.6"
}

variable "metrics_server_version" {
  # https://github.com/kubernetes-sigs/metrics-server/releases
  description = "Kubernetes Metrics Server version to use"
  type        = string
  default     = "0.7.2"
}
