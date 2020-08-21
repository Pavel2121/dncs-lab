export DEBIAN_FRONTEND=noninteractive

sudo su
apt-get update

# installing tcpdump, openvswitch and curl
apt-get install -y tcpdump
apt-get install -y openvswitch-common openvswitch-switch apt-transport-https ca-certificates curl software-properties-common

# creates a new bridge "br0"
ovs-vsctl add-br br0

# creates a trunk port and set interface up
ovs-vsctl add-port br0 enp0s8
ip link set enp0s8 up

# add a port on the bridge with tag=2 (VLAN 2) and set the interface up
ovs-vsctl add-port br0 enp0s9 tag=2
ip link set enp0s9 up

# add a port on the bridge with tag=3 (VLAN 3) and set the interface up
ovs-vsctl add-port br0 enp0s10 tag=3
ip link set enp0s10 up