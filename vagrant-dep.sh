#!/usr/bin/env bash

set -euo pipefail

if ! command -v yay >/dev/null 2>&1 && ! command -v apt-get >/dev/null 2>&1; then
  printf '%s\n' 'Error: yay (Arch Linux) or apt-get (Debian) is required.' >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  printf '%s\n' 'Error: sudo is required.' >&2
  exit 1
fi

TARGET_USER="${SUDO_USER:-${USER:-}}"
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
  printf '%s\n' 'Error: run this script as a regular user, not directly as root.' >&2
  exit 1
fi

if command -v yay >/dev/null 2>&1; then
  PACKAGES=(
    qemu-desktop
    libvirt
    dnsmasq
    iptables-nft
    vagrant
    ruby
    base-devel
    curl
    ca-certificates
    git
  )
  printf '%s\n' '==> Installing Arch Linux dependencies with yay...'
  yay -Syu --needed --noconfirm "${PACKAGES[@]}"
else
  PACKAGES=(
    qemu-kvm
    libvirt-daemon-system
    libvirt-clients
    libvirt-dev
    dnsmasq
    vagrant
    ruby
    ruby-dev
    build-essential
    curl
    ca-certificates
    git
  )
  printf '%s\n' '==> Installing Debian dependencies...'
  sudo apt-get update
  sudo apt-get install -y "${PACKAGES[@]}"
fi

printf '%s\n' '==> Enabling libvirt...'
sudo systemctl enable --now libvirtd.service

cleanup_vagrant_network() {
  printf '%s\n' '==> Checking for stale Vagrant libvirt networking...'

  local running_domains
  running_domains=$(sudo virsh list --state-running --name 2>/dev/null | sed '/^$/d' || true)
  if [ -n "$running_domains" ]; then
    printf '%s\n' 'Running libvirt domains detected; network cleanup skipped.'
    return
  fi

  if sudo virsh net-info vagrant-libvirt >/dev/null 2>&1; then
    sudo virsh net-destroy vagrant-libvirt >/dev/null 2>&1 || true
    sudo virsh net-undefine vagrant-libvirt >/dev/null 2>&1 || true
    printf '%s\n' 'Stale vagrant-libvirt network removed.'
  fi

  local dnsmasq_pids
  dnsmasq_pids=$(pgrep -f '/var/lib/libvirt/dnsmasq/vagrant-libvirt.conf' || true)
  if [ -n "$dnsmasq_pids" ]; then
    sudo kill $dnsmasq_pids || true
    printf '%s\n' 'Stale Vagrant dnsmasq process stopped.'
  fi

  sudo systemctl restart libvirtd.service
}

cleanup_vagrant_network

printf '%s\n' '==> Granting virtualization permissions...'
sudo usermod -aG libvirt,kvm "$TARGET_USER"

PRIVATE_NET='192.168.56.0/24'

configure_firewall() {
  printf '%s\n' '==> Configuring firewall for the Vagrant private network...'

  if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow from "$PRIVATE_NET" to any port 22 proto tcp comment 'Vagrant SSH' >/dev/null
    sudo ufw allow from "$PRIVATE_NET" to any port 80 proto tcp comment 'K3s HTTP ingress' >/dev/null
    sudo ufw allow from "$PRIVATE_NET" to any port 6443 proto tcp comment 'K3s API' >/dev/null
    sudo ufw allow from "$PRIVATE_NET" to any port 10250 proto tcp comment 'K3s kubelet' >/dev/null
    sudo ufw allow from "$PRIVATE_NET" to any port 8472 proto udp comment 'K3s Flannel VXLAN' >/dev/null
    if sudo ufw status | grep -q 'Status: inactive'; then
      printf '%s\n' 'Firewall rules added to ufw (ufw remains inactive).'
    else
      printf '%s\n' 'Firewall rules added to active ufw.'
    fi
    return
  fi

  if command -v firewall-cmd >/dev/null 2>&1; then
    local rules=(
      '22/tcp'
      '80/tcp'
      '6443/tcp'
      '10250/tcp'
      '8472/udp'
    )
    for port in "${rules[@]}"; do
      rule="rule family=ipv4 source address=${PRIVATE_NET} port port=${port%/*} protocol=${port#*/} accept"
      if ! sudo firewall-cmd --permanent --query-rich-rule="$rule" >/dev/null 2>&1; then
        sudo firewall-cmd --permanent --add-rich-rule="$rule" >/dev/null
      fi
    done
    sudo firewall-cmd --reload >/dev/null
    printf '%s\n' 'Firewall rules added to firewalld.'
    return
  fi

  printf '%s\n' 'No supported firewall detected; no firewall settings changed.'
}

configure_firewall

printf '%s\n' '==> Installing the Vagrant libvirt plugin...'
USER_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

printf '\n%s\n' 'Setup complete for p1 and p2.'
printf '%s\n' 'Open a new session before using p1 or p2.'
printf '%s\n' 'Then run: cd <project_dir>/p1 && make up'
