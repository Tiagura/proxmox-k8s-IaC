# Kubernetes Cluster Automation on Proxmox using Terraform and Ansible – **Custom Branch**

## Overview

This branch is my **personalized setup** for creating Kubernetes clusters in my homelab.  
While the [`main branch`](https://github.com/Tiagura/proxmox-k8s-IaC/tree/main) provides a **general-purpose cluster definition**, this **custom branch** is adapted to fit my specific needs and workflow. This branch will **always track updates** from `main` (versions of Kubernetes, CNIs, tooling, etc.). 

Key differences compared to the `main` branch:

### Networking

[Cilium](https://cilium.io/) is used as the cluster's CNI. And will also be used to replace the `kube-proxy` component.

- The Gateway API is enabled by default.
- The installation of the `kube-proxy` is **skipped**
  - Cilium **replaces** `kube-proxy`, leaving kube-proxy enabled would cause conflicts.  
- The **CNI choice remains flexible** – Cilium is **not installed automatically** by this setup. You can pick a CNI of your choice as long as:
  - It is **compatible with Gateway API**.
  - It can **replace or bypass kube-proxy**.

For reference, my working **Cilium configuration** can be found [here](https://github.com/Tiagura/k8s-gitops/tree/main/infrastructure/networking/cilium)

### Storage

[Longhorn](https://longhorn.io/) is used as the primary storage solution in this setup. Some adjustments were necessary to ensure Longhorn operates smoothly:

- The `dm_crypt` kernel module is loaded.

- The `multipathd` service is disabled, as it can [conflict](https://longhorn.io/kb/troubleshooting-volume-with-multipath/) with Longhorn’s storage operations.

These tweaks ensure that Longhorn can manage persistent volumes reliably without interference from system-level services.



> If you're curious about my cluster and its services, I use a GitOps approach with ArgoCD and the files with the documentation can be found in the [here](https://github.com/Tiagura/k8s-gitops/tree/main)