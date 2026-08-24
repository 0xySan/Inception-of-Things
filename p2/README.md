# Partie 2 - K3s et trois applications

Cette partie doit etre executee dans une machine virtuelle. Le projet est
place dans `/iot`.

## Objectif du sujet

Une seule machine Vagrant doit executer K3s en mode serveur et heberger trois
applications web :

- l'application 1 avec le Host `app1.com` ;
- l'application 2 avec le Host `app2.com` ;
- l'application 3 par defaut pour tout autre Host.

L'application 2 doit avoir trois replicas.

La machine doit utiliser le nom `<login>S` et l'adresse IP
`192.168.56.110`.

## Prerequis

### Debian 13

```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-dev ruby-dev \
  build-essential gcc make vagrant
sudo systemctl enable --now libvirtd
```

### Arch Linux

```bash
sudo pacman -Syu --needed qemu-desktop libvirt dnsmasq virt-manager \
  ruby base-devel gcc make vagrant
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm "$USER"
```

Installer le provider Vagrant libvirt :

```bash
vagrant plugin install vagrant-libvirt
```

## Fichiers

- `Vagrantfile` : cree la VM et installe K3s server ;
- `confs/app1.yaml` : Deployment et Service de l'application 1 ;
- `confs/app2.yaml` : Deployment et Service de l'application 2 avec 3 replicas ;
- `confs/app3.yaml` : Deployment et Service de l'application par defaut ;
- `confs/ingress.yaml` : regles de routage HTTP par Host ;
- `scripts/` : fichiers servis par les applications.

Traefik est desactive dans le `Vagrantfile`. Ingress Nginx est installe puis
configure pour ecouter sur le port 80 de la VM.

## Installation

```bash
cd /iot/p2
make
```

La VM peut aussi etre demarree directement avec :

```bash
vagrant up --provider=libvirt
```

## Verification

```bash
vagrant status
vagrant ssh <login>S
```

Dans la VM :

```bash
kubectl get nodes
kubectl get deployments
kubectl get pods
kubectl get services
kubectl get ingress apps-ingress -o yaml
```

Le noeud doit etre `Ready`. Les replicas attendus sont :

```text
app-one   1
app-two   3
app-three 1
```

Tester le routage depuis la VM ou depuis une machine pouvant joindre
`192.168.56.110` :

```bash
curl -H 'Host: app1.com' http://192.168.56.110
curl -H 'Host: app2.com' http://192.168.56.110
curl http://192.168.56.110
curl -H 'Host: inconnu.com' http://192.168.56.110
```

Les deux premiers appels ciblent respectivement app1 et app2. Les deux
derniers ciblent l'application 3 par defaut.

Verifier les trois pods d'app2 :

```bash
kubectl get pods -l app=app-two -o wide
kubectl get endpoints app-two
```

## Nettoyage

```bash
cd /iot/p2
make clean
```

---

# Part 2 - K3s and three applications

This part must run inside a virtual machine. The project is located in `/iot`.

## Subject requirements

One Vagrant machine must run K3s in server mode and host three web
applications:

- application 1 with the `app1.com` Host;
- application 2 with the `app2.com` Host;
- application 3 as the default application for every other Host.

Application 2 must have three replicas.

The machine must use the name `<login>S` and IP address `192.168.56.110`.

## Requirements

### Debian 13

```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-dev ruby-dev \
  build-essential gcc make vagrant
sudo systemctl enable --now libvirtd
```

### Arch Linux

```bash
sudo pacman -Syu --needed qemu-desktop libvirt dnsmasq virt-manager \
  ruby base-devel gcc make vagrant
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm "$USER"
```

Install the Vagrant libvirt provider:

```bash
vagrant plugin install vagrant-libvirt
```

## Files

- `Vagrantfile`: creates the VM and installs K3s server;
- `confs/app1.yaml`: Deployment and Service for application 1;
- `confs/app2.yaml`: Deployment and Service for application 2 with 3 replicas;
- `confs/app3.yaml`: Deployment and Service for the default application;
- `confs/ingress.yaml`: HTTP Host routing rules;
- `scripts/`: files served by the applications.

Traefik is disabled in the `Vagrantfile`. Ingress Nginx is installed and
configured to listen on the VM port 80.

## Installation

```bash
cd /iot/p2
make
```

Or start the VM directly:

```bash
vagrant up --provider=libvirt
```

## Verification

```bash
vagrant status
vagrant ssh <login>S
kubectl get nodes
kubectl get deployments,pods,services
kubectl get ingress apps-ingress -o yaml
```

The node must be `Ready`. Expected replicas:

```text
app-one   1
app-two   3
app-three 1
```

Test routing from the VM or from a machine that can reach
`192.168.56.110`:

```bash
curl -H 'Host: app1.com' http://192.168.56.110
curl -H 'Host: app2.com' http://192.168.56.110
curl http://192.168.56.110
curl -H 'Host: unknown.com' http://192.168.56.110
```

The first two requests target app1 and app2. The last two requests target the
default application 3.

Check application 2 replicas:

```bash
kubectl get pods -l app=app-two -o wide
kubectl get endpoints app-two
```

## Cleanup

```bash
cd /iot/p2
make clean
```
