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
# Lightweight Gitlab Installation via Helm
# ===============================================================


SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
CONF_DIR="$SCRIPT_DIR/../confs"

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
# Install Gitlab 10.0+ external tools
# ===============================================================

# 1. Namespace
sudo kubectl create namespace gitlab --dry-run=client -o yaml | sudo kubectl apply -f -

sudo helm repo add bitnami https://charts.bitnami.com/bitnami || true
sudo helm repo update

generate_password() {
  openssl rand -hex 16
}

get_or_generate_password() {
  local secret_name=$1
  local secret_key=$2
  local password

  password=$(sudo kubectl get secret "$secret_name" \
    --namespace gitlab \
    -o "jsonpath={.data.$secret_key}" 2>/dev/null | base64 --decode || true)

  if [ -n "$password" ]; then
    printf '%s' "$password"
  else
    generate_password
  fi
}

PGPASSWORD=$(get_or_generate_password gitlab-postgresql-password postgresql-password)
# Bitnami moved its free images to 'bitnamilegacy' (Aug 2025): override the repository
sudo helm upgrade --install gitlab-postgresql bitnami/postgresql \
  --namespace gitlab \
  --set image.repository=bitnamilegacy/postgresql \
  --set image.tag=17 \
  --set metrics.enabled=false \
  --set-string auth.postgresPassword="$PGPASSWORD" \
  --set auth.database=gitlabhq_production \
  --set primary.resources.requests.memory=256Mi \
  --set primary.resources.requests.cpu=100m


REDISPASSWORD=$(get_or_generate_password gitlab-redis-password redis-password)
sudo helm upgrade --install gitlab-redis bitnami/redis \
  --namespace gitlab \
  --set-string auth.password="$REDISPASSWORD" \
  --set architecture=standalone \
  --set master.resources.requests.memory=128Mi \
  --set master.resources.requests.cpu=50m

# PostgreSQL secret
sudo kubectl create secret generic gitlab-postgresql-password \
  --namespace gitlab \
  --from-literal=postgresql-password="$PGPASSWORD" \
  --dry-run=client -o yaml | sudo kubectl apply -f -

# Redis secret
sudo kubectl create secret generic gitlab-redis-password \
  --namespace gitlab \
  --from-literal=redis-password="$REDISPASSWORD" \
  --dry-run=client -o yaml | sudo kubectl apply -f -

# ===============================================================
# Helm Configuration for gitlab
# ===============================================================

info "Adding GitLab Helm repo..."
sudo helm repo add gitlab https://charts.gitlab.io/ || true

info "Updating Helm repositories..."
sudo helm repo update

# ===============================================================
# Configuration Files Check
# ===============================================================

if [ ! -f "$CONF_DIR/gitlab-value.yaml" ]; then
  error "Gitlab configuration file not found"
	exit 1
fi

# ===============================================================
# Gitlab Installation
# ===============================================================

sudo helm upgrade --install gitlab gitlab/gitlab \
  -n gitlab \
  --wait --timeout 10m \
  --skip-crds \
  -f "$CONF_DIR/gitlab-value.yaml"

# ===============================================================
# Final Check
# ===============================================================

ok "GitLab deployment completed successfully"
sudo helm list -n gitlab