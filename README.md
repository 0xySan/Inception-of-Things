# 🚀 Inception of Things (IoT) — Guide de Soutenance & Cheat-Sheet

Ce dépôt contient mon travail sur le projet **Inception of Things**, un projet de la branche administration système de l'école 42. C'est une introduction complète et pratique à l'orchestration de conteneurs avec **Kubernetes (K8s)**, à l'infrastructure virtuelle avec **Vagrant** et **Docker**, et au déploiement continu via **GitOps (Argo CD, GitLab)**.

Ce document est rédigé comme une **prise de notes structurée** et un **guide de survie pour la soutenance (peer evaluation)**. Il met l'accent sur la compréhension des termes techniques, le rôle de chaque composant et fournit la liste exacte des commandes pour prouver le bon fonctionnement de chaque partie.

---

## 📚 1. Terminologie & Concepts Clés (À comprendre pour la soutenance)

Pendant la soutenance, l'évaluateur cherchera à valider que vous comprenez la théorie derrière vos scripts. Voici les définitions essentielles expliquées simplement :

### 🖥️ Virtualisation vs. Containerisation
*   **Machine Virtuelle (VM) :** Simule un ordinateur physique entier. Elle embarque un OS complet (avec son noyau) au-dessus d'un hyperviseur. C'est lourd (plusieurs Go), lent à démarrer, mais offre une isolation matérielle totale. (Utilisé dans la Partie 1 & 2 via Vagrant).
*   **Conteneur (Docker) :** Partage le noyau du système d'exploitation de la machine hôte. Il n'isole que l'espace utilisateur. C'est extrêmement léger (quelques Mo), démarre instantanément, mais l'isolation est logicielle. (Utilisé dans la Partie 3 & Bonus via K3d).

### 🛠️ Vagrant & Libvirt/KVM
*   **Vagrant :** Outil de gestion d'environnements virtuels (Infrastructure as Code). Il permet de configurer et lancer des machines virtuelles de manière reproductible via un fichier `Vagrantfile`.
*   **KVM (Kernel-based Virtual Machine) / Libvirt :** KVM est la technologie de virtualisation native du noyau Linux. Libvirt est l'API qui permet à Vagrant de communiquer avec KVM pour gérer les VMs.

### ☸️ Kubernetes (K8s) et ses composants
Kubernetes est un orchestrateur permettant d'automatiser le déploiement, la mise à l'échelle et la gestion des conteneurs.
*   **Control Plane (Server / Master Node) :** Le cerveau du cluster. Il gère l'état global du cluster, planifie les pods et écoute l'API. Dans un K8s classique, l'état est stocké dans une base clé-valeur appelée `etcd`.
*   **Worker Node (Agent Node) :** Les machines physiques ou virtuelles qui exécutent réellement vos applications (les Pods).
*   **Pod :** La plus petite unité de déploiement dans K8s. Il contient un ou plusieurs conteneurs (souvent un seul) qui partagent la même adresse IP et le même stockage.
*   **Deployment (Déploiement) :** Une couche d'abstraction qui gère le cycle de vie des Pods. Il permet de définir le nombre de répliques (replicas) souhaitées. Si un Pod plante, le Déploiement le recrée automatiquement.
*   **Service :** Une adresse réseau stable et un mécanisme de load-balancing pour exposer un groupe de Pods. Les Pods ayant des IPs éphémères, le Service permet de toujours les joindre sous le même nom/port.
*   **Namespace (Espace de noms) :** Une partition virtuelle du cluster pour isoler logiquement les ressources (ex: séparer `argocd`, `dev` et `gitlab`).
*   **Ingress & Ingress Controller :**
    *   *Ingress :* L'objet Kubernetes définissant les règles de routage (ex: si HTTP Host = `app1.com`, rediriger vers le Service `app-one`).
    *   *Ingress Controller :* Le reverse-proxy réel qui écoute le trafic et applique les règles d'Ingress (ex: Nginx Ingress Controller ou Traefik).

### 📦 K3s vs. K3d
*   **K3s :** Version allégée de Kubernetes certifiée par la CNCF, conçue par Rancher. Idéale pour les environnements de développement ou l'IoT. Elle est légère car :
    *   Les drivers cloud tiers obsolètes sont supprimés.
    *   La base de données `etcd` lourde est remplacée par défaut par une base de données **SQLite** légère (intégrée).
    *   Elle est empaquetée dans un seul binaire de moins de 100 Mo.
*   **K3d :** Outil permettant d'exécuter un cluster **K3s dans Docker**. Chaque nœud K3s tourne dans son propre conteneur Docker. C'est extrêmement rapide et consomme très peu de ressources par rapport à de vraies VMs.

### 🚀 GitOps & Argo CD
*   **GitOps :** Pratique consistant à utiliser un dépôt Git comme unique source de vérité pour définir l'état désiré d'une infrastructure ou d'une application.
*   **Argo CD :** Outil GitOps pour Kubernetes qui compare en permanence l'état déclaré dans un dépôt Git avec l'état réel du cluster.
    *   *Self-Healing (Auto-guérison) :* Si une modification manuelle est faite dans le cluster (via kubectl), Argo CD la détecte et réapplique la configuration Git.
    *   *Synchronization (Sync) :* Dès qu'un commit modifie les fichiers de configuration sur Git, Argo CD applique automatiquement ces changements sur le cluster.
    *   *Pull Model :* Argo CD s'exécute à l'intérieur du cluster et va chercher (pull) la configuration Git. C'est plus sécurisé que le modèle "Push" où une CI externe doit posséder les accès administrateurs du cluster.

### ⚓ Helm
*   **Helm :** Le gestionnaire de paquets de Kubernetes (comme `apt` sous Debian). Il utilise des **Charts** (paquets contenant des templates YAML) paramétrables via un fichier `values.yaml` unique, simplifiant grandement le déploiement d'outils complexes (comme GitLab ou Argo CD).

---

## 🛠️ 2. Structure du Projet

```
.
├── p1/                 # Partie 1 : K3s multi-nœuds avec Vagrant (2 VMs)
│   ├── Vagrantfile     # Orchestration des VMs
│   └── scripts/        # Scripts d'installation automatisée de K3s (Master/Worker)
├── p2/                 # Partie 2 : K3s mono-nœud & 3 Web Apps (1 VM)
│   ├── Vagrantfile     # Lancement de la VM unique
│   ├── confs/          # Fichiers YAML (Deployments, Services, Ingress Nginx)
│   └── scripts/        # Scripts de déploiement applicatif
├── p3/                 # Partie 3 : K3d et Argo CD (GitOps)
│   ├── confs/          # Manifestes ArgoCD Application et CronJob Refresh
│   └── scripts/        # Scripts de création du cluster, Helm & ArgoCD
└── bonus/              # Bonus : GitLab interne (GitOps local complet)
    ├── confs/          # Configurations GitLab Helm, Ingress dédié
    └── scripts/        # Scripts de déploiement et de migration du dépôt vers GitLab
```

---

## 💡 3. Explications par Partie & Rôle des Fichiers

### 📍 Partie 1 — K3s & Vagrant (Multi-Machines)
Le but est de configurer deux machines virtuelles communicantes :
*   **`artgirarS` (Server / Control Plane) :** IP `192.168.56.110`. Il initialise le cluster K3s.
*   **`artgirarSW` (Agent / Worker) :** IP `192.168.56.111`. Il se connecte au serveur et exécute les charges applicatives.

**Mécanique technique :**
1.  **Le jeton (`K3S_TOKEN`) :** Lors de l'initialisation du serveur, un jeton secret est requis pour autoriser d'autres nœuds à le rejoindre. Nous le fixons dans le `Vagrantfile` (`password`).
2.  **Liaison du Worker :** Le script du Worker installe K3s en mode agent et pointe vers l'API Server du Master :
    ```bash
    curl -sfL https://get.k3s.io | K3S_TOKEN=$K3S_TOKEN sh -s - agent --server "https://192.168.56.110:6443"
    ```
3.  **Alias `k` :** Un script configure l'alias `k` pour raccourcir l'appel à `k3s kubectl`.

---

### 📍 Partie 2 — K3s & 3 Applications (VM unique + Ingress-Nginx)
Le but est de faire tourner une VM unique (`192.168.56.110`) et d'y déployer trois applications web avec des règles d'accès basées sur le header HTTP `Host`.

**Mécanique technique :**
1.  **Désactivation de Traefik :** Le script d'installation utilise `--disable=traefik` pour empêcher l'ingress controller par défaut de K3s de démarrer.
2.  **Installation de Ingress-Nginx :** Nous appliquons les manifestes officiels d'Ingress-Nginx baremetal.
3.  **hostNetwork :** Afin que le contrôleur Nginx puisse écouter directement sur le port 80 physique de la VM hôte, on "patch" le déploiement nginx avec :
    ```json
    {"spec":{"template":{"spec":{"hostNetwork":true,"dnsPolicy":"ClusterFirstWithHostNet"}}}}
    ```
4.  **Routage HTTP (`confs/ingress.yaml`) :**
    *   Si le client envoie une requête avec le header `Host: app1.com`, l'Ingress la route vers le service `app-one` (1 pod réplique).
    *   Si le client envoie une requête avec le header `Host: app2.com`, l'Ingress la route vers le service `app-two` (3 pods répliques).
    *   Pour toute autre valeur de header (ou adresse IP directe), le trafic est routé vers l'application par défaut `app-three`.

---

### 📍 Partie 3 — K3d & Argo CD (GitOps local)
Cette partie supprime la virtualisation lourde (Vagrant) au profit de K3d sur notre machine locale.

**Mécanique technique :**
1.  **Création du cluster K3d :**
    ```bash
    sudo k3d cluster create inception-of-things --agents 2 --port "80:80@loadbalancer" --port "8888:8888@loadbalancer"
    ```
    Le cluster se compose de 3 conteneurs Docker (1 serveur, 2 agents) et d'un conteneur faisant office de Load Balancer pour mapper les ports hôtes vers le cluster.
2.  **Déploiement d'Argo CD :** Installé via Helm dans le namespace `argocd`.
3.  **Application Argo CD (`confs/argocd-application.yaml`) :**
    Ce fichier YAML indique à Argo CD de surveiller notre dépôt GitHub public (`https://github.com/0xysan/Inception-of-Things.git`) sur la branche `app`.
    Il applique automatiquement tous les fichiers YAML trouvés à la racine de cette branche dans le namespace `dev`.
4.  **Le Refresh Agent (`confs/cronjob-refresh.yaml`) :**
    Normalement, Argo CD n'interroge les dépôts publics que toutes les 3 minutes.
    Pour la soutenance, nous déployons un CronJob Kubernetes qui tourne **chaque minute** et force la synchronisation de l'application :
    ```bash
    kubectl annotate application dev-app -n argocd argocd.argoproj.io/refresh=hard --overwrite
    ```
5.  **Mise à jour v1 -> v2 :** En modifiant le tag d'image de `v1` à `v2` dans le dépôt Git, Argo CD détecte la différence, télécharge la nouvelle image et effectue une mise à jour applicative transparente (rollout) sur le port `8888`.

---

### 📍 Bonus — GitLab Local (GitOps Interne)
Le bonus rend le cluster 100% autonome en hébergeant GitLab directement dans le cluster (namespace `gitlab`).

**Mécanique technique :**
1.  **GitLab Helm Chart (`confs/gitlab-value.yaml`) :**
    Déploiement de GitLab avec des ressources très réduites pour ne pas saturer la RAM (sidekiq réduit, postgresql minimisé, runners désactivés).
2.  **Script de Setup GitOps (`gitlab_gitops_setup.sh`) :**
    - Attend que la page de login de GitLab soit accessible.
    - Récupère le mot de passe root auto-généré dans le secret Kubernetes de GitLab.
    - Clône la branche applicative du dépôt distant.
    - Pousse cette branche dans notre GitLab local privé : `http://gitlab.localhost/root/gitops_argocd.git`.
3.  **Secret Repository pour Argo CD :**
    Argo CD a besoin d'identifiants pour clôner ce dépôt GitLab privé. Nous déployons un secret Kubernetes contenant le token root et tagué avec le label :
    `argocd.argoproj.io/secret-type: repository`.
4.  **Application Argo CD :**
    Nous mettons à jour `repoURL` pour pointer vers le service interne DNS de Kubernetes :
    `http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/gitops_argocd.git`.

---

## 📋 4. Liste des Commandes de Soutenance (À exécuter pas à pas)

Voici les commandes exactes à montrer à votre correcteur.

### 🔍 Partie 1 — K3s & Vagrant (2 VMs)
1.  **Vérifier le statut des deux VMs Vagrant :**
    ```bash
    vagrant status
    ```
2.  **Se connecter en SSH à la machine Server :**
    ```bash
    vagrant ssh artgirarS
    ```
3.  **Prouver que le Worker s'est bien connecté au Server :**
    ```bash
    k get nodes -o wide
    # Attendu: artgirarS (control-plane,master) et artgirarSW (worker) en statut Ready.
    ```

---

### 🔍 Partie 2 — K3s & 3 Applications (1 VM)
1.  **Se connecter à la machine de la Partie 2 :**
    ```bash
    vagrant ssh etaquetS
    ```
2.  **Montrer les Déploiements et les Pods (app2 doit avoir 3 répliques) :**
    ```bash
    kubectl get deployments,pods -n default
    # Attendu :
    # app-one (1 pod)
    # app-two (3 pods)
    # app-three (1 pod)
    ```
3.  **Montrer les Services associés :**
    ```bash
    kubectl get services -n default
    ```
4.  **Montrer la configuration de l'Ingress :**
    ```bash
    kubectl get ingress apps-ingress -o yaml
    ```
5.  **Tester le routage HTTP depuis votre machine hôte (ou depuis la VM) via `curl` :**
    ```bash
    # Test vers app1.com
    curl -H "Host: app1.com" http://192.168.56.110
    
    # Test vers app2.com (répétez pour voir le load balancing entre les 3 pods d'app2)
    curl -H "Host: app2.com" http://192.168.56.110
    
    # Test par défaut (pas de Host ou Host inconnu -> redirige vers app3)
    curl http://192.168.56.110
    curl -H "Host: inconnu.com" http://192.168.56.110
    ```

---

### 🔍 Partie 3 — K3d & Argo CD
1.  **Lancer l'installation complète :**
    ```bash
    cd p3/scripts && make
    ```
2.  **Montrer les conteneurs Docker créés par K3d :**
    ```bash
    docker ps
    # Attendu : 3 à 4 conteneurs k3d (server, agents, loadbalancer)
    ```
3.  **Récupérer le mot de passe administrateur initial de la console Argo CD :**
    ```bash
    sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    ```
4.  **Ouvrir l'UI d'Argo CD :**
    Allez sur `http://argocd.localhost` (Login : `admin`, utiliser le mot de passe récupéré).
5.  **Tester la synchronisation automatique (Démo GitOps v1 -> v2) :**
    *   Consulter l'application déployée sur `http://localhost`. Elle affiche "v1".
    *   Modifier le tag de l'image (de `v1` à `v2`) dans votre fichier de déploiement sur votre dépôt Git (branche `app`).
    *   Pusher le commit.
    *   Sur l'UI d'Argo CD (ou après max 1 min grâce au refresh agent), montrer que Argo CD passe en `OutOfSync`, puis télécharge l'image et synchronise l'application.
    *   Rafraîchir `http://localhost`. L'application affiche désormais "v2" !

---

### 🔍 Bonus — GitLab Interne
1.  **Lancer le déploiement du Bonus :**
    ```bash
    cd bonus/scripts && make
    ```
2.  **Récupérer le mot de passe administrateur de GitLab :**
    ```bash
    sudo kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d
    ```
3.  **Accéder aux interfaces :**
    *   GitLab : `http://gitlab.localhost` (Login : `root`, mot de passe ci-dessus)
    *   Argo CD : `http://argocd.localhost`
4.  **Démontrer la synchronisation GitOps avec le dépôt interne :**
    *   Montrer dans l'UI d'Argo CD que le dépôt configuré pointe bien vers l'adresse interne : `http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/gitops_argocd.git`.
    *   Cloner/Modifier le tag d'image dans GitLab local, commiter, pusher.
    *   Montrer la synchronisation automatique de l'application sur le cluster.

---

## ❓ 5. Questions / Réponses typiques des Correcteurs

*   **Q : Pourquoi K3s utilise-t-il SQLite à la place d'etcd par défaut ?**
    *R : `etcd` est une base clé-valeur distribuée très gourmande en mémoire vive (RAM) et en CPU, nécessitant une gestion fine des disques (I/O). Pour rester "light" et s'exécuter sur de petits systèmes (IoT/Edge), K3s remplace par défaut `etcd` par une base de données relationnelle SQLite classique, beaucoup moins gourmande.*

*   **Q : Comment fonctionne la communication réseau entre les pods (CNI) ?**
    *R : K3s utilise **Flannel** par défaut comme CNI (Container Network Interface). Flannel crée un réseau virtuel overlay (généralement via VXLAN) attribuant une adresse IP unique et routable à chaque Pod au sein de l'ensemble des nœuds du cluster.*

*   **Q : À quoi sert l'argument `--write-kubeconfig-mode=644` lors du démarrage de K3s ?**
    *R : Par défaut, K3s crée le fichier de configuration du cluster (`/etc/rancher/k3s/k3s.yaml`) avec des droits d'accès restreints à root (600). Le définir sur 644 permet à d'autres utilisateurs non-root (comme l'utilisateur `vagrant`) de lire la configuration et d'exécuter des commandes `kubectl`.*

*   **Q : C'est quoi la différence entre l'état "Déclaré" et l'état "Réel" dans Argo CD ?**
    *R :
    *   L'état **Déclaré** correspond aux manifestes YAML stockés dans le dépôt Git (ce que l'on veut obtenir).
    *   L'état **Réel** correspond aux ressources tournant actuellement dans le cluster Kubernetes (ce qui tourne en pratique).
    Argo CD effectue continuellement une boucle de réconciliation pour aligner l'état réel sur l'état déclaré.*

*   **Q : Pourquoi a-t-on besoin du paramètre `selfHeal: true` ?**
    *R : Si un administrateur système modifie ou supprime manuellement une ressource dans le cluster (ex: en faisant `kubectl delete deployment`), Argo CD va immédiatement détecter que l'état réel ne correspond plus à l'état déclaré dans Git, et recréer la ressource manquante de manière autonome.*

*   **Q : Quelle est la différence entre un Service de type ClusterIP, NodePort et LoadBalancer ?**
    *R :
    *   **ClusterIP (défaut) :** Expose le Service sur une IP interne du cluster. Le service n'est accessible que depuis l'intérieur du cluster.
    *   **NodePort :** Expose le Service sur un port statique sur chaque nœud du cluster (généralement entre 30000 et 32767). Le Service devient accessible depuis l'extérieur en ciblant `<IP_du_Noeud>:<NodePort>`.
    *   **LoadBalancer :** Expose le Service en externe à l'aide d'un load balancer de fournisseur Cloud (AWS, GCP, etc.). En local avec K3s, cela utilise un outil intégré (Klipper-LB) pour rediriger le trafic.*

---

## 🛠️ Boîte à outils de Debugging en direct

Si un pod ne démarre pas devant le correcteur, gardez votre sang-froid et utilisez ces commandes :

1.  **Vérifier le statut global des pods dans tous les namespaces :**
    ```bash
    kubectl get pods -A
    ```
2.  **Consulter les logs d'un pod spécifique :**
    ```bash
    kubectl logs -n <namespace> <nom_du_pod>
    ```
3.  **Inspecter les événements d'un pod (pourquoi il ne démarre pas) :**
    ```bash
    kubectl describe pod -n <namespace> <nom_du_pod>
    ```
4.  **Lancer K9s pour avoir une vue visuelle immédiate du cluster :**
    ```bash
    sudo k9s
    ```
