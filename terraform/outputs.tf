output "generated_proxmox_provider" {
  sensitive = true
  value     = local.provider_config
}

output "rendered_hosts_file" {
  value     = local.hosts_file
}

output "ansible_inventory_content" {
  value     = local.inventory_file
}