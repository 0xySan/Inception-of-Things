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

print_title() {
  printf '\n%b╭────────────────────────────────────────────────────────────╮%b\n' "$CYAN" "$RESET"
  printf '%b│%b  %bINCEPTION OF THINGS%b  %b· Part 3%b                         %b│%b\n' \
    "$CYAN" "$RESET" "$BOLD$WHITE" "$RESET" "$GRAY" "$RESET" "$CYAN" "$RESET"
  printf '%b╰────────────────────────────────────────────────────────────╯%b\n' "$CYAN" "$RESET"
}

section() {
  printf '\n%b%s%b\n' "$BLUE$BOLD" "$1" "$RESET"
  printf '%b────────────────────────────────────────────────────────────%b\n' "$GRAY" "$RESET"
}

row() {
  printf '  %b%-18s%b %s\n' "$CYAN" "$1" "$RESET" "$2"
}

print_title

section 'SERVICES'
row 'Argo CD' 'http://argocd.localhost'
row 'Application' 'http://localhost:8888'
row 'Cluster' 'inception-of-things · 1 server + 2 agents'

section 'ACCESS'
row 'Argo CD user' 'admin'
row 'Argo CD password' "$ARGOCD_PASSWORD"

section 'QUICK CHECKS'
printf '  %b$%b kubectl get pods -A\n' "$GREEN" "$RESET"
printf '  %b$%b kubectl get application -n argocd\n' "$GREEN" "$RESET"
printf '  %b$%b curl http://localhost:8888\n' "$GREEN" "$RESET"
printf '  %b$%b kubectl get cronjob,jobs,pods -n argocd\n' "$GREEN" "$RESET"

section 'TOOLS'
printf '  %b%s%b  k9s\n' "$YELLOW" 'TUI' "$RESET"
printf '  %b%s%b  make clean\n' "$YELLOW" 'STOP' "$RESET"
printf '  %b%s%b  make re\n' "$YELLOW" 'RESET' "$RESET"

printf '\n%bTip:%b use %bkubectl get application dev-app -n argocd -o wide%b to inspect sync status.\n\n' \
  "$GRAY" "$RESET" "$WHITE" "$RESET"
