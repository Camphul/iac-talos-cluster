terraform {
  required_providers {
    proxmox = {
      # https://registry.terraform.io/providers/bpg/proxmox/latest/docs
      source  = "bpg/proxmox"
      version = "0.78.2"
    }
    talos = {
      # https://registry.terraform.io/providers/siderolabs/talos/latest/docs
      source  = "siderolabs/talos"
      version = "0.9.0-alpha.0"
    }
    synclocal = {
      source  = "justenwalker/synclocal"
      version = "0.0.2"
    }
    macaddress = {
      source  = "ivoronin/macaddress"
      version = "0.3.2"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = false
  ssh {
    agent    = true
    username = "root"
  }
}
