#!/bin/bash
# ===============================================================
#  EEEEE    M   M     A     I    L        L        EEEEE    TTTTT
#  E        MM MM    A A    I    L        L        E          T
#  EEEE     M M M   AAAAA   I    L        L        EEEE       T
#  E        M   M   A   A   I    L        L        E          T
#  EEEEE    M   M   A   A   I    LLLLL    LLLLL    EEEEE      T
# ===============================================================

# ===============================================================
# ArgoCD Installation via Helm
# ===============================================================

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
CONF_DIR="$SCRIPT_DIR/../conf"

BG_BLUE="\033[48;2;0;100;200m"
BG_RED="\033[48;2;200;0;0m"
BG_YELLOW="\033[48;2;200;160;0m"
BG_GREEN="\033[48;2;0;128;0m"
BG_WHITE="\033[48;2;255;255;255m"
FG_WHITE="\033[38;2;255;255;255m"
FG_BLACK="\033[38;2;0;0;0m"
RESET="\033[0m"

info() { echo -e "${BG_BLUE}${FG_WHITE} [INFO] ${RESET} $*"; }
error() { echo -e "${BG_RED}${FG_WHITE} [FAIL] ${RESET} $*"; }
ok() { echo -e "${BG_GREEN}${FG_WHITE} [ OK ] ${RESET} $*"; }

# ===============================================================
# Helm Configuration
# ===============================================================

info "Adding ArgoCD Helm repo..."
sudo helm repo add argo https://argoproj.github.io/argo-helm || true

info "Updating Helm repositories..."
sudo helm repo update

# ===============================================================
# Configuration Files Check
# ===============================================================

if [ ! -f "$CONF_DIR/argocd-value.yaml" ]; then
  error "ArgoCD configuration file not found"
    exit 1
fi

# ===============================================================
# ArgoCD Installation
# ===============================================================

info "Installing ArgoCD..."
sudo helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace \
  --wait --timeout 10m \
  -f "$CONF_DIR/argocd-value.yaml"

# ===============================================================
# Secure ArgoCD Application Deployment
# ===============================================================

info "Creating ArgoCD Application..."
sudo kubectl apply -f "$CONF_DIR/argocd-application.yaml"

# ===============================================================
# Automatic Refresh Agent
# ===============================================================

info "Deploying refresh agent (every minute)..."
sudo kubectl apply -f "$CONF_DIR/cronjob-refresh.yaml"

# ===============================================================
# Final Check
# ===============================================================

ok "ArgoCD deployment is in progress..."
sudo helm list -n argocd