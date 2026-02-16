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
      - systemctl start qemu-guest-agent
      - systemctl enable qemu-guest-agent
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
    # Issue: https://github.com/bpg/terraform-provider-proxmox/issues/2091
    # Commit: https://github.com/sulibot/home-ops/commit/e121348869dbfcf151f4ffd583bede2ff30240d4
    enabled = false
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

  content_type = "import"
  datastore_id = each.value.datastore_id
  node_name    = each.value.node_name

  url = var.cloud_image_url
  # extrach the filename from the url and replace the extension with .qcow2
  file_name = "${regex("([^/]+)\\.[^/.]+$", var.cloud_image_url)[0]}.qcow2"
}

resource "local_file" "ansible_inventory_file" {
  filename = "${path.module}/inventory.generated"
  content  = local.inventory_file
}

resource "local_file" "hosts_file" {
  filename = "${path.module}/hosts.generated"
  content  = local.hosts_file
}