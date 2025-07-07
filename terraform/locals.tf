# Merge global variables with local variables for VMs
# Combine all VMs into one local variable for iteration
locals {
  lb_defaults = {
    lb_ciuser     = var.lb_ciuser
    lb_cipassword = var.lb_cipassword
    lb_cores      = var.lb_cores
    lb_memory     = var.lb_memory
    lb_disk       = var.lb_disk
  }

  load_balancers_with_defaults = [
    for lb in var.load_balancers : merge(local.lb_defaults,
                                          { for k, v in lb : k => v if v != null }
    )
  ]

  master_defaults = {
    master_ciuser     = var.master_ciuser
    master_cipassword = var.master_cipassword
    master_cores      = var.master_cores
    master_memory     = var.master_memory
    master_disk       = var.master_disk
  }

  masters_with_defaults = [
    for m in var.masters : merge(local.master_defaults,
                                  { for k, v in m : k => v if v != null }
    )
  ]

  worker_defaults = {
    worker_ciuser     = var.worker_ciuser
    worker_cipassword = var.worker_cipassword
    worker_cores      = var.worker_cores
    worker_memory     = var.worker_memory
    worker_disk       = var.worker_disk
  }

  workers_with_defaults = [
    for w in var.workers : merge(local.worker_defaults,
                                  { for k, v in w : k => v if v != null }  
    )
  ]

  all_vms = concat(
    # Combine all VMs into one list with defaults applied
    [for lb in local.load_balancers_with_defaults : {
      hostname              = lb.hostname
      ip                    = lb.ip
      pve_node              = lb.pve_node
      pve_node_datastore    = lb.pve_node_datastore
      pve_node_vm_storage   = lb.pve_node_vm_storage
      pve_network_bridge    = lb.pve_network_bridge
      username              = lb.lb_ciuser
      password              = lb.lb_cipassword
      cores                 = lb.lb_cores
      memory                = lb.lb_memory
      disk                  = lb.lb_disk
    }],
    [for m in local.masters_with_defaults : {
      hostname              = m.hostname
      ip                    = m.ip
      pve_node              = m.pve_node
      pve_node_datastore    = m.pve_node_datastore
      pve_node_vm_storage   = m.pve_node_vm_storage
      pve_network_bridge    = m.pve_network_bridge
      username              = m.master_ciuser
      password              = m.master_cipassword
      cores                 = m.master_cores
      memory                = m.master_memory
      disk                  = m.master_disk
    }],
    [for w in local.workers_with_defaults : {
      hostname              = w.hostname
      ip                    = w.ip
      pve_node              = w.pve_node
      pve_node_datastore    = w.pve_node_datastore
      pve_node_vm_storage   = w.pve_node_vm_storage
      pve_network_bridge    = w.pve_network_bridge
      username              = w.worker_ciuser
      password              = w.worker_cipassword
      cores                 = w.worker_cores
      memory                = w.worker_memory
      disk                  = w.worker_disk
    }]
  )
}

# Group the pve_nodes and pve_node_datastores to avoid downloading the same image multiple times
locals {
  unique_node_datastore_pairs = distinct([
    for node in local.all_vms :
    {
      node_name    = node.pve_node
      datastore_id = node.pve_node_datastore
      key          = "${node.pve_node}-${node.pve_node_datastore}"
    }
  ])

  unique_download_targets = {
    for pair in local.unique_node_datastore_pairs :
    pair.key => {
      node_name    = pair.node_name
      datastore_id = pair.datastore_id
    }
  }
}

# Generate a list of all VMs with their IPs and hostnames for the hosts file
locals {
  node_ips = [
    for vm in local.all_vms : {
      ip       = split("/", vm.ip)[0]       # removes /24
      hostname = vm.hostname
    }
  ]

  hosts_file = templatefile("${path.module}/hosts.tmpl", {
    node_ips = local.node_ips
    domain   = var.domain
  })
}

# Generate the Ansible inventory file from the VMs
locals {
  loadbalancers = [
    for vm in var.load_balancers : {
      ip       = split("/", vm.ip)[0]
      hostname = vm.hostname
      username = var.lb_ciuser
    }
  ]

  masters = [
    for vm in var.masters : {
      ip       = split("/", vm.ip)[0]
      hostname = vm.hostname
      username = var.master_ciuser
    }
  ]

  workers = [
    for vm in var.workers : {
      ip       = split("/", vm.ip)[0]
      hostname = vm.hostname
      username = var.worker_ciuser
    }
  ]

  inventory_file = templatefile("${path.module}/ansible_inventory.tmpl", {
    loadbalancers = local.loadbalancers
    masters       = local.masters
    workers       = local.workers
    // from data.local_file.ssh_public_key.filename remove .pub
    ssh_key_path = replace(data.local_file.ssh_public_key.filename, ".pub", "")
  })
}