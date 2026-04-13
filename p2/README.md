# Depedencies
To install some depedencies you can do the following :
`sudo apt update;
sudo apt install -y \
  qemu-kvm \
  libvirt-daemon-system \
  libvirt-dev \
  ruby-dev \
  build-essential \
  gcc \
  make`

# Plugins
Install the plugin for libvirt with the following :
`vagrant plugin install vagrant-libvirt`

then you will be able to run with libvirt !