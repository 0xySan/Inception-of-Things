#!/bin/bash
# ===============================================================
#  EEEEE    M   M     A     I    L        L        EEEEE    TTTTT
#  E        MM MM    A A    I    L        L        E          T
#  EEEE     M M M   AAAAA   I    L        L        EEEE       T
#  E        M   M   A   A   I    L        L        E          T
#  EEEEE    M   M   A   A   I    LLLLL    LLLLL    EEEEE      T
# ===============================================================

# Liste minimale des paquets pour k3d, Helm, ArgoCD et GitOps via GitHub
PACKAGES=(
  curl            # Pour télécharger les binaires/scripts (k3d, Helm, ArgoCD, kubectl)
  ca-certificates # Requis pour que curl valide les connexions HTTPS (GitHub, releases, etc.)
  docker.io       # Moteur de conteneurs indispensable pour faire tourner le cluster k3d
  git             # Requis sur votre machine pour cloner, commit et push vers GitHub
  kubectl         # Outil d'interaction avec k3s
)

# Mise à jour et installation de la liste minimale
sudo apt update
sudo apt install -y "${PACKAGES[@]}"

sudo usermod -aG docker $USER
