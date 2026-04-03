all:
	vagrant up --provider virtualbox

clean:
	vagrant destroy -f
	rm -rf .vagrant
# 	vagrant box remove debian/bookworm64 --all

re: clean all

# dependencies:
# 	apt install -y vagrant
