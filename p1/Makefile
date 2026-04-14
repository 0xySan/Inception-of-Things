up:
	vagrant up --provider libvirt

down:
	@vagrant halt

restart: down up

status:
	@vagrant status

clean:
	@vagrant destroy -f

fclean: clean
	rm -rf .vagrant


re: fclean up

# dependencies:
# 	apt install -y vagrant
