#!/bin/bash

set -u

RESET='\033[0m'
BOLD='\033[1m'
CYAN='\033[36m'
BLUE='\033[34m'
GREEN='\033[32m'
YELLOW='\033[33m'
WHITE='\033[97m'
GRAY='\033[90m'

ARGOCD_PASSWORD=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || printf '%s' 'unavailable')
GITLAB_PASSWORD=$(sudo kubectl -n gitlab get secret gitlab-gitlab-initial-root-password \
  -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || printf '%s' 'unavailable')

section() {
  printf '\n%b%s%b\n' "$BLUE$BOLD" "$1" "$RESET"
  printf '%b────────────────────────────────────────────────────────────%b\n' "$GRAY" "$RESET"
}

row() {
  printf '  %b%-18s%b %s\n' "$CYAN" "$1" "$RESET" "$2"
}

printf '\n%b╭────────────────────────────────────────────────────────────╮%b\n' "$CYAN" "$RESET"
printf '%b│%b  %bINCEPTION OF THINGS%b  %b· Bonus GitLab%b                  %b│%b\n' \
  "$CYAN" "$RESET" "$BOLD$WHITE" "$RESET" "$GRAY" "$RESET" "$CYAN" "$RESET"
printf '%b╰────────────────────────────────────────────────────────────╯%b\n' "$CYAN" "$RESET"

section 'SERVICES'
row 'Argo CD' 'http://argocd.localhost'
row 'GitLab' 'http://gitlab.localhost'
row 'Application' 'http://localhost:8888'
row 'Cluster' 'inception-of-things · 1 server + 2 agents'

section 'ACCESS'
row 'Argo CD user' 'admin'
row 'Argo CD password' "$ARGOCD_PASSWORD"
row 'GitLab user' 'root'
row 'GitLab password' "$GITLAB_PASSWORD"

section 'GITOPS'
row 'Repository' 'gitlab.localhost/root/gitops_argocd.git'
row 'Namespace' 'dev'
printf '  %b$%b kubectl get application dev-app -n argocd -o wide\n' "$GREEN" "$RESET"
printf '  %b$%b curl http://localhost:8888\n' "$GREEN" "$RESET"

section 'TOOLS'
printf '  %b%s%b  kubectl get pods -A\n' "$YELLOW" 'CHECK' "$RESET"
printf '  %b%s%b  kubectl get cronjob,jobs,pods -n argocd\n' "$YELLOW" 'SYNC' "$RESET"
printf '  %b%s%b  k9s\n' "$YELLOW" 'TUI' "$RESET"
printf '  %b%s%b  make clean\n' "$YELLOW" 'STOP' "$RESET"

printf '\n%bTip:%b the GitLab host is generated from domain %blocalhost%b.\n\n' \
  "$GRAY" "$RESET" "$WHITE" "$RESET"
