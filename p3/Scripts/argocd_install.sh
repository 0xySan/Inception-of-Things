#!/bin/bash
# ===============================================================
#  EEEEE    M   M     A     I    L        L        EEEEE    TTTTT
#  E        MM MM    A A    I    L        L        E          T
#  EEEE     M M M   AAAAA   I    L        L        EEEE       T
#  E        M   M   A   A   I    L        L        E          T
#  EEEEE    M   M   A   A   I    LLLLL    LLLLL    EEEEE      T
# ===============================================================

# Telechargement et installation d'ArgoCD via helm

# Ajouter le repo Helm d'ArgoCD
echo "Ajout du repo Helm ArgoCD..."
sudo helm repo add argo https://argoproj.github.io/argo-helm || echo "Repo bereits existant"

# Mettre à jour les repos
echo "Mise à jour des repos Helm..."
sudo helm repo update

# Installer ArgoCD
echo "Installation d'ArgoCD..."
sudo helm install argocd argo/argo-cd -n argocd --create-namespace

# Vérifier l'installation
echo "Vérification de l'installation..."
sudo helm list -n argocd