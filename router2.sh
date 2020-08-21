export DEBIAN_FRONTEND=noninteractive
sudo su
apt-get update

# installing tcpdump
apt-get install -y tcpdump --assume-yes

# enable IP forwarding
sysctl net.ipv4.ip_forward=1 

# add IP addresses to the interfaces and set it "up"
ip add add 15.0.4.1/25 dev enp0s8
ip add add 15.0.6.2/30 dev enp0s9
ip link set enp0s8 up
ip link set enp0s9 up


# delete the dafault gateway
ip route del default

# Both lines are used to create static routes to reach subnet "Hosts-A" and "Hosts-B" via router-1
ip route add 15.0.0.0/24 via 15.0.6.1 dev enp0s9
ip route add 15.0.2.0/23 via 15.0.6.1 dev enp0s9