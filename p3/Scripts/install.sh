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


#Demande le passage a sudo au prealable pour eviter les demandes de mot de passe en plein milieu de l'installation
sudo echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m Installation en cours, veuillez patienter... \033[0m"

# bash "$SCRIPT_DIR/dependency-check.sh"

# ===============================================================
# K3D
# ===============================================================

echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m [*] Nettoyage des ressources existantes... \033[0m"
sudo k3d cluster delete inception-of-things 2>/dev/null && echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Ancien cluster supprimé \033[0m"

#Installation de k3d
bash "$SCRIPT_DIR/k3d_install.sh" && echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ k3d installé ! \033[0m"

#On cree un cluster k3d
sudo k3d cluster create inception-of-things --agents 2 --port "80:80@loadbalancer" --port "443:443@loadbalancer" --port "8080:8080@loadbalancer" && echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Cluster k3d créé ! \033[0m"

# Configuration du kubeconfig pour le cluster k3d
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m [*] Configuration du kubeconfig... \033[0m"
mkdir -p ~/.kube
sudo k3d kubeconfig get inception-of-things > ~/.kube/config
chmod 600 ~/.kube/config
sleep 1

# Vérifier que kubectl fonctionne
counter=1
until sudo kubectl cluster-info &>/dev/null; do
    if [ $counter -gt 10 ]; then
        echo -e "\033[48;2;200;100;0m\033[38;2;255;255;255m ! Kubectl indisponible \033[0m"
        break
    fi
    echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m  [Essaie $counter] En attente de kubectl... \033[0m"
    ((counter++))
    sleep 1
done
echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Kubeconfig configuré ! \033[0m"

#On cree le premier namespace pour ArgoCD
sudo kubectl create namespace argocd 2>/dev/null && echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Namespace argocd créé ! \033[0m"

#On cree le second namespace 'dev'
sudo kubectl create namespace dev 2>/dev/null && echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Namespace dev créé ! \033[0m"

export counter=1

until [ $(sudo k3d node list | wc -l) -ge 3 ]; do
    echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m [Essaie $counter] En attente de tous les nœuds... \033[0m"
    ((counter++))
    sleep 2
done

echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Tous les nœuds sont prêts ! \033[0m"

# Attendre que kubectl soit complètement fonctionnel
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m [*] Attente de la disponibilité de l'API Kubernetes... \033[0m"
counter=1
until sudo kubectl cluster-info &>/dev/null; do
    echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m  [Essaie $counter] En attente de l'API... \033[0m"
    ((counter++))
    sleep 2
done
echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ API Kubernetes opérationnelle ! \033[0m"

# ===============================================================
# HELM & argocd
# ===============================================================

#Instalation de helm pour k3d
bash "$SCRIPT_DIR/helm_install.sh" && echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Helm installé ! \033[0m"

#Installation d'ArgoCD via helm
bash "$SCRIPT_DIR/argocd_install.sh" && echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ ArgoCD installé ! \033[0m"

# Attendre qu'ArgoCD soit complètement prêt
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m [*] En attente du déploiement d'ArgoCD... \033[0m"
counter=1
until sudo kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server --no-headers | grep -q Running; do
    if [ $counter -gt 120 ]; then
        echo -e "\033[48;2;200;100;0m\033[38;2;255;255;255m ! Timeout en attendant les pods ArgoCD \033[0m"
        echo -e "\033[48;2;200;100;0m\033[38;2;255;255;255m Pods actuels : \033[0m"
        sudo kubectl get pods -n argocd
        break
    fi
    # Afficher un point au lieu d'un message long
    if [ $((counter % 5)) -eq 0 ]; then
        echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m  [$counter/120] Attente... \033[0m"
    fi
    ((counter++))
    sleep 1
done

echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m [*] Attente du repo-server ArgoCD... \033[0m"
counter=1
until sudo kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-repo-server --no-headers | grep -q Running; do
    if [ $counter -gt 120 ]; then
        echo -e "\033[48;2;200;100;0m\033[38;2;255;255;255m ! Timeout en attendant repo-server ArgoCD \033[0m"
        echo -e "\033[48;2;200;100;0m\033[38;2;255;255;255m Pods actuels : \033[0m"
        sudo kubectl get pods -n argocd
        break
    fi
    if [ $((counter % 5)) -eq 0 ]; then
        echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m  [$counter/120] Attente... \033[0m"
    fi
    ((counter++))
    sleep 1
done

if [ $counter -le 120 ]; then
    echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Tous les pods ArgoCD sont prêts ! \033[0m"

    # Wait for deployment-level readiness to avoid transient repo-server dial errors.
    echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m [*] Vérification du rollout ArgoCD... \033[0m"
    sudo kubectl rollout status deployment/argocd-repo-server -n argocd --timeout=180s
    sudo kubectl rollout status deployment/argocd-server -n argocd --timeout=180s
    
    # Créer l'Ingress pour ArgoCD
    echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m [*] Configuration d'ArgoCD via Ingress... \033[0m"
    sudo kubectl apply -f "$SCRIPT_DIR/../conf/ingress.yaml"

    # Déclarer l'application GitOps à synchroniser depuis la branche app
    echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m [*] Création de l'Application ArgoCD... \033[0m"
    sudo kubectl apply -f "$SCRIPT_DIR/../conf/argocd-application.yaml"
    
    sleep 2
    echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Ingress et Application créés \033[0m"
else
    echo -e "\033[48;2;200;100;0m\033[38;2;255;255;255m ⚠ ArgoCD ne s'est pas lancé correctement - vérifiez avec: sudo kubectl get pods -n argocd \033[0m"
fi


# ===============================================================
# Utilitaires / TUI
# ===============================================================

bash "$SCRIPT_DIR/k9s_install.sh" && echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ k9s installé ! \033[0m"

echo ""
echo -e "\033[48;2;0;128;0m\033[38;2;255;255;255m ✓ Installation terminée avec succès ! \033[0m"
echo ""
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ╔════════════════════════════════════════════════════════╗ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ║  SERVICES ET INFORMATIONS D'ACCÈS                      ║ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ╠════════════════════════════════════════════════════════╣ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ║  ArgoCD                                                ║ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ║    URL:      http://localhost                          ║ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ║    Utilisateur: admin                                  ║ \033[0m"

ARGOCD_PASSWORD=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "N/A")
printf '\033[48;2;0;100;200m\033[38;2;255;255;255m ║    Mot de passe: %-36s  ║ \033[0m\n' "${ARGOCD_PASSWORD}"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ╠════════════════════════════════════════════════════════╣ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ║  Application de démonstration                          ║ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ║    URL:      http://app.localhost                      ║ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ╠════════════════════════════════════════════════════════╣ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ║  Kubernetes Cluster                                    ║ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ║    Cluster:  inception-of-things                       ║ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ║    Nodes:    1 server + 2 agents                       ║ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ╠════════════════════════════════════════════════════════╣ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ║  Commandes utiles                                      ║ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ║    • Vérifier l'état:    sudo kubectl get pods         ║ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ║    • TUI k9s:            sudo k9s                      ║ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ║    • Vérif' Ingress:     sudo kubectl get ing -n argocd║ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ║    • Désinstaller:        bash Scripts/uninstall.sh    ║ \033[0m"
echo -e "\033[48;2;0;100;200m\033[38;2;255;255;255m ╚════════════════════════════════════════════════════════╝ \033[0m"
echo ""
