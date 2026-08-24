# Dependencies

The commands below work on Debian 13 and Arch Linux. Run them from `/iot` or
from the directory containing this project.

On Debian 13:

```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-dev ruby-dev \
  build-essential gcc make vagrant
sudo systemctl enable --now libvirtd
```

On Arch Linux:

```bash
sudo pacman -Syu --needed qemu-desktop libvirt dnsmasq virt-manager \
  ruby base-devel gcc make vagrant
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm "$USER"
```

# Plugins
Install the plugin for libvirt with the following :
`vagrant plugin install vagrant-libvirt`

Then start the environment with `make`.
