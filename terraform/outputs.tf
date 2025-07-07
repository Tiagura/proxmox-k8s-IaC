output "rendered_hosts_file" {
  value = local.hosts_file
}

output "ansible_inventory_content" {
  value     = local.inventory_file
}