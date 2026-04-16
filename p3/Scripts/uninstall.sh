#!/bin/bash
# ===============================================================
#  EEEEE    M   M     A     I    L        L        EEEEE    TTTTT
#  E        MM MM    A A    I    L        L        E          T
#  EEEE     M M M   AAAAA   I    L        L        EEEE       T
#  E        M   M   A   A   I    L        L        E          T
#  EEEEE    M   M   A   A   I    LLLLL    LLLLL    EEEEE      T
# ===============================================================

#On récupère le chemin absolu du dossier dans lequel se trouve CE script
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m Désinstallation en cours... \033[0m"

# ===============================================================
# K3D - Suppression du cluster et namespaces
# ===============================================================

echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m [1/4] Suppression des namespaces... \033[0m"
sudo kubectl delete namespace argocd --ignore-not-found && echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Namespace argocd supprimé \033[0m"
sudo kubectl delete namespace dev --ignore-not-found && echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Namespace dev supprimé \033[0m"

echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m [2/4] Suppression du cluster k3d... \033[0m"
sudo k3d cluster delete inception-of-things && echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Cluster k3d supprimé \033[0m"

# ===============================================================
# Nettoyage des outils installés
# ===============================================================

echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m [3/4] Suppression des outils... \033[0m"

# Suppression de k3d
sudo rm -f /usr/local/bin/k3d && echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ k3d supprimé \033[0m"

# Suppression de Helm
sudo rm -f /usr/local/bin/helm && echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Helm supprimé \033[0m"

# Suppression de k9s
sudo rm -f ~/.local/bin/k9s && echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ k9s supprimé \033[0m"

# Netoyage docker.io des images k3d
sudo docker rmi -f $(sudo docker images --filter=reference='rancher/k3s*' -q) 2>/dev/null && echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Images k3s de docker.io supprimées \033[0m"

# ===============================================================
# Suppression des fichiers de configuration
# ===============================================================

echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m [4/4] Suppression des fichiers de configuration... \033[0m"
rm -rf ~/.config/k3d && echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Configuration k3d supprimée \033[0m"
rm -rf ~/.kube/config ~/.kube/k3d-* ~/.kube/clusters/k3d* 2>/dev/null && echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Kubeconfig supprimé \033[0m"

echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Désinstallation complète ! \033[0m" 
