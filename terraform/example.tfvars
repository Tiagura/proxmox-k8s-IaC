ssh_public_key_path = "~/.ssh/id_rsa.pub"

pve_api_url = "https://<IP_or_DNS_to_PROXMOX>:8006/api2/json"
pve_username = "<user>@<realm>"
pve_password = "<password>"

gateway_ip = "<gateway_ip>" # e.g., "10.0.0.1"
domain = "home.arpa"        # Preferred domain for local networks

# PVE Nodes
pve_nodes = {
  # <node_name> = "<node_ip>"
  pve1 = "<IP1>"
  pve2 = "<IP2>"
  pve3 = "<IP3>"
}

# VM Configuration

load_balancers = [
  { hostname = "k8s-lb-1", ip = "<IP1>/<MASK>", pve_node = "pve1", pve_node_datastore = "local", pve_node_vm_storage = "local-lvm", pve_network_bridge = "vmbr0" },
  { hostname = "k8s-lb-2", ip = "<IP2>/<MASK>", pve_node = "pve2", pve_node_datastore = "local", pve_node_vm_storage = "local-lvm", pve_network_bridge = "vmbr0" }
]
lb_ciuser                = "lb_user"
lb_cipassword            = "lb_password"
lb_cores                 = 1
lb_memory                = 512
lb_disk                  = 5

masters = [
  { hostname = "k8s-master-1", ip = "<IP3>/<MASK>", pve_node = "pve1", pve_node_datastore = "local", pve_node_vm_storage = "local-lvm", pve_network_bridge = "vmbr0" },
  { hostname = "k8s-master-2", ip = "<IP4>/<MASK>", pve_node = "pve2", pve_node_datastore = "local", pve_node_vm_storage = "local-lvm", pve_network_bridge = "vmbr0" },
  { hostname = "k8s-master-3", ip = "<IP5>/<MASK>", pve_node = "pve3", pve_node_datastore = "local", pve_node_vm_storage = "local-lvm", pve_network_bridge = "vmbr0" }
]
master_ciuser              = "master_user"
master_cipassword          = "master_password"
master_cores               = 2
master_memory              = 2048
master_disk                = 10

workers = [
  { hostname = "k8s-worker-1", ip = "<IP6>/<MASK>", pve_node = "pve1", pve_node_datastore = "local", pve_node_vm_storage = "local-lvm", pve_network_bridge = "vmbr0" },
  { hostname = "k8s-worker-2", ip = "<IP7>/<MASK>", pve_node = "pve2", pve_node_datastore = "local", pve_node_vm_storage = "local-lvm", pve_network_bridge = "vmbr0" }
]
worker_ciuser              = "worker_user"
worker_cipassword          = "worker_password"
worker_cores               = 2
worker_memory              = 2048
worker_disk                = 10
