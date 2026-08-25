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

