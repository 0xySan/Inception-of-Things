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
# Gitlab gitops setup
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
ok() { echo -e "${BG_GREEN}${FG_WHITE} [ OK ] ${RESET} $*"; }
error() { echo -e "${BG_RED}${FG_WHITE} [FAIL] ${RESET} $*"; }

# ===============================================================
# Wait for Gitlab to be ready and retrieve root password
# ===============================================================

info "Waiting for Gitlab webservice to be ready..."

until [ "$(curl -fsS http://gitlab.localhost/users/sign_in >/dev/null 2>&1; echo $?)" = "0" ]; do	
  echo -n "." && sleep 5
done
echo ""
ok "Gitlab is ready"

TEMP_GITOPS_DIR="${SCRIPT_DIR}/gitops"
GITOPS_BASE_REPO="https://github.com/0xysan/Inception-of-Things.git"
GITOPS_BASE_BRANCH="app"
GITLAB_HOST="gitlab.localhost"
GITLAB_NAMESPACE="root"
CURRENT_BRANCH="$GITOPS_BASE_BRANCH"
GITLAB_ROOT_PASSWORD=$(sudo kubectl -n gitlab get secret gitlab-gitlab-initial-root-password \
  -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null)


# ==============================================================
# Gitops repo  migration
# ==============================================================

info "Migrating GitOps repository to GitLab..."
if [ -d "$TEMP_GITOPS_DIR" ]; then
  warn "Existing '$TEMP_GITOPS_DIR' directory found, removing..."
  rm -rf "$TEMP_GITOPS_DIR"
fi
git clone --branch "$GITOPS_BASE_BRANCH" "$GITOPS_BASE_REPO" "$TEMP_GITOPS_DIR" || { error "Failed to clone base repo"; exit 1; }
cd "$TEMP_GITOPS_DIR" || { error "Failed to enter gitops directory"; exit 1; }

if [ -z "$GITLAB_ROOT_PASSWORD" ]; then
  error "Failed to retrieve GitLab root password"
  exit 1
fi

git push "http://root:${GITLAB_ROOT_PASSWORD}@${GITLAB_HOST}/${GITLAB_NAMESPACE}/gitops_argocd.git" "$CURRENT_BRANCH" || { error "Failed to push to GitLab"; exit 1; }

ok "GitOps repository migrated successfully"

info "Waiting for internal GitLab webservice to be ready..."
sudo kubectl -n gitlab rollout status deployment/gitlab-webservice-default --timeout=20m || {
  error "GitLab internal webservice is not ready"
  exit 1
}
# ===============================================================
# Register GitLab repository credentials for ArgoCD
# ===============================================================

# ArgoCD needs explicit repo credentials to read the private GitLab repository.
## https://argo-cd.readthedocs.io/en/stable/operator-manual/argocd-repo-creds-yaml/
info "Registering private GitLab repository credentials for ArgoCD..."
sudo kubectl -n argocd apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/gitops_argocd.git
  username: root
  password: ${GITLAB_ROOT_PASSWORD}
EOF

# ===============================================================
# Deploy application via GitOps with ArgoCD
# ===============================================================

info "Deploying application via GitOps with ArgoCD..."
sudo kubectl apply -f "${SCRIPT_DIR}/../conf/argocd-application.yaml" -n argocd || { error "Failed to apply ArgoCD application manifest"; exit 1; }

info "Forcing ArgoCD to refresh the application..."
sudo kubectl annotate application dev-app -n argocd argocd.argoproj.io/refresh=hard --overwrite || {
  error "Failed to refresh ArgoCD application"
  exit 1
}

rm -rf "$TEMP_GITOPS_DIR"