#!/bin/bash
# ===============================================================
#  EEEEE    M   M     A     I    L        L        EEEEE    TTTTT
#  E        MM MM    A A    I    L        L        E          T
#  EEEE     M M M   AAAAA   I    L        L        EEEE       T
#  E        M   M   A   A   I    L        L        E          T
#  EEEEE    M   M   A   A   I    LLLLL    LLLLL    EEEEE      T
# ===============================================================

set -euo pipefail
# ===============================================================
# Complete Uninstall: K3D + Tools + Configs
# ===============================================================

# Get current script directory
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
ok() { echo -e "${BG_GREEN}${FG_WHITE} [ OK ] ${RESET} $*"; }
note() { echo -e "${BG_WHITE}${FG_BLACK} $*${RESET}"; }

info "Uninstall in progress..."

# ===============================================================
# K3D - Delete Cluster and Namespaces
# ===============================================================

info "Deleting namespaces..."
sudo kubectl delete namespace argocd --ignore-not-found && ok "Namespace argocd deleted"
sudo kubectl delete namespace dev --ignore-not-found && ok "Namespace dev deleted"
sudo kubectl delete namespace gitlab --ignore-not-found && ok "Namespace gitlab deleted"

info "Removing GitLab Helm release..."
sudo helm uninstall gitlab -n gitlab 2>/dev/null && ok "GitLab release removed" || warn "GitLab release not found"

info "Deleting k3d cluster..."
sudo k3d cluster delete inception-of-things && ok "k3d cluster deleted"

# ===============================================================
# Cleanup Installed Tools
# ===============================================================

info "Removing installed tools..."

# Remove k3d
sudo rm -f /usr/local/bin/k3d && ok "k3d removed"

# Remove Helm
sudo helm repo remove gitlab 2>/dev/null && ok "GitLab Helm repo removed" || warn "GitLab Helm repo not found"
sudo rm -f /usr/local/bin/helm && ok "Helm removed"

# Remove k9s
sudo rm -f ~/.local/bin/k9s && ok "k9s removed"

# Cleanup docker.io k3d images
sudo docker rmi -f $(sudo docker images --filter=reference='rancher/k3s*' -q) 2>/dev/null && ok "k3s images removed"

# ===============================================================
# Delete Configuration Files
# ===============================================================

info "Deleting configuration files..."
rm -rf ~/.config/k3d && ok "k3d configuration deleted"
rm -rf ~/.kube/config ~/.kube/k3d-* ~/.kube/clusters/k3d* 2>/dev/null && ok "Kubeconfig deleted"

ok "Complete uninstall finished!"
