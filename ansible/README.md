# Ansible Configuration for Kubernetes Cluster Setup

This Ansible module provides provisioning and configuring a Kubernetes cluster across multiple nodes. The Ansible configuration is split into **two playbooks**, each responsible for a different stage in the cluster setup process.

## Playbook 1: `local-setup.yml`

This playbook prepares the setup machine and is executed with:
```bash
ansible-playbook local-setup.yml --ask-become-pass
```

### Responsibilities:
- Parses Terraform outputs.
- Generate `inventory.ini`.
- Install required tools.
- Update `/etc/hosts` on setup machine.

## Playbook 2: `cluster-setup.yaml`

This playbook installs and configures Kubernetes components and provides other needed configurations across all cluster nodes.

### Responsibilities:
- Install required packages on each node depending on its role (load balancer, master, worker).
- Initialize the Kubernetes control plane (using `kubeadm`).
- Join worker nodes to the cluster.
- Configure optional load balancers if present.
- Install the CNI plugin (default is Cilium).

### Usage Examples by Topology

#### Basic Cluster
- **Topology:**
  - 1 Master Node
  - N Worker Nodes
  - No Load Balancer

- **Command:**
  ```bash
  ansible-playbook cluster-setup.yml -e "control_plane_endpoint=<IP_or_DNS>" -i inventory.ini
  ```

- **Notes:**
   If control_plane_endpoint is not provided, Ansible will default to using the IP of the master node.

#### Standard HA Cluster
- **Topology:**
  - 3+ Master Nodes
  - N Worker Nodes
  - 1 Load Balancer Node (HAProxy)

- **Command:**
  ```bash
  ansible-playbook cluster-setup.yml -e "control_plane_endpoint=<IP_or_DNS>" -i inventory.ini
  ```

- **Notes:**
  If `control_plane_endpoint` is not provided, Ansible will default to using the IP of the load balancer node.

#### Highly Available Cluster with Keepalived
- **Topology:**
  - 3+ Master Nodes
  - N Worker Nodes
  - 2+ Load Balancer Nodes (Keepalived + HAProxy)

- **Command:**
  ```bash
  ansible-playbook cluster-setup.yml -e "vip_address=<VIRTUAL_IP> control_plane_endpoint=<IP_or_DNS> keepalived_interface=<interface> lb_pass=<lb_pwd>" -i inventory.ini
  ```

- **Required Variables:**
  - `vip_address`: Virtual IP to be managed by Keepalived
  - `keepalived_interface`: Network interface for Keepalived (e.g., `eth0`)
  - `lb_pass`: Password for Keepalived auth (e.g. pwd used for loadbalancers `lb_cipassword`)

- **Notes:**
  If `control_plane_endpoint` is not provided, Ansible will default to using the `vip_address`.

## Extra Configuration Variables

> Any variable below can be overridden using the `-e` flag on the command line. If not passed, Ansible looks for an environment variable. If that is also unset, the default value is used.

### General Cluster Parameters

| Variable                      | Default Value   | Description                                                                                                                      |
|------------------------------|-----------------|----------------------------------------------------------------------------------------------------------------------------------|
| `control_plane_endpoint`      | *auto-detected* | DNS/IP for Kubernetes control plane access. Defaults to the IP of master/load balancer/vip depending on topology. It is recommended to use a DNS record because it allows flexibility in changing the backend IP (e.g., when scaling or replacing load balancer/master nodes) without reconfiguring clients or the cluster.           |
| `control_plane_endpoint_port` | `6443`          | Kubernetes API server port.                                                                                                      |
| `pod_subnet`                  | `10.32.0.0/16`  | CIDR for Kubernetes pod network. Passed to Cilium.                                                                               |

### Runtime & Networking Components

| Variable             | Default Value  | Description                                                 |
|----------------------|----------------|-------------------------------------------------------------|
| `cni_version`        | `1.3.0`        | Version of CNI plugins used for container networking.       |
| `containerd_version` | `2.1.3`        | Version of containerd runtime.                              |
| `crictl_version`     | `1.33.0`       | Version of CRI tools.                                       |
| `runc_version`       | `1.3.0`        | Version of `runc` used as the container runtime shim.       |

### Kubernetes Components

| Variable                      | Default Value  | Description                          |
|-------------------------------|----------------|--------------------------------------|
| `k8s_release_version`         | `1.33.2`       | Kubernetes version to be installed.  |
| `k8s_service_release_version` | `0.16.2`       | Version of Kubernetes services.      |
| `kubectl_version`             | `1.33.2`       | Version of `kubectl` CLI tool.       |

### Cilium CNI Plugin

| Variable             | Default Value  | Description                        |
|----------------------|----------------|------------------------------------|
| `cilium_version`     | `1.17.5`       | Version of Cilium to install.      |
| `cilium_cli_version` | `0.18.5`       | Version of the Cilium CLI tool.    |

### HA Load Balancer Parameters

| Variable              | Default Value | Description                                                               |
|-----------------------|----------------|--------------------------------------------------------------------------|
| `vip_address`         | `""`           | Required virtual IP for HA clusters.                                     |
| `keepalived_interface`| `""`           | Interface used by Keepalived (e.g., `eth0`). Must be defined for HA.     |
| `lb_pass`             | `""`           | Password used by Keepalived for authentication. Must be defined for HA.  |


