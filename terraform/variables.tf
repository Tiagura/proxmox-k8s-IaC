# Common Variables

# SSH Key
variable "ssh_public_key_path" {
  description = "Path to the SSH public key for VM access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "pve_nodes" {
  description = "Mapping of Proxmox node names to their IP addresses"
  type = map(string)
}

# PVE Variables
variable "pve_api_url" {
  description = "Proxmox VE API URL"
  type        = string
}

variable "pve_username" {
  description = "Proxmox VE username"
  type        = string
  default     = "root@pam"
}

variable "pve_password" {
  description = "Proxmox VE password"
  type        = string
  sensitive = true
}

# Network Variables
variable "dns_servers" {
  description = "List of DNS servers for the VM"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "domain" {
  description = "Domain for the cluster nodes"
  type        = string
  default     = "home.arpa"
}

variable "gateway_ip" {
  description = "Gateway IP for VMs"
  type        = string
}

# VMs Settings/Behavior
variable "cloud_image_url" {
  description = "URL of the cloud image to use for VMs"
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "vm_autostart" {
  description = "Enable autostart for VMs"
  type        = bool
  default     = false
}

variable "timezone" {
  description = "Timezone for the VMs"
  type        = string
  default     = "Europe/London"
}

# Load Balancers VM Settings
variable "load_balancers" {
  description = "List of load balancers with name and IP"
  type = list(object({
    hostname = string
    ip       = string
    pve_node = string
    pve_node_datastore = string
    pve_node_vm_storage = string
    pve_network_bridge = string
    lb_ciuser = optional(string)
    lb_cores = optional(number)
    lb_memory = optional(number)
    lb_disk = optional(number)
  }))
  default = []
}

variable "lb_ciuser" {
  description = "Cloud-init username for load balancers"
  type        = string
}

variable "lb_cores" {
  description = "Number of CPU cores for load balancers"
  type        = number
  default     = 1
}

variable "lb_memory" {
  description = "RAM (MB) for load balancers"
  type        = number
  default     = 512
}

variable "lb_disk" {
  description = "Disk size (GB) for load balancers"
  type        = number
  default     = 5
}

# Masters VM Settings
variable "masters" {
  description = "List of master nodes"
  type = list(object({
    hostname = string, 
    ip       = string
    pve_node = string
    pve_node_datastore = string
    pve_node_vm_storage = string
    pve_network_bridge = string
    master_ciuser = optional(string)
    master_cores = optional(number)
    master_memory = optional(number)
    master_disk = optional(number)
  }))
  default = []
}

variable "master_ciuser" {
  description = "Cloud-init username for masters"
  type        = string
}

variable "master_cores" {
  description = "Number of CPU cores for masters"
  type        = number
  default     = 2
}

variable "master_memory" {
  description = "RAM (MB) for masters"
  type        = number
  default     = 2048
}

variable "master_disk" {
  description = "Disk size (GB) for masters"
  type        = number
  default     = 10
}

# Workers VM Settings
variable "workers" {
  description = "List of worker nodes"
  type = list(object({
    hostname = string
    ip       = string
    pve_node = string
    pve_node_datastore = string
    pve_node_vm_storage = string
    pve_network_bridge = string
    worker_ciuser = optional(string)
    worker_cores = optional(number)
    worker_memory = optional(number)
    worker_disk = optional(number)
  }))
  default = []
}

variable "worker_ciuser" {
  description = "Cloud-init username for workers"
  type        = string
}

variable "worker_cores" {
  description = "Number of CPU cores for workers"
  type        = number
  default     = 2
}

variable "worker_memory" {
  description = "RAM (MB) for workers"
  type        = number
  default     = 2048
}

variable "worker_disk" {
  description = "Disk size (GB) for workers"
  type        = number
  default     = 10
}

