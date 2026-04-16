#!/bin/bash
# ===============================================================
#  EEEEE    M   M     A     I    L        L        EEEEE    TTTTT
#  E        MM MM    A A    I    L        L        E          T
#  EEEE     M M M   AAAAA   I    L        L        EEEE       T
#  E        M   M   A   A   I    L        L        E          T
#  EEEEE    M   M   A   A   I    LLLLL    LLLLL    EEEEE      T
# ===============================================================

# Telechargement et installation d'ArgoCD via helm

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
CONF_DIR="$SCRIPT_DIR/../conf"

# Ajouter le repo Helm d'ArgoCD
echo "Ajout du repo Helm ArgoCD..."
sudo helm repo add argo https://argoproj.github.io/argo-helm || echo "Repo bereits existant"

# Mettre à jour les repos
echo "Mise à jour des repos Helm..."
sudo helm repo update

# Vérifier que le fichier de configuration existe
if [ ! -f "$CONF_DIR/argocd-value.yaml" ]; then
    echo "Erreur: fichier de configuration ArgoCD non trouvé à $CONF_DIR/argocd-value.yaml"
    exit 1
fi

# Installer ArgoCD avec le fichier de configuration
echo "Installation d'ArgoCD avec configuration personnalisée..."
sudo helm install argocd argo/argo-cd -n argocd --create-namespace \
  -f "$CONF_DIR/argocd-value.yaml"

# Vérifier l'installation
echo "Vérification de l'installation..."
sudo helm list -n argocd