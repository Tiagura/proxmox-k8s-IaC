# Ansible Configuration for Kubernetes Cluster Setup

This Ansible module provides provisioning and configuring a Kubernetes cluster across multiple nodes. The Ansible configuration is split into **two playbooks**, each responsible for a different stage in the cluster setup process.

## Table of Contents

- [Ansible Configuration for Kubernetes Cluster Setup](#ansible-configuration-for-kubernetes-cluster-setup)
  - [Table of Contents](#table-of-contents)
  - [Playbook 1: `local-setup.yml`](#playbook-1-local-setupyml)
    - [Responsibilities:](#responsibilities)
  - [Playbook 2: `cluster-setup.yaml`](#playbook-2-cluster-setupyaml)
    - [Responsibilities:](#responsibilities-1)
    - [Usage Examples by Topology](#usage-examples-by-topology)
      - [Basic Cluster](#basic-cluster)
      - [Standard HA Cluster](#standard-ha-cluster)
        - [Single Dedicated Load Balancer](#single-dedicated-load-balancer)
        - [Highly Available Cluster with embebbed LoadBalancers](#highly-available-cluster-with-embebbed-loadbalancers)
        - [Highly Available Cluster with external LoadBalancers](#highly-available-cluster-with-external-loadbalancers)
    - [HA Health-Check Matrix](#ha-health-check-matrix)
  - [Extra Configuration Variables](#extra-configuration-variables)
    - [Cloud Init Bootstrap Parameters](#cloud-init-bootstrap-parameters)
    - [General Cluster Parameters](#general-cluster-parameters)
    - [Runtime \& Networking Components](#runtime--networking-components)
    - [Kubernetes Components](#kubernetes-components)
    - [HA Load Balancer Parameters](#ha-load-balancer-parameters)

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
   If `control_plane_endpoint` is not provided, Ansible will default to using the IP of the master node.

#### Standard HA Cluster
In a standard HA cluster, the control plane can be made highly available by embedding HA components on the master nodes or using dedicated load balancer VMs; kube-vip is another option but is not implemented in this project.

##### Single Dedicated Load Balancer

- **Topology:**
  - 3+ Master Nodes
  - N Worker Nodes
  - 1 Load Balancer Node

- **Command:**
  ```bash
  ansible-playbook cluster-setup.yml -e "control_plane_endpoint=<IP_or_DNS>" -i inventory.ini
  ```

- **Notes:**
  If `control_plane_endpoint` is not provided, Ansible will default to using the IP of the load balancer node. Keepalived is not configured for a single load balancer; HAProxy checks the master nodes directly.

##### Highly Available Cluster with embebbed LoadBalancers

- **Topology:**
  - 3+ Master Nodes
  - N Worker Nodes
  - 0 Load Balancer Node

- **Command:**
  ```bash
  ansible-playbook cluster-setup.yml -e "vip_address=<VIRTUAL_IP/MASK> control_plane_endpoint=<VIP_or_DNS> embedded_ha_control_plane=true keepalived_interface=<interface> keepalived_pwd=<pwd>" -i inventory.ini
  ```

- **Required Variables:**
  - `vip_address`: Virtual IP to be managed by Keepalived
  - `embedded_ha_control_plane`: Set to `true`
  - `keepalived_interface`: Network interface for Keepalived (e.g., `eth0`)
  - `keepalived_pwd`: Password for Keepalived auth

- **Notes:**
  If `control_plane_endpoint` is not provided, Ansible will default to using the host portion of `vip_address`. Keepalived manages the VIP and checks the local Kubernetes API `/livez` endpoint. HAProxy is not configured on embedded masters because kube-apiserver already owns port `6443`.

##### Highly Available Cluster with external LoadBalancers
- **Topology:**
  - 3+ Master Nodes
  - N Worker Nodes
  - 2+ Load Balancer Nodes

- **Command:**
  ```bash
  ansible-playbook cluster-setup.yml -e "vip_address=<VIRTUAL_IP/MASK> control_plane_endpoint=<VIP_or_DNS> keepalived_interface=<interface> keepalived_pwd=<pwd>" -i inventory.ini
  ```

- **Required Variables:**
  - `vip_address`: Virtual IP to be managed by Keepalived
  - `keepalived_interface`: Network interface for Keepalived (e.g., `eth0`)
  - `keepalived_pwd`: Password for Keepalived auth

- **Notes:**
  If `control_plane_endpoint` is not provided, Ansible will default to using the host portion of `vip_address`. Keepalived manages the VIP, while HAProxy listens on `*:6443` and checks the master nodes directly.

### HA Health-Check Matrix

The health-check script runs `curl -k https://127.0.0.1:6443/livez`. In embedded mode this checks the local Kubernetes API server. On external load balancers it checks the local HAProxy listener, which in turn must reach a healthy API backend.

| Scenario | HAProxy configured on | Keepalived configured on | Keepalived health check | HAProxy backend health check | VIP behavior |
|----------|-----------------------|--------------------------|-------------------------|-----------------------------|--------------|
| 1 Master | None | None | None | None | No floating VIP; master IP is used |
| 2+ Masters | None in non-embedded mode | Masters when `embedded_ha_control_plane=true` | Local Kubernetes API `/livez` | None | Keepalived can move the VIP between masters; no load balancing from HAProxy |
| 1 LB and 2+ Masters | LB | None | None | LB checks every master's HTTPS `/livez` endpoint | No floating VIP; single LB IP is used |
| 2+ LBs and 2+ Masters | Every LB | Every LB | Local HAProxy listener, which checks `/livez` through its backend | Every LB checks every master's HTTPS `/livez` endpoint | VIP moves between LBs when the local health check fails |

HAProxy listens on `*:6443` and uses HTTPS `/livez` checks with certificate verification disabled. Keepalived uses the same local probe through `track_script`; it is not limited to ICMP ping or node reachability.

## Extra Configuration Variables

> Any variable below can be overridden using the `-e` flag on the command line. If not passed, Ansible looks for an environment variable. If that is also unset, the default value is used.

### Cloud Init Bootstrap Parameters

| Variable | Default Value  | Description |
|----------|----------------|-------------|
| `disable_multipath` | `false` | If set to `true`, disables and stops the multipathd service during bootstrap to prevent multipath device management on the node. |

### General Cluster Parameters

| Variable | Default Value  | Description |
|----------|----------------|-------------|
| `control_plane_endpoint`      | *auto-detected* | DNS/IP for Kubernetes control plane access. Defaults to the IP of master/load balancer/vip depending on topology. It is recommended to use a DNS record because it allows flexibility in changing the backend IP (e.g., when scaling or replacing load balancer/master nodes) without reconfiguring clients or the cluster.           |
| `control_plane_endpoint_port` | `6443`          | Kubernetes API server port.                 |
| `skip_kube_proxy`             | `false`         | Flag to skip the installation of kube-proxy.|
| `pod_subnet`                  | `10.32.0.0/16`  | CIDR for Kubernetes pod network.            |
| `service_subnet`              | `10.96.0.0/12`  | CIDR for Kubernetes service network.        |

### Runtime & Networking Components

| Variable             | Default Value  | Description                                                 |
|----------------------|----------------|-------------------------------------------------------------|
| `cni_version`        | [`version`](./roles/install-cni/defaults/main.yml) | Version of CNI plugins used for container networking.       |
| `containerd_version` | [`version`](./roles/install-containerd/defaults/main.yml) | Version of `containerd` runtime |
| `crictl_version`     | [`version`](./roles/install-crictl/defaults/main.yml) | Version of CRI tools.                                       |
| `runc_version`       | [`version`](./roles/install-runc/defaults/main.yml) | Version of `runc` used as the container runtime shim.       |

### Kubernetes Components

| Variable                      | Default Value  | Description                          |
|-------------------------------|----------------|--------------------------------------|
| `k8s_release_version`         | [`version`](./roles/install-kubeadm-kubelet/defaults/main.yml)  | Kubernetes version to be installed.  |
| `k8s_service_release_version` | [`version`](./roles/install-kubeadm-kubelet/defaults/main.yml)  | Version of Kubernetes services.      |
| `kubectl_version`             | [`version`](./roles/install-kubectl/defaults/main.yml)          | Version of `kubectl` CLI tool.       |

### HA Load Balancer Parameters

| Variable              | Default Value | Description                                                               |
|-----------------------|----------------|--------------------------------------------------------------------------|
| `vip_address`         | `""`           | Required virtual IP, with mask, for HA clusters.                                     |
| `keepalived_interface`| `""`           | Interface used by Keepalived (e.g., `eth0`). Must be defined for HA.     |
| `keepalived_pwd`             | `""`           | Password used by Keepalived for authentication. Must be defined for HA.  |

Keepalived uses `/usr/local/bin/check-kubernetes-api.sh` as an application health check. In embedded mode it checks the local Kubernetes API directly; on external load balancers it checks the local HAProxy listener and its Kubernetes API backend. HAProxy also checks each master through the Kubernetes API `/livez` endpoint rather than only checking whether TCP port `6443` is open.


