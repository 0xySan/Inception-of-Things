# Inception of Things (IoT) — 42 System Administration Project (v2.1)

This repository contains my work for **Inception of Things (IoT)**, a **42 specialization** project focused on **system administration** and a minimal introduction to **Kubernetes** using **K3s**, **K3d**, **Vagrant**, and **Argo CD**.

The project is split into **three mandatory parts** (to be done in order) and an optional **bonus**.

---

## Repository Structure (Required)

At the root of the repository:

- `p1/` — Part 1: K3s and Vagrant (2 VMs)
- `p2/` — Part 2: K3s and three simple applications (1 VM)
- `p3/` — Part 3: K3d and Argo CD (no Vagrant)
- `bonus/` — Bonus: Local GitLab integrated with Part 3 (optional)

Each part follows the subject convention:

- `scripts/` → install / setup scripts (used during defense)
- `confs/` → Kubernetes / Ingress / ArgoCD configuration files

---

## Part 1 — K3s and Vagrant (2 Machines)

Goal: create two virtual machines using **Vagrant** and install **K3s**:

- VM1: **Server (controller)**  
  - hostname: `<login>S`  
  - IP (eth1): `192.168.56.110`
- VM2: **ServerWorker (agent)**  
  - hostname: `<login>SW`  
  - IP (eth1): `192.168.56.111`

Requirements:
- Minimal resources recommended (1 CPU, 512MB–1024MB RAM)
- SSH access to both machines **without password**
- `kubectl` must be installed and used

---

## Part 2 — K3s and 3 Applications (1 Machine)

Goal: run **one VM** with **K3s in server mode** and deploy **three web apps**.

Ingress requirement:
- Access apps based on the **HOST header** when requesting `192.168.56.110`
  - `app1.com` → app1
  - `app2.com` → app2 (**3 replicas required**)
  - any other host → app3 (default)

During defense, the Ingress must be shown to evaluators.

---

## Part 3 — K3d and Argo CD (GitOps)

Goal: set up a lightweight Kubernetes cluster using **K3d** (K3s in Docker), then configure **Argo CD** to automatically deploy an application from this public Git repository.

Requirements:
- K3d installed on the VM (**Docker is mandatory**)
- A script must install **all required tools/packages** during evaluation
- Two namespaces:
  - `argocd` → Argo CD components
  - `dev` → the application deployed by Argo CD
- The deployed application must have **two versions** (`v1` and `v2`) using Docker tags:
  - Option A: `wil42/playground` (port **8888**) with tags `v1` and `v2`
  - Option B: your own public Docker image with tags `v1` and `v2`
- During evaluation, updating the image tag in Git (v1 → v2) must trigger Argo CD sync and update the running app.

Repository naming rule (42):
- The repository name must include the login of a group member.

---

## Bonus — Local GitLab (Optional)

Goal: add a **local GitLab** instance to the Part 3 lab.

Requirements:
- GitLab runs locally in the cluster
- Dedicated namespace: `gitlab`
- GitLab is configured to work with the cluster
- Everything from Part 3 still works using the local GitLab
- Bonus is evaluated **only if the mandatory part is perfect**
- Helm is allowed (and typically useful) to deploy GitLab

---

## Notes

This project is a **minimal introduction** to Kubernetes: it does not aim to cover all Kubernetes concepts, but focuses on building a working lab with clear constraints and reproducible steps for a defense environment.
