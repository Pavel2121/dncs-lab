export DEBIAN_FRONTEND=noninteractive
sudo su
apt-get update

# installing tcpdump
apt-get install -y tcpdump --assume-yes

# adds IP address to the interface and set it "up"
ip add add 15.0.0.2/24 dev enp0s8
ip link set enp0s8 up

# delete the default gateway
ip route del default

# sets the default gateway on router-1
ip route add default via 15.0.0.1