# Kubernetes Cluster Automation on Proxmox using Terraform and Ansible

## Overview

This project provides a highly customizable and automated solution for deploying Kubernetes clusters on a Proxmox VE environment. It leverages **Terraform** to provision virtual machines using cloud-init and **Ansible** to configure and bootstrap the VMs into a fully functional Kubernetes cluster.

You can create clusters that fit your exact needs—from a simple single-master setup to a highly available (HA) cluster with multiple control-plane nodes and load balancers. Thanks to the modular nature of the codebase, the number and role of VMs can be adjusted easily, offering flexibility for various scenarios.

> The Kubernetes setup process follows the official best practices outlined in the [kubernetes documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/).

## Tools & Stack

This project relies on a combination of tools and components to automate and manage the deployment of Kubernetes clusters in a Proxmox environment:

### Infrastructure & Automation
- **Terraform** – Automates VM provisioning on Proxmox using cloud-init and custom configuration.
- **Ansible** – Automates the configuration and bootstrapping of Kubernetes components.

### Kubernetes Components
- **Kubeadm** – Used to initialize and join Kubernetes control-plane and worker nodes.
- **kubectl** – CLI tool for managing Kubernetes clusters.
- **kubelet** - An agent that runs on each node in the cluster.

### Container Runtime
- **containerd** – Lightweight container runtime used as the default backend for Kubernetes.
- **runc** – Low-level container runtime used by containerd for spawning containers.
- **crictl** - CLI tool for interacting with container runtimes that implement the Kubernetes Container Runtime Interface (CRI)

### Networking & CNI
- **Cilium** – Recommended CNI (Container Network Interface) for advanced networking, security, and observability.
- **cilium-cli** – CLI tool to interact with and manage Cilium deployments.

### High Availability & Load Balancing
- **HAProxy** – Acts as a Layer 4/7 load balancer to distribute API server traffic across control-plane nodes.
- **Keepalived** – Provides failover and virtual IP (VIP) capabilities for multiple load balancers in an HA setup.

## Prerequisites

Before using this project, ensure that the following tools are installed on your setup machine:

- Terraform (>=`8.x`)
- Ansible (>=`2.18.x`)
- SSH key pair
- Properly configured `terraform.tfvars` 
- Access to a **Proxmox VE** cluster with Login/API credentials

## Cluster Topology Options

This system supports multiple cluster topologies depending on your high-availability (HA) and scalability needs:

### Basic Cluster

- 1 Master Node
- N Worker Nodes
- No load balancer

### Standard HA Cluster

- 3+ Master Nodes
- N Worker Nodes
- 1 Load Balancer node using HAProxy

### Advanced HA Cluster

- 3+ Master Nodes
- N Worker Nodes
- 2+ Load Balancer nodes (`keepalived` + `HAProxy`) used to ensure failover among load balancers

Each VM is configured dynamically using cloud-init templates, with parameters defined in Terraform variables. Whether you’re spinning up a minimal test cluster or a HA environment, the setup adapts to your needs.

## Usage

Follow these steps to use the project:

1. Clone the repo:

   ```sh
   git clone https://github.com/Tiagura/proxmox-k8s-IaC.git
   ```
  
2. Navigate to the [`/terraform`](./terraform) directory.  

3. Follow the instructions there to:
   - Configure your Proxmox credentials and environment
   - Customize VM specifications and cluster topology via `terraform.tfvars`
   - Use `terraform` to create the VMs

4. Navigate to the [`/ansible`](./terraform) directory.

5. Follow the instructions there to:
   - Configure the setuo machine
   - Set up and initialize the Kubernetes cluster with kubeadm
   - Join the other master nodes
   - Join worker nodes
   - Set up HAProxy and Keepalived for high availability (if configured)

## Some Important Notes
   - If the `pod_subnet` variable is not provided during the execution of the Ansible `playbook.yaml`, the default pod CIDR used will be `10.32.0.0/16`. Make sure that your chosen CNI plugin configuration is updated accordingly to avoid networking issues.
   - This setup is designed to be **managed from the setup machine** where Terraform and Ansible are executed. If you prefer to manage the cluster from a different machine:
     1. Copy the contents of the generated `hosts` file entries into the management machine’s `/etc/hosts`.
     2. Install `kubectl` on the target machine.
     3. Install `Cilium CLI` on the target machine.
     4. Copy the Kubernetes admin config from the initial setup machine:
        ```bash
        mkdir -p $HOME/.kube
        scp user@<setup-machine>:/etc/kubernetes/admin.conf $HOME/.kube/config
        chown $(id -u):$(id -g) $HOME/.kube/config
        ```
        Replace `<setup-machine>` with the IP or hostname of the initial setup machine and adjust the `user` accordingly.
   - By default, Cilium is installed using a simple command:
      ```bash
      cilium install --version {cilium_version} --set ipam.operator.clusterPoolIPv4PodCIDRList={pod_subnet}
      ```
      These default values are:
         `cilium_version: 1.17.5`
         `pod_subnet: 10.32.0.0/16`
      
      This works for most basic setups. However, if you require a more advanced or customized configuration (e.g., enabling the Kubernetes Gateway API, changing IPAM backends, enabling encryption, etc.), you should first uninstall Cilium:
      ```bash
      cilium uninstall
      ```
      Then, reinstall Cilium with your desired settings
