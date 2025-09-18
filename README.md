# Kubernetes Cluster Automation on Proxmox using Terraform and Ansible – **Custom Branch**

## Overview

This branch is my **personalized setup** for creating Kubernetes clusters in my homelab.  
While the [`main branch`](https://github.com/Tiagura/proxmox-k8s-IaC/tree/main) provides a **general-purpose cluster definition**, this **custom branch** is adapted to fit my specific needs and workflow.  

Key differences compared to the `main` branch:
- This branch will **always track updates** from `main` (versions of Kubernetes, CNIs, tooling, etc.).
- It introduces **Gateway API support** by default.
- It **skips the installation of `kube-proxy`** during cluster initialization, because in my homelab I run **Cilium with Gateway API**.  
  - Since Cilium can **act as or bypass kube-proxy**, leaving kube-proxy enabled causes conflicts.  
  - By removing kube-proxy, Cilium takes over traffic management more cleanly.
- **CNI choice remains flexible** – Cilium is **not installed automatically** by this setup. You can pick a CNI of your choice as long as:
  - It is **compatible with Gateway API**.
  - It can **replace or bypass kube-proxy**.  

For reference, my working **Cilium configuration** can be found [here](https://github.com/Tiagura/k8s-gitops/tree/main/infrastructure/networking/cilium)

> If you're curious about my cluster and its services, I use a GitOps approach with ArgoCD and the files with the documentation can be found in the [here](https://github.com/Tiagura/k8s-gitops/tree/main)