#!/bin/bash
# ===============================================================
#  EEEEE    M   M     A     I    L        L        EEEEE    TTTTT
#  E        MM MM    A A    I    L        L        E          T
#  EEEE     M M M   AAAAA   I    L        L        EEEE       T
#  E        M   M   A   A   I    L        L        E          T
#  EEEEE    M   M   A   A   I    LLLLL    LLLLL    EEEEE      T
# ===============================================================

# ===============================================================
# Complete Installation: K3D + ArgoCD + GitOps
# ===============================================================

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

BG_BLUE="\033[48;2;0;100;200m"
BG_RED="\033[48;2;200;0;0m"
BG_YELLOW="\033[48;2;200;160;0m"
BG_GREEN="\033[48;2;0;128;0m"
BG_WHITE="\033[48;2;255;255;255m"
FG_WHITE="\033[38;2;255;255;255m"
FG_BLACK="\033[38;2;0;0;0m"
RESET="\033[0m"

info() { echo -e "${BG_BLUE}${FG_WHITE} [INFO] ${RESET} $*"; }
warn() { echo -e "${BG_YELLOW}${FG_BLACK} [WARN] ${RESET} $*"; }
error() { echo -e "${BG_RED}${FG_WHITE} [ERROR] ${RESET} $*"; }
ok() { echo -e "${BG_GREEN}${FG_WHITE} [OK] ${RESET} $*"; }
note() { echo -e "${BG_WHITE}${FG_BLACK} $*${RESET}"; }

# Request sudo privileges upfront
sudo echo ""

# ===============================================================
# K3D Cluster - Creation
# ===============================================================

info "Cleaning existing resources..."
sudo k3d cluster delete inception-of-things 2>/dev/null && ok "Previous cluster deleted"

info "Installing k3d..."
bash "$SCRIPT_DIR/k3d_install.sh" > /dev/null 2>&1 && echo "  ✓ k3d ready"

info "Creating K3D cluster..."
sudo k3d cluster create inception-of-things --agents 2 \
  --port "80:80@loadbalancer" \
  --port "443:443@loadbalancer" \
  --port "8080:8080@loadbalancer" \
    --port "8888:8888@loadbalancer" > /dev/null 2>&1 && echo "  ✓ Cluster created"

# ===============================================================
# Kubeconfig - Configuration
# ===============================================================

info "Configuring kubeconfig..."
mkdir -p ~/.kube
sudo k3d kubeconfig get inception-of-things > ~/.kube/config
chmod 600 ~/.kube/config

# Wait for kubectl
counter=0
until sudo kubectl cluster-info &>/dev/null || [ $counter -gt 10 ]; do
    ((counter++))
    sleep 1
done
ok "Kubeconfig configured"

# ===============================================================
# Namespaces - Creation
# ===============================================================

info "Creating namespaces..."
sudo kubectl create namespace argocd 2>/dev/null || true
sudo kubectl create namespace dev 2>/dev/null || true
ok "Namespaces ready"

# ===============================================================
# K3D Nodes - Wait
# ===============================================================

info "Waiting for all nodes..."
counter=0
until [ $(sudo k3d node list | wc -l) -ge 3 ] || [ $counter -gt 30 ]; do
    ((counter++))
    sleep 2
done
ok "All nodes are ready"

# ===============================================================
# Helm - Installation and Configuration
# ===============================================================

info "Installing Helm..."
bash "$SCRIPT_DIR/helm_install.sh" > /dev/null 2>&1 && echo "  ✓ Helm installed"

info "Installing ArgoCD..."
bash "$SCRIPT_DIR/argocd_install.sh" && echo "  ✓ ArgoCD deployed"

# ===============================================================
# ArgoCD - Wait
# ===============================================================

info "Checking ArgoCD deployment..."

# ArgoCD Server
counter=0
until sudo kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server --no-headers 2>/dev/null | grep -q Running || [ $counter -gt 120 ]; do
    ((counter++))
    [ $((counter % 10)) -eq 0 ] && warn "Attempt $counter/120..."
    sleep 1
done

# ArgoCD Repo Server
counter=0
until sudo kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-repo-server --no-headers 2>/dev/null | grep -q Running || [ $counter -gt 120 ]; do
    ((counter++))
    [ $((counter % 10)) -eq 0 ] && warn "Attempt $counter/120..."
    sleep 1
done

ok "ArgoCD online"

# ===============================================================
# Utilities - Installation
# ===============================================================

info "Installing k9s (TUI)..."
bash "$SCRIPT_DIR/k9s_install.sh" > /dev/null 2>&1 && echo "  ✓ k9s installed"

# ===============================================================
# Final Summary
# ===============================================================

bash "$SCRIPT_DIR/info.sh"