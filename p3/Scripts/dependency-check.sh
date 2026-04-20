#!/bin/bash
# ===============================================================
#  EEEEE    M   M     A     I    L        L        EEEEE    TTTTT
#  E        MM MM    A A    I    L        L        E          T
#  EEEE     M M M   AAAAA   I    L        L        EEEE       T
#  E        M   M   A   A   I    L        L        E          T
#  EEEEE    M   M   A   A   I    LLLLL    LLLLL    EEEEE      T
# ===============================================================

# Liste minimale des paquets pour k3d, Helm, ArgoCD et GitOps via GitHub
APT_PACKAGES=(
  curl            # Pour télécharger les binaires/scripts (k3d, Helm, ArgoCD, kubectl)
  ca-certificates # Requis pour que curl valide les connexions HTTPS (GitHub, releases, etc.)
  docker.io       # Moteur de conteneurs indispensable pour faire tourner le cluster k3d
  git             # Requis sur votre machine pour cloner, commit et push vers GitHub
  kubectl         # Outil d'interaction avec k3s
)

PACMAN_PACKAGES=(
  curl            # Pour télécharger les binaires/scripts (k3d, Helm, ArgoCD, kubectl)
  ca-certificates # Requis pour que curl valide les connexions HTTPS (GitHub, releases, etc.)
  docker          # Moteur de conteneurs indispensable pour faire tourner le cluster k3d
  git             # Requis sur votre machine pour cloner, commit et push vers GitHub
  kubectl         # Outil d'interaction avec k3s
)

if command -v apt >/dev/null 2>&1; then
  # Mise à jour et installation de la liste minimale avec apt
  sudo apt update
  sudo apt install -y "${APT_PACKAGES[@]}"
elif command -v pacman >/dev/null 2>&1; then
  # Mise à jour et installation de la liste minimale avec pacman
  sudo pacman -Sy --noconfirm --needed "${PACMAN_PACKAGES[@]}"
else
  echo "Aucun gestionnaire de paquets pris en charge trouvé (apt ou pacman)."
  exit 1
fi

if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable --now docker
fi

sudo usermod -aG docker $USER
