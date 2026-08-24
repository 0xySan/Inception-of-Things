# Inception of Things

Projet d'introduction a Kubernetes avec K3s, K3d, Vagrant, Helm et Argo CD.

L'ensemble du projet **doit etre execute dans une machine virtuelle**. Le
dossier `/iot` est le dossier racine du projet dans cette VM.

## Sommaire

1. [Prerequis](#prerequis)
2. [Structure](#structure)
3. [Partie 1](#partie-1--k3s-et-vagrant)
4. [Partie 2](#partie-2--k3s-et-trois-applications)
5. [Partie 3](#partie-3--k3d-et-argo-cd)
6. [Bonus](#bonus--gitlab)
7. [Diagnostic](#diagnostic)

## Prerequis

Les commandes suivantes sont a executer dans la VM, depuis `/iot`.

### Debian 13

```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-dev ruby-dev \
  build-essential gcc make vagrant curl ca-certificates git
sudo systemctl enable --now libvirtd
```

### Arch Linux

```bash
sudo pacman -Syu --needed qemu-desktop libvirt dnsmasq virt-manager \
  ruby base-devel gcc make vagrant curl ca-certificates git
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm "$USER"
```

Installer le provider Vagrant libvirt :

```bash
vagrant plugin install vagrant-libvirt
```

Pour K3d, Docker, kubectl, Helm et les outils associes :

```bash
cd /iot/p3/scripts
./dependency-check.sh
newgrp docker
```

Le script `dependency-check.sh` reconnait Debian avec `apt` et Arch Linux avec
`pacman`.

## Structure

```text
/iot
├── p1/
│   ├── Vagrantfile
│   ├── Makefile
│   ├── confs/
│   └── scripts/
├── p2/
│   ├── Vagrantfile
│   ├── Makefile
│   ├── confs/
│   └── scripts/
├── p3/
│   ├── confs/
│   └── scripts/
└── bonus/
    ├── confs/
    └── scripts/
```

Les parties obligatoires sont `p1`, `p2` et `p3`. Le dossier `bonus` contient
la partie GitLab.

## Partie 1 - K3s et Vagrant

Deux machines Vagrant sont creees :

- `<login>S` : serveur K3s, IP `192.168.56.110`, 1 CPU et 1024 MiB ;
- `<login>SW` : agent K3s, IP `192.168.56.111`, 1 CPU et 512 MiB.

Le serveur est installe en mode control-plane. L'agent rejoint le serveur avec
le token K3s. Le script de chaque machine fournit la commande `k` pour
executer kubectl via K3s.

Lancer la partie :

```bash
cd /iot/p1
make up
vagrant status
vagrant ssh <login>S
```

Verifier le cluster :

```bash
k get nodes -o wide
k get pods -A
```

Deux noeuds doivent etre en etat `Ready`.

Nettoyer :

```bash
cd /iot/p1
make clean
```

## Partie 2 - K3s et trois applications

Une machine Vagrant `<login>S` est creee avec l'adresse
`192.168.56.110`. K3s est installe en mode serveur, Traefik est desactive et
Ingress Nginx est utilise pour router les requetes HTTP.

Les applications sont accessibles selon le header `Host` :

| Host | Application | Replicas |
| --- | --- | ---: |
| `app1.com` | `app-one` | 1 |
| `app2.com` | `app-two` | 3 |
| autre ou absent | `app-three` | 1 |

Lancer la partie :

```bash
cd /iot/p2
make
vagrant status
vagrant ssh <login>S
```

Verifier les ressources :

```bash
kubectl get nodes
kubectl get deployments,pods,services
kubectl get ingress apps-ingress -o yaml
```

Tester le routage :

```bash
curl -H 'Host: app1.com' http://192.168.56.110
curl -H 'Host: app2.com' http://192.168.56.110
curl http://192.168.56.110
curl -H 'Host: inconnu.com' http://192.168.56.110
```

Nettoyer :

```bash
cd /iot/p2
make clean
```

## Partie 3 - K3d et Argo CD

Cette partie utilise K3d dans Docker et ne necessite pas de Vagrant.
L'installation cree un cluster `inception-of-things` avec un serveur et deux
agents.

Deux namespaces sont utilises :

- `argocd` pour Argo CD et ses ressources ;
- `dev` pour l'application geree par GitOps.

### Depot GitOps

Le depot GitOps est un depot GitHub public distinct de la branche de travail
principale. Les manifestes de l'application sont stockes sur une branche
dediee nommee `app` (branche **APP**).

Argo CD surveille cette branche et synchronise les fichiers YAML de sa racine
vers le namespace `dev`. Le depot configure dans le manifeste est :

```text
https://github.com/<login>/Inception-of-Things.git
```

Le nom du depot public doit contenir le login d'un membre du groupe. Si
l'adresse du depot est modifiee, mettre a jour `repoURL` dans :

```text
p3/confs/argocd-application.yaml
```

### Installation

```bash
cd /iot/p3/scripts
make
```

Verifier le cluster et Argo CD :

```bash
sudo k3d cluster list
sudo kubectl get nodes
sudo kubectl get namespaces
sudo kubectl get pods -A
sudo kubectl get application -n argocd
sudo kubectl get deployment,service -n dev
```

Acceder a Argo CD :

```text
http://argocd.localhost
```

Recuperer le mot de passe initial :

```bash
sudo kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; printf '\n'
```

Tester l'application sur le port demande par le sujet :

```bash
curl http://localhost:8888
```

### Mise a jour GitOps

La branche `app` contient deux versions de l'image de l'application. Modifier
le tag dans `deployment.yaml`, puis pousser la modification sur la branche
`app` :

```bash
git checkout app
sed -i 's/:v1/:v2/' deployment.yaml
git add deployment.yaml
git commit -m "Update application version"
git push origin app
```

Argo CD detecte la difference entre Git et le cluster, met a jour le
Deployment et synchronise le namespace `dev`.

```bash
sudo kubectl get application dev-app -n argocd -o wide
sudo kubectl get pods -n dev
curl http://localhost:8888
```

Le CronJob `argocd-refresh` demande un rafraichissement au maximum toutes les
minutes.

Nettoyer :

```bash
cd /iot/p3/scripts
make clean
```

## Bonus - GitLab

Le bonus ajoute GitLab au cluster K3d dans le namespace `gitlab`. PostgreSQL et
Redis sont deployes comme dependances externes avec des ressources reduites.

Le script migre la branche `app` du depot GitHub vers un depot GitLab local,
puis configure Argo CD pour utiliser ce depot comme source GitOps.

Lancer le bonus apres validation de la partie 3 :

```bash
cd /iot/bonus/scripts
make
```

Verifier les ressources :

```bash
sudo kubectl get pods -n gitlab
sudo kubectl get ingress -A
sudo kubectl get application dev-app -n argocd \
  -o jsonpath='{.spec.source.repoURL}{"\n"}'
```

Acceder aux services :

```text
GitLab : http://gitlab.localhost
Argo CD: http://argocd.localhost
App    : http://localhost:8888
```

Recuperer le mot de passe root GitLab :

```bash
sudo kubectl -n gitlab get secret gitlab-gitlab-initial-root-password \
  -o jsonpath='{.data.password}' | base64 -d; printf '\n'
```

Le depot GitOps interne utilise le service Kubernetes suivant :

```text
http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/gitops_argocd.git
```

Nettoyer :

```bash
cd /iot/bonus/scripts
make clean
```

## Diagnostic

Etat general :

```bash
sudo kubectl get pods -A
sudo kubectl get events -A --sort-by=.lastTimestamp
```

Details d'un pod :

```bash
sudo kubectl describe pod -n <namespace> <pod>
sudo kubectl logs -n <namespace> <pod>
```

Ingress :

```bash
sudo kubectl get ingress -A
sudo kubectl get services -A
sudo kubectl get pods -n kube-system
```

Argo CD :

```bash
sudo kubectl get application -n argocd -o yaml
sudo kubectl logs -n argocd deploy/argocd-application-controller
sudo kubectl logs -n argocd deploy/argocd-repo-server
```

Interface terminale :

```bash
sudo k9s
```

---

# Inception of Things - English

Introduction project to Kubernetes with K3s, K3d, Vagrant, Helm and Argo CD.

The whole project **must run inside a virtual machine**. The project root in
that VM is `/iot`.

## Requirements

Run the following commands inside the VM.

### Debian 13

```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-dev ruby-dev \
  build-essential gcc make vagrant curl ca-certificates git
sudo systemctl enable --now libvirtd
```

### Arch Linux

```bash
sudo pacman -Syu --needed qemu-desktop libvirt dnsmasq virt-manager \
  ruby base-devel gcc make vagrant curl ca-certificates git
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm "$USER"
```

Install Vagrant's libvirt provider:

```bash
vagrant plugin install vagrant-libvirt
```

Install the tools required by K3d:

```bash
cd /iot/p3/scripts
./dependency-check.sh
newgrp docker
```

The dependency script supports Debian through `apt` and Arch Linux through
`pacman`.

## Part 1 - K3s and Vagrant

Two Vagrant machines are created:

- `<login>S`: K3s server at `192.168.56.110`, 1 CPU and 1024 MiB;
- `<login>SW`: K3s agent at `192.168.56.111`, 1 CPU and 512 MiB.

```bash
cd /iot/p1
make up
vagrant status
vagrant ssh <login>S
k get nodes -o wide
k get pods -A
```

Both nodes must be `Ready`. Clean with `make clean` from `/iot/p1`.

## Part 2 - K3s and three applications

One Vagrant machine runs K3s at `192.168.56.110`. Traefik is disabled and
Ingress Nginx routes requests according to the `Host` header:

| Host | Application | Replicas |
| --- | --- | ---: |
| `app1.com` | `app-one` | 1 |
| `app2.com` | `app-two` | 3 |
| other or missing | `app-three` | 1 |

```bash
cd /iot/p2
make
vagrant ssh <login>S
kubectl get deployments,pods,services
kubectl get ingress apps-ingress -o yaml
curl -H 'Host: app1.com' http://192.168.56.110
curl -H 'Host: app2.com' http://192.168.56.110
curl http://192.168.56.110
```

Clean with `make clean` from `/iot/p2`.

## Part 3 - K3d and Argo CD

This part uses K3d in Docker and does not use Vagrant. It creates one server,
two agents, and the `argocd` and `dev` namespaces.

### GitOps repository

The GitOps repository is a public GitHub repository with a dedicated `app`
branch, separate from the main working branch. Argo CD watches this branch and
syncs its root YAML files to the `dev` namespace.

```text
https://github.com/<login>/Inception-of-Things.git
```

The public repository name must contain a group member's login. If the URL
changes, update `repoURL` in `p3/confs/argocd-application.yaml`.

Install and check:

```bash
cd /iot/p3/scripts
make
sudo k3d cluster list
sudo kubectl get nodes
sudo kubectl get pods -A
sudo kubectl get application -n argocd
sudo kubectl get deployment,service -n dev
```

Argo CD is available at `http://argocd.localhost`, and the application at
`http://localhost:8888`.

Retrieve the initial Argo CD password:

```bash
sudo kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; printf '\n'
```

To test GitOps, change the image tag from `v1` to `v2` in `deployment.yaml` on
the `app` branch, then commit and push:

```bash
git checkout app
sed -i 's/:v1/:v2/' deployment.yaml
git add deployment.yaml
git commit -m "Update application version"
git push origin app
```

Check the synchronization:

```bash
sudo kubectl get application dev-app -n argocd -o wide
sudo kubectl get pods -n dev
curl http://localhost:8888
```

Clean with `make clean` from `/iot/p3/scripts`.

## Bonus - GitLab

The bonus adds GitLab to the K3d cluster in the `gitlab` namespace. PostgreSQL
and Redis are deployed as lightweight external dependencies. The script copies
the `app` branch to a local GitLab repository and configures Argo CD to use it.

```bash
cd /iot/bonus/scripts
make
sudo kubectl get pods -n gitlab
sudo kubectl get ingress -A
sudo kubectl get application dev-app -n argocd \
  -o jsonpath='{.spec.source.repoURL}{"\n"}'
```

Services:

```text
GitLab: http://gitlab.localhost
Argo CD: http://argocd.localhost
Application: http://localhost:8888
```

Clean with `make clean` from `/iot/bonus/scripts`.

## Troubleshooting

```bash
sudo kubectl get pods -A
sudo kubectl get events -A --sort-by=.lastTimestamp
sudo kubectl describe pod -n <namespace> <pod>
sudo kubectl logs -n <namespace> <pod>
sudo kubectl get ingress -A
sudo kubectl get application -n argocd -o yaml
sudo k9s
```
