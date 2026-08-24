# Inception of Things

Ce depot contient les trois parties obligatoires du sujet Inception of Things
ainsi que le bonus GitLab. Les procedures ci-dessous sont adaptees a une VM
Debian 13 ou Arch Linux dans laquelle le depot est place dans `/iot`.

## 1. Controle du depot

| Partie | Attendu | Etat des fichiers |
| --- | --- | --- |
| p1 | Deux VM Vagrant, K3s server + agent | Conforme |
| p2 | Une VM, trois applications, Ingress et trois replicas pour app2 | Conforme |
| p3 | K3d, Argo CD, namespace `dev`, GitHub et mise a jour v1/v2 | Conforme, nom GitHub a confirmer |
| bonus | GitLab local et depot GitOps interne | Present, a tester apres p3 |

Le depot distant utilise pour p3 est `https://github.com/0xysan/Inception-of-Things.git`,
branche `app`. Cette branche contient `deployment.yaml` et le Service de
`playground-app` dans le namespace `dev`.

Le sujet demande que le nom du depot public contienne le login d'un membre du
groupe. Le proprietaire GitHub `0xysan` est bien un login de membre, mais le nom
visible du depot est `Inception-of-Things`. Si l'evaluation interprete cette
regle strictement sur le nom et non sur le chemin complet GitHub, renommer le
depot en incluant explicitement ce login et mettre a jour `repoURL` dans
`p3/confs/argocd-application.yaml`.

## 2. Structure

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

## 3. Etape 0 - Preparatifs Debian 13 ou Arch Linux

Depuis la VM, verifier la distribution avec `cat /etc/os-release`.

### Debian 13

```bash
cd /iot
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-dev ruby-dev \
  build-essential gcc make vagrant curl ca-certificates git
sudo systemctl enable --now libvirtd
```

### Arch Linux

```bash
cd /iot
sudo pacman -Syu --needed qemu-desktop libvirt dnsmasq virt-manager \
  ruby base-devel gcc make vagrant curl ca-certificates git
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm "$USER"
```

Installer ensuite le plugin Vagrant libvirt sur les deux distributions :

```bash
vagrant plugin install vagrant-libvirt
```

Pour p3, le script d'installation des dependances ajoute Docker, kubectl,
active Docker et ajoute l'utilisateur courant au groupe `docker`. Il reconnait
`apt` sur Debian et `pacman` sur Arch Linux :

```bash
cd /iot/p3/scripts
./dependency-check.sh
```

Apres l'ajout aux groupes Docker/libvirt, ouvrir une nouvelle session ou executer :

```bash
newgrp docker
```

## 4. Etape 1 - Deux noeuds K3s avec Vagrant

Le fichier `p1/Vagrantfile` declare :

- `artgirarS`, hostname `artgirarS`, IP `192.168.56.110`, 1 CPU et 1024 MiB ;
- `artgirarSW`, hostname `artgirarSW`, IP `192.168.56.111`, 1 CPU et 512 MiB ;
- K3s server sur le premier noeud ;
- K3s agent connecte a `https://192.168.56.110:6443` sur le second noeud ;
- l'outil `k` qui appelle `k3s kubectl`.

Lancer et controler :

```bash
cd /iot/p1
make up
vagrant status
vagrant ssh artgirarS
```

Dans le server :

```bash
k get nodes -o wide
k get pods -A
```

Resultat attendu : deux noeuds `Ready`, un control-plane et un worker.

Nettoyage :

```bash
cd /iot/p1
make down
make clean
```

## 5. Etape 2 - Trois applications et Ingress

Le fichier `p2/Vagrantfile` cree une seule VM `etaquetS` a l'adresse
`192.168.56.110`. Traefik est desactive et ingress-nginx est installe avec
`hostNetwork`, afin d'ecouter sur le port HTTP de la VM.

Les manifestes sont repartis ainsi :

- `app1.yaml` : Deployment `app-one`, 1 replica et Service `app-one` ;
- `app2.yaml` : Deployment `app-two`, 3 replicas et Service `app-two` ;
- `app3.yaml` : Deployment `app-three`, 1 replica et Service `app-three` ;
- `ingress.yaml` : routage par Host, avec `app-three` comme backend par defaut.

Lancer :

```bash
cd /iot/p2
make
vagrant status
vagrant ssh etaquetS
```

Controler dans la VM :

```bash
kubectl get nodes
kubectl get deployments,pods,services
kubectl get ingress apps-ingress -o yaml
```

Tester depuis la VM ou depuis l'hote :

```bash
curl -H 'Host: app1.com' http://192.168.56.110
curl -H 'Host: app2.com' http://192.168.56.110
curl http://192.168.56.110
curl -H 'Host: inconnu.com' http://192.168.56.110
```

Les deux premiers appels doivent afficher respectivement app1 et app2. Les
deux derniers doivent afficher app3. Pour observer les trois replicas d'app2 :

```bash
kubectl get pods -l app=app-two -o wide
kubectl get endpoints app-two
```

## 6. Etape 3 - K3d et Argo CD

Cette partie n'utilise pas Vagrant. `p3/scripts/install.sh` :

1. cree le cluster K3d `inception-of-things` avec 1 server et 2 agents ;
2. mappe les ports HTTP necessaires vers le load balancer ;
3. configure `~/.kube/config` ;
4. cree les namespaces `argocd` et `dev` ;
5. installe Helm et Argo CD ;
6. applique l'Application Argo CD et le CronJob de rafraichissement.

Le namespace `dev` est synchronise depuis la branche `app` du depot GitHub.
Argo CD applique tous les manifestes de la racine de cette branche, avec
`prune: true` et `selfHeal: true`.

Installation :

```bash
cd /iot/p3/scripts
make
```

Verification :

```bash
sudo k3d cluster list
sudo kubectl get nodes
sudo kubectl get ns
sudo kubectl get pods -A
sudo kubectl get application -n argocd
sudo kubectl get deployment,service -n dev
sudo kubectl get cronjob,jobs,pods -n argocd
```

Acces et mot de passe Argo CD :

```text
http://argocd.localhost
```

```bash
sudo kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; printf '\n'
```

Application (port demande par le sujet) :

```bash
curl http://localhost:8888
curl -H 'Host: localhost' http://127.0.0.1:8888
```

Pour verifier la synchronisation, modifier dans la branche `app` la ligne
`wil42/playground:v1` en `wil42/playground:v2`, puis commiter et pousser. Argo
CD doit passer par un etat `OutOfSync`, puis redeployer le pod et revenir a
`Synced`. Le CronJob demande un rafraichissement au maximum toutes les minutes.

```bash
sudo kubectl get application dev-app -n argocd \
  -o jsonpath='{.status.sync.status}{"\n"}'
sudo kubectl get pods -n dev
curl http://localhost:8888
```

Nettoyage :

```bash
cd /iot/p3/scripts
make clean
```

## 7. Etape 4 - Bonus GitLab local

Le bonus reprend le cluster K3d et ajoute GitLab dans le namespace `gitlab`.
Le script installe PostgreSQL et Redis externes, puis GitLab avec des
ressources reduites. Le script de migration clone la branche `app`, la pousse
dans le depot GitLab local et cree le Secret de depot lu par Argo CD.

Lancer apres avoir valide p3 :

```bash
cd /iot/bonus/scripts
make
```

Controler :

```bash
sudo kubectl get pods -n gitlab
sudo kubectl get ingress -A
sudo kubectl get application dev-app -n argocd \
  -o jsonpath='{.spec.source.repoURL}{"\n"}'
```

Acces :

```text
GitLab : http://gitlab.localhost
Argo CD: http://argocd.localhost
App    : http://localhost
```

Mot de passe root GitLab :

```bash
sudo kubectl -n gitlab get secret gitlab-gitlab-initial-root-password \
  -o jsonpath='{.data.password}' | base64 -d; printf '\n'
```

Le depot attendu par Argo CD est alors :
`http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/gitops_argocd.git`.

## 8. Diagnostic rapide

```bash
sudo kubectl get pods -A
sudo kubectl describe pod -n <namespace> <pod>
sudo kubectl logs -n <namespace> <pod>
sudo kubectl get events -A --sort-by=.lastTimestamp
sudo k9s
```

Pour un probleme d'Ingress :

```bash
sudo kubectl get ingress -A
sudo kubectl get svc -A
sudo kubectl get pods -n kube-system
```

Pour un probleme Argo CD :

```bash
sudo kubectl get application -n argocd -o yaml
sudo kubectl logs -n argocd deploy/argocd-application-controller
sudo kubectl logs -n argocd deploy/argocd-repo-server
```

## 9. Compatibilite et limites

- Debian 13 : supporte avec KVM, libvirt et le provider Vagrant libvirt.
- Arch Linux : supporte avec `qemu-desktop`, `libvirt` et le provider Vagrant
  libvirt.
- p1 et p2 necessitent KVM/libvirt et les droits sur les groupes `libvirt` et
  `kvm`.
- p3 et le bonus necessitent Docker pour executer K3d.
- `dependency-check.sh` reconnait Debian et Arch Linux pour les dependances de
  p3. Les services libvirt et les droits utilisateur sont prepares avant p1/p2.

## 10. Corrections appliquees lors du controle

- Ajout du dossier `p1/confs`, necessaire au montage Vagrant declare dans le
  Vagrantfile.
- Suppression de l'appel a `gitlab_gitops_setup.sh` dans p3 : ce script est
  reserve au bonus et n'existe pas dans la partie obligatoire.
- Clarification de la separation GitHub/p3 et GitLab/bonus.
- Procedures et chemins adaptes a Debian 13, Arch Linux et `/iot`.
- Correction et enrichissement de la documentation p2.
