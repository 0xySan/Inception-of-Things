#!/bin/bash
# ===============================================================
#  EEEEE    M   M     A     I    L        L        EEEEE    TTTTT
#  E        MM MM    A A    I    L        L        E          T
#  EEEE     M M M   AAAAA   I    L        L        EEEE       T
#  E        M   M   A   A   I    L        L        E          T
#  EEEEE    M   M   A   A   I    LLLLL    LLLLL    EEEEE      T
# ===============================================================

# Minimal package list for k3d, Helm, ArgoCD, and GitOps via GitHub
APT_PACKAGES=(
  curl            # Download binaries/scripts (k3d, Helm, ArgoCD, kubectl)
  ca-certificates # Required so curl can validate HTTPS connections (GitHub, releases, etc.)
  docker.io       # Container engine required to run the k3d cluster
  git             # Required to clone, commit, and push to GitHub
  kubectl         # CLI tool to interact with k3s
)

PACMAN_PACKAGES=(
  curl            # Download binaries/scripts (k3d, Helm, ArgoCD, kubectl)
  ca-certificates # Required so curl can validate HTTPS connections (GitHub, releases, etc.)
  docker          # Container engine required to run the k3d cluster
  git             # Required to clone, commit, and push to GitHub
  kubectl         # CLI tool to interact with k3s
)

if command -v apt >/dev/null 2>&1; then
  # Update and install the minimal list with apt
  sudo apt update
  sudo apt install -y "${APT_PACKAGES[@]}"
elif command -v pacman >/dev/null 2>&1; then
  # Update and install the minimal list with pacman
  sudo pacman -Sy --noconfirm --needed "${PACMAN_PACKAGES[@]}"
else
  echo "No supported package manager found (apt or pacman)."
  exit 1
fi

if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable --now docker
fi

sudo usermod -aG docker $USER
