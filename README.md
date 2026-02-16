# Kubernetes Cluster Automation on Proxmox using Terraform and Ansible

## Overview

This project provides a highly customizable and automated solution for deploying Kubernetes clusters on a Proxmox VE environment. It leverages **Terraform** to provision virtual machines using cloud-init and **Ansible** to configure and bootstrap the VMs into a fully functional Kubernetes cluster.

You can create clusters that fit your exact needs—from a simple single-master setup to a highly available (HA) cluster with multiple control-plane nodes and load balancers. Thanks to the modular nature of the codebase, the number and role of VMs can be adjusted easily, offering flexibility for various scenarios.

> The Kubernetes setup process follows the official best practices outlined in the [kubernetes documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/).

## Table of Contents

- [Kubernetes Cluster Automation on Proxmox using Terraform and Ansible](#kubernetes-cluster-automation-on-proxmox-using-terraform-and-ansible)
  - [Overview](#overview)
  - [Table of Contents](#table-of-contents)
  - [Tools \& Stack](#tools--stack)
    - [Infrastructure \& Automation](#infrastructure--automation)
    - [Kubernetes Components](#kubernetes-components)
    - [Container Runtime](#container-runtime)
    - [CNI Plugins](#cni-plugins)
    - [High Availability \& Load Balancing](#high-availability--load-balancing)
    - [Kubernetes Cluster Config Options](#kubernetes-cluster-config-options)
  - [Prerequisites](#prerequisites)
  - [Cluster Topology Options](#cluster-topology-options)
  - [Usage](#usage)
  - [Some Important Notes](#some-important-notes)
    - [Terraform](#terraform)
    - [Kubernetes](#kubernetes)

## Tools & Stack

This project relies on a combination of tools and components to automate and manage the deployment of Kubernetes clusters in a Proxmox environment:

### Infrastructure & Automation
- **Terraform** - Automates VM provisioning on Proxmox using cloud-init and custom configuration.
- **Ansible** - Automates the configuration and bootstrapping of Kubernetes components.

### Kubernetes Components
- **Kubeadm** - Used to initialize and join Kubernetes control-plane and worker nodes.
- **kubectl** - CLI tool for managing Kubernetes clusters.
- **kubelet** - An agent that runs on each node in the cluster.

### Container Runtime
- **containerd** - Lightweight container runtime used as the default backend for Kubernetes.
- **runc** - Low-level container runtime used by containerd for spawning containers.
- **crictl** - CLI tool for interacting with container runtimes that implement the Kubernetes Container Runtime Interface (CRI)

### CNI Plugins
- [**containernetworking/plugins**](https://github.com/containernetworking/plugins) - Enables cluster networking

### High Availability & Load Balancing
- **HAProxy** - Acts as a Layer 4/7 load balancer to distribute API server traffic across control-plane nodes.
- **Keepalived** - Provides failover and virtual IP (VIP) capabilities for multiple load balancers in an HA setup.

### Kubernetes Cluster Config Options
- **Control Plane Endpoint** - DNS or IP address used by clients and nodes to reach the Kubernetes API server.
- **Control Plane Endpoint Port** - TCP port on which the Kubernetes API server listens.
- **Skip Kube-Proxy Install** - Skip installing kube-proxy on nodes.
- **Pod Subnet CIDR** - Define Kubernetes Pod network CIDR.
- **Service Subnet CIDR** - Define Kubernetes Service network CIDR.

## Prerequisites

Before using this project, ensure that the following tools are installed on your setup machine:

- Terraform (>=`8.x`)
- Ansible (>=`2.18.x`)
- SSH key pair
- Properly configured `terraform.tfvars` 
- Access to a **Proxmox VE** cluster with Login/API credentials

## Cluster Topology Options

This project supports multiple cluster topologies depending on your high-availability (HA) and scalability needs, and also allows passing additional configuration options to the cluster. See example of [supported cluster topologies](./ansible/README.md/#usage-examples-by-topology).
Each created VM is configured dynamically using cloud-init templates, with parameters defined in Terraform variables. Whether you’re spinning up a minimal test cluster or a HA environment, the setup can be adapted to your needs.

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

### Terraform
   - **QEMU guest agent is disabled by default** because enabling it causes Terraform to hang until the timeout (default 15 minutes). Various fixes were attempted but didn’t resolve the issue. If your use case requires the agent, you can enable it, but it is recommended to reduce the timeout (e.g., 5 minutes) depending on your Proxmox node performance.
   - **VM creation parallelism**: creating multiple VMs in parallel may result in some VMs failing with an HTTP 500 “username not set” error, even though the username is set. As a workaround, you can reduce Terraform’s parallelism (with the flag `-parallelism=` set). Test different values to find what works best for your environment ( in my case is it 3/4).

### Kubernetes
   - **No container network interface (CNI)** is installed in the resulting cluster, pick your CNI of choice and install it.
   - If the `pod_subnet` variable is not provided during the execution of the Ansible `playbook.yaml`, the default pod CIDR used will be `10.32.0.0/16`. Make sure that your chosen CNI configuration is updated accordingly to avoid networking issues.
   - This setup is designed to be **managed from the setup machine** where Terraform and Ansible are executed. If you prefer to manage the cluster from a different machine:
     1. Copy the contents of the generated `hosts` file entries into the management machine’s `/etc/hosts`.
     2. Install `kubectl` on the target machine.
     3. Copy the Kubernetes admin config from the initial setup machine:
        ```bash
        mkdir -p $HOME/.kube
        scp user@<setup-machine>:/etc/kubernetes/admin.conf $HOME/.kube/config
        chown $(id -u):$(id -g) $HOME/.kube/config
        ```
        Replace `<setup-machine>` with the IP or hostname of the initial setup machine and adjust the `user` accordingly.
