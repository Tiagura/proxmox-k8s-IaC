terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.83.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.pve_api_url

  # Use either token or username/password authentication
  # Token-based (recommended for automation)
  # api_token = var.pve_api_token
  # OR username/password (less secure)
  username = var.pve_username
  password = var.pve_password

  insecure = true
  
  ssh {
    agent = true
  }
}