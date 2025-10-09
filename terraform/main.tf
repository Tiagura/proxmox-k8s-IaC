data "local_file" "ssh_public_key" {
  filename = var.ssh_public_key_path
}

resource "local_file" "proxmox_provider_file" {
  filename = "${path.module}/proxmox_provider.tf"
  content  = local.provider_config
}

resource "proxmox_virtual_environment_file" "meta_data_cloud_config" {
  for_each = { for vm in local.all_vms : vm.hostname => vm }

  content_type = "snippets"
  datastore_id = each.value.pve_node_datastore
  node_name    = each.value.pve_node

  source_raw {
    data = <<-EOF
    #cloud-config
    local-hostname: ${each.value.hostname}
    timezone: ${var.timezone}
    package_update: true
    packages:
      - qemu-guest-agent
      - net-tools
      - curl
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "${each.value.hostname}-meta-data.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each  = { for vm in local.all_vms : vm.hostname => vm }
  name      = each.value.hostname
  node_name = each.value.pve_node
  on_boot   = var.vm_autostart

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = each.value.pve_node_vm_storage
    file_id      = proxmox_virtual_environment_download_file.cloud_image["${each.value.pve_node}-${each.value.pve_node_datastore}"].id
    file_format  = "qcow2"
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = each.value.disk
  }

  initialization {
    datastore_id = each.value.pve_node_vm_storage
    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = var.gateway_ip
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_account {
      keys     = [data.local_file.ssh_public_key.content]
      username = each.value.username
      password = each.value.password
    }

    meta_data_file_id = proxmox_virtual_environment_file.meta_data_cloud_config[each.value.hostname].id
  }

  network_device {
    bridge = each.value.pve_network_bridge
  }
  
  tags = ["Terraform", "k8s-node"]
}

resource "proxmox_virtual_environment_download_file" "cloud_image" {
  for_each = local.unique_download_targets

  content_type = "iso"
  datastore_id = each.value.datastore_id
  node_name    = each.value.node_name

  url = var.cloud_image_url
}

resource "local_file" "ansible_inventory_file" {
  filename = "${path.module}/inventory.generated"
  content  = local.inventory_file
}

resource "local_file" "hosts_file" {
  filename = "${path.module}/hosts.generated"
  content  = local.hosts_file
}