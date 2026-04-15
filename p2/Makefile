all:
	vagrant up --provider=libvirt

clean:
	vagrant destroy -f
	rm -rf .vagrant

fclean: clean
	vagrant box remove generic/debian12 --all

re: clean all

reload:
	vagrant up --provider=libvirt --provision

setup:
	vagrant plugin install vagrant-libvirt

# dependencies:
# 	apt install -y vagrant

.PHONY: all clean re reload setup fclean