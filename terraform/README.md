# Terraform: Proxmox VM Provisioning for Kubernetes

This Terraform module provisions virtual machines on a Proxmox VE cluster for setting up a customizable Kubernetes environment. VMs are configured using cloud-init and grouped into roles (masters, workers, load balancers), ready for Ansible post-provisioning.

## Table of Contents

- [Terraform: Proxmox VM Provisioning for Kubernetes](#terraform-proxmox-vm-provisioning-for-kubernetes)
  - [Table of Contents](#table-of-contents)
  - [What This Module Does](#what-this-module-does)
  - [Proxmox Environment Setup](#proxmox-environment-setup)
    - [API Access and Authentication](#api-access-and-authentication)
    - [VM Disk Storage Considerations](#vm-disk-storage-considerations)
    - [Cloud Image Downloading](#cloud-image-downloading)
    - [Cloud Init Metadata File](#cloud-init-metadata-file)
  - [Setup Instructions](#setup-instructions)
    - [1. Configure `terraform.tfvars`](#1-configure-terraformtfvars)
    - [2. Initialize Terraform and Apply](#2-initialize-terraform-and-apply)
  - [VM Cloud Init and Resources configurations](#vm-cloud-init-and-resources-configurations)
    - [Load Balancer VM Object](#load-balancer-vm-object)
    - [Master Node VM Object](#master-node-vm-object)
    - [Worker Node VM Object](#worker-node-vm-object)
    - [Example: Defining Master Nodes](#example-defining-master-nodes)
  - [Output Files](#output-files)
    - [Proxmox Provider Configuration File](#proxmox-provider-configuration-file)
    - [Ansible Inventory File](#ansible-inventory-file)
    - [Hosts File](#hosts-file)
  - [Clean-Up](#clean-up)
  - [Next Steps](#next-steps)

## What This Module Does

- Connects to the Proxmox VE API
- Provisions VMs and assigns VM specs such as CPU, memory, disk, and network
- Injects cloud-init configuration into each VM
- Outputs an auto-generated Ansible inventory file based on the created infrastructure
- Generates a hosts file containing entries to be added to the /etc/hosts file on the setup machine

## Proxmox Environment Setup

Before running the Terraform configuration, certain Proxmox-specific settings should be reviewed and adjusted for security and compatibility.

### API Access and Authentication

This project uses **password-based authentication** to access the Proxmox API by default. While this works well for initial development, it is **not recommended for production** or secure environments. Instead, it is strongly advised to use **API tokens** and more restrictive user accounts.

Refer to the [bpg/proxmox Terraform Provider documentation](https://registry.terraform.io/providers/bpg/proxmox/latest/docs#ssh-connection) to learn how to configure alternative authentication methods, including SSH-based access and API tokens.

To implement these changes alter the [providers.tf](./providers.tf) file. 

> **Note:** By default, the configuration uses `root@pam`, which should also be avoided in production. Consider creating a Proxmox user with the minimum required permissions and a custom role for Terraform automation.

### VM Disk Storage Considerations

The location where VM disks are stored is controlled by the `pve_node_vm_storage` parameter inside each VM definition (load balancers, masters, and workers).

### Cloud Image Downloading

Terraform will download the required cloud image once **per unique pair** of `pve_node` and `pve_node_datastore` declared across all VM definitions (i.e. the lists of load_balancers, masters and workers). For example:

```hcl
masters = [ { ..., pve_node = "pv1", pve_node_datastore = "local" } ]
workers = [ { ..., pve_node = "pv2", pve_node_datastore = "local" } ]
```

In this case, Terraform will download the image **twice**, once for each unique node/datastore combo.

Ensure the target datastore has the **"Import"** content type enabled, as this is where the cloud-init image will be stored and referenced.

### Cloud Init Metadata File

Terraform will create a cloud-init metadata file for each VM and store it in the pve_node_vm_storage declared for that VM, similar to the behavior observed in [Cloud Image Downloading](#cloud-image-downloading). Ensure the target datastore has the **"Snippets"** content type enabled, as this file contains the necessary configurations.

## Setup Instructions

### 1. Configure `terraform.tfvars`

Create a file named `terraform.tfvars` with the required variables. Use the file `example.tfvars` as an example and edit it.

```bash
mv example.tfvars terraform.tfvars
nano terraform.tfvars
```

Adjust these values as needed based on your topology. Look into the full [terraform variables list](#vm-cloud-init-and-resources-configurations) for more variables and possible configurations

### 2. Initialize Terraform and Apply

Run the following commands:

1. Initialize the Terraform working directory.
```bash
terraform init
```

2. Generate the proxmox provider config file and review the output file `proxmox_provider.tf` to ensure it is correct
```bash
terraform apply -target=local_file.proxmox_provider_file
```

4. Generate the execution plan and review the output to ensure that the planned changes are correct
```bash
terraform plan -var-file="terraform.tfvars"
```

1. Apply the changes.
```bash
terraform apply -var-file="terraform.tfvars"
```

## VM Cloud Init and Resources configurations

The project provides several Terraform variables that allow you to customize the cluster to suit your needs. Below is a summary:

| Variable Name         | Description                            | Type     | Default / Required   |
| --------------------- | -------------------------------------- | -------- | -------------------- |
| `ssh_public_key_path` | Path to SSH public key                 | `string` | `~/.ssh/id_rsa.pub`  |
| `pve_api_url`         | Proxmox API URL                        | `string` | **Required**         |
| `pve_username`        | Proxmox username                       | `string` | `root@pam`           |
| `pve_password`        | Proxmox password                       | `string` | **Required**         |
| `pve_nodes`           | Mapping of Proxmox node names to IPs   | `map`    | **Required**         |
| `dns_servers`         | DNS servers for VMs                    | `list`   | `[1.1.1.1, 8.8.8.8]` |
| `domain`              | Domain name for nodes                  | `string` | `home.arpa`          |
| `gateway_ip`          | Gateway IP                             | `string` | **Required**         |
| `cloud_image_url`     | URL of Ubuntu cloud image              | `string` | Noble Cloud Img URL  |
| `vm_autostart`        | Enable autostart                       | `bool`   | `false`              |
| `timezone`            | Timezone of VMs                        | `string` | `Europe/London`      |
| `load_balancers`      | List of load balancer VM definitions   | `list`   | `[]`                 |
| `lb_ciuser`           | Cloud-init user for load balancers (can be empty/null if no load balancers are defined)     | `string` | **Required**         |
| `lb_cores`            | CPU cores per load balancer            | `number` | `1`                  |
| `lb_memory`           | RAM Memory (MB) per load balancer      | `number` | `512`                |
| `lb_disk`             | Disk size (GB) per load balancer       | `number` | `5`                  |
| `masters`             | List of master VM definitions          | `list`   | `[]`                 |
| `master_ciuser`       | Cloud-init user for masters            | `string` | **Required**         |
| `master_cores`        | CPU cores per master                   | `number` | `2`                  |
| `master_memory`       | RAM Memory (MB) per master             | `number` | `2048`               |
| `master_disk`         | Disk size (GB) per master              | `number` | `10`                 |
| `workers`             | List of worker VM definitions          | `list`   | `[]`                 |
| `worker_ciuser`       | Cloud-init user for workers            | `string` | **Required**         |
| `worker_cores`        | CPU cores per worker                   | `number` | `2`                  |
| `worker_memory`       | RAM Memory (MB) per worker             | `number` | `2048`               |
| `worker_disk`         | Disk size (GB) per worker              | `number` | `10`                 |

In addition to the general configuration, you can define detailed configurations for each VM role (load balancers, masters, and workers) by specifying lists of VM definitions. These objects allow per-VM customization for hostname, IP, resources, and Proxmox settings.

> The placement of each VM (i.e., which Proxmox node, cloud-init datastore, and VM disk storage it will use) is not automatically determined by defaults; it must be explicitly defined for each VM using the `pve_node`, `pve_node_datastore`, and `pve_node_vm_storage` fields.

### Load Balancer VM Object

| Field                 | Description                          | Type     | Required |
| --------------------- | ------------------------------------ | -------- | -------- |
| `hostname`            | Hostname of the VM                   | `string` | Yes      |
| `ip`                  | IP address of the VM                 | `string` | Yes      |
| `pve_node`            | Target Proxmox node                  | `string` | Yes      |
| `pve_node_datastore`  | Datastore name(for cloud img storage)| `string` | Yes      |
| `pve_node_vm_storage` | VM disk storage location             | `string` | Yes      |
| `pve_network_bridge`  | Network bridge interface             | `string` | Yes      |
| `lb_ciuser`           | Optional override of cloud-init user | `string` | No       |
| `lb_cores`            | Optional override of CPU cores       | `number` | No       |
| `lb_memory`           | Optional override of RAM memory (MB) | `number` | No       |
| `lb_disk`             | Optional override of disk size (GB)  | `number` | No       |

### Master Node VM Object

| Field                 | Description                          | Type     | Required |
| --------------------- | ------------------------------------ | -------- | -------- |
| `hostname`            | Hostname of the VM                   | `string` | Yes      |
| `ip`                  | IP address of the VM                 | `string` | Yes      |
| `pve_node`            | Target Proxmox node                  | `string` | Yes      |
| `pve_node_datastore`  | Datastore name(for cloud img storage)| `string` | Yes      |
| `pve_node_vm_storage` | VM disk storage location             | `string` | Yes      |
| `pve_network_bridge`  | Network bridge interface             | `string` | Yes      |
| `master_ciuser`       | Optional override of cloud-init user | `string` | No       |
| `master_cores`        | Optional override of CPU cores       | `number` | No       |
| `master_memory`       | Optional override of RAM memory (MB) | `number` | No       |
| `master_disk`         | Optional override of disk size (GB)  | `number` | No       |

### Worker Node VM Object

| Field                 | Description                          | Type     | Required |
| --------------------- | ------------------------------------ | -------- | -------- |
| `hostname`            | Hostname of the VM                   | `string` | Yes      |
| `ip`                  | IP address of the VM                 | `string` | Yes      |
| `pve_node`            | Target Proxmox node                  | `string` | Yes      |
| `pve_node_datastore`  | Datastore name(for cloud img storage)| `string` | Yes      |
| `pve_node_vm_storage` | VM disk storage location             | `string` | Yes      |
| `pve_network_bridge`  | Network bridge interface             | `string` | Yes      |
| `worker_ciuser`       | Optional override of cloud-init user | `string` | No       |
| `worker_cores`        | Optional override of CPU cores       | `number` | No       |
| `worker_memory`       | Optional override of RAM memory (MB) | `number` | No       |
| `worker_disk`         | Optional override of disk size (GB)  | `number` | No       |

### Example: Defining Master Nodes

Below is an example of how to define a list of Kubernetes master nodes with both shared and per-node configurations:

```hcl
masters = [
  { hostname = "k8s-master-1", ip = "<IP1>/<MASK>", pve_node = "pv1", pve_node_datastore = "local1", pve_node_vm_storage = "local-lvm1", pve_network_bridge = "vmbr0", master_ciuser="diff_user"},
  { hostname = "k8s-master-2", ip = "<IP2>/<MASK>", pve_node = "pv2", pve_node_datastore = "local2", pve_node_vm_storage = "local-lvm2", pve_network_bridge = "vmbr0", master_cores=4 },
  { hostname = "k8s-master-3", ip = "<IP3>/<MASK>", pve_node = "pv2", pve_node_datastore = "local2", pve_node_vm_storage = "local-lvm2", pve_network_bridge = "vmbr0" }
]

master_ciuser     = "user"
master_cores      = 2
master_memory     = 2048
master_disk       = 10
```

By this definition:
- VM 1 (`hostname = "k8s-master-1"`) will have a custom cloud-init user `diff_user` and password `diff_pwd`. It will be created on Proxmox node `pv1`, use the cloud-init image on `local1`, and store its VM disk in `local-lvm1`.
- VM 2 (`hostname = "k8s-master-2"`) will override the default CPU cores and use `4` cores. It will be created on Proxmox node `pv2`, use the cloud-init image on `local2`, and store its VM disk in `local-lvm2`.
- VM 3 (`hostname = "k8s-master-3"`) will use all default values defined previouslly (i.e. `master_ciuser`, `master_cores`, `master_memory`, `master_disk`). It will be created on Proxmox node `pv2`, use the cloud-init image on `local2`, and store its VM disk in `local-lvm2`.

## Output Files

After successful deployment, Terraform will generate several useful output files to assist in configuring your Kubernetes cluster, managing VM access and more.

### Proxmox Provider Configuration File

Before running `terraform apply` to provision VMs, you must first [generate the dynamic Proxmox provider file](#2-initialize-terraform-and-apply). This file contains the SSH mappings for all Proxmox nodes. Terraform uses this file to connect to the nodes during VM provisioning.

```ini
provider "proxmox" {
  endpoint = "<proxmox_api_url>"
  username = "<username>"
  password = "<password>"
  insecure = true

  ssh {
    agent = true

    ### Blocks from the pve_nodes map
    node {
      name    = "pve1"
      address = "<IP1>"
    }

    node {
      name    = "pve2"
      address = "<IP2>"
    }
    ### 
  }
}
```

### Ansible Inventory File

An inventory file will be generated using the `ansible_inventory.tmpl` template:

```ini
[loadbalancers]
# Generated entries for load balancers

[masters]
# Generated entries for master nodes

[workers]
# Generated entries for worker nodes
```

Each entry includes SSH access details for Ansible, such as `ansible_host`, `ansible_user`, and private key path.

### Hosts File

A hosts file will be generated using the `hosts.tmpl` template:

```ini
<IP> <VM-Hostaname>.<domain> <VM-Hostaname>
```

This file enables communication between the created VMs via DNS records, which is crucial for K8s. The setup machine will also use this file to access the created VMs.

## Clean-Up

To destroy all created resources:

```bash
terraform destroy
```

## Next Steps

After Terraform completes:

1. Navigate to the [`/ansible`](../ansible) directory.
2. Follow the instructions on 


