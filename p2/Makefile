flags = 2>&1 | grep -v '\[fog\]\[WARNING\]'

all:
	@echo "===> Starting Vagrant machines..."
	@vagrant up --provider=libvirt $(flags)

clean:
	@echo "===> Destroying Vagrant machines..."
	@vagrant destroy -f $(flags)
	@echo "===> Removing Vagrant boxes..."
	@rm -rf .vagrant

fclean: clean
	@echo "===> Removing Vagrant boxes..."
	@vagrant box remove debian/trixie64 --all

re: clean all

reload:
	@echo "===> Reloading Vagrant machines..."
	@vagrant up --provider=libvirt --provision $(flags)

setup:
	@echo "===> Installing Vagrant libvirt plugin..."
	@vagrant plugin install vagrant-libvirt

.PHONY: all clean re reload setup fclean