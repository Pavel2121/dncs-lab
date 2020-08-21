export DEBIAN_FRONTEND=noninteractive
sudo su
apt-get update

# installing tcpdump
apt-get install -y tcpdump --assume-yes

# enable IP forwarding
sysctl net.ipv4.ip_forward=1

# add IP address to the interface and set it "up"
ip add add 15.0.6.1/30 dev enp0s9
ip link set enp0s9 up

# create a subinterface for VLAN 2
ip link add link enp0s8 name enp0s8.2 type vlan id 2
ip add add 15.0.0.1/24 dev enp0s8.2

# create a subinterfaces for VLAN 3
ip link add link enp0s8 name enp0s8.3 type vlan id 3
ip add add 15.0.2.1/23 dev enp0s8.3

# set interfaces up
ip link set enp0s8 up
ip link set enp0s8.2 up
ip link set enp0s8.3

# delete the default gateway
ip route del default

# create a static route to reach subnet "Hub" via router-2
ip route add 15.0.4.0/25 via 15.0.6.2 dev enp0s9