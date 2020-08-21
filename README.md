# DNCS-LAB

Design of Networks and Communication Systems, University of Trento. The team is formed by Paolo Stefanolli and Milic Lazar

## Contents:

- [Network map](#Network-map)
- [Design Requirements](#Design-requirements)
- [Project solution](#Project-solution)
  - [Subnetting](#Subnetting)
  - [Assign IP addresses](#Assign-IP-Adresses)
  - [Set a VLAN](#Set-a-VLAN)
  - [Updated Network map with IP's and VLAN](#Updated-Network-map-with-IP's-and-VLAN)
- [Vagrantfile](#Vagranfile)
- [Configuring the network](#Configuring-the-network)
  - [router1.sh](#ROUTER-1)
  - [router2.sh](#ROUTER-2)
  - [switch.sh](#SWITCH)
  - [hosta.sh](#HOST-A)
  - [hostb.sh](#HOST-B)
  - [hostc.sh](#HOST-C)
- [How to test](#How-to-test)
- [Repository information](#Repository-information)


 # Network map

```
        +-----------------------------------------------------+
        |                                                     |
        |                                                     |eth0
        +--+--+                +------------+             +------------+
        |     |                |            |             |            |
        |     |            eth0|            |eth2     eth2|            |
        |     +----------------+  router-1  +-------------+  router-2  |
        |     |                |            |             |            |
        |     |                |            |             |            |
        |  M  |                +------------+             +------------+
        |  A  |                      |eth1                       |eth1
        |  N  |                      |                           |
        |  A  |                      |                           |
        |  G  |                      |                     +-----+----+
        |  E  |                      |eth1                 |          |
        |  M  |            +-------------------+           |          |
        |  E  |        eth0|                   |           |  host-c  |
        |  N  +------------+      SWITCH       |           |          |
        |  T  |            |                   |           |          |
        |     |            +-------------------+           +----------+
        |  V  |               |eth2         |eth3                |eth0
        |  A  |               |             |                    |
        |  G  |               |             |                    |
        |  R  |               |eth1         |eth1                |
        |  A  |        +----------+     +----------+             |
        |  N  |        |          |     |          |             |
        |  T  |    eth0|          |     |          |             |
        |     +--------+  host-a  |     |  host-b  |             |
        |     |        |          |     |          |             |
        |     |        |          |     |          |             |
        ++-+--+        +----------+     +----------+             |
        | |                              |eth0                   |
        | |                              |                       |
        | +------------------------------+                       |
        |                                                        |
        |                                                        |
        +--------------------------------------------------------+

```

# Design Requirements
- Hosts 1-a and 1-b are in two subnets (*Hosts-A* and *Hosts-B*) that must be able to scale up to respectively 180 and 294 usable addresses
- Host 2-c is in a subnet (*Hub*) that needs to accommodate up to 78 usable addresses
- Host 2-c must run a docker image (dustnic82/nginx-test) which implements a web-server that must be reachable from Host-1-a and Host-1-b
- No dynamic routing can be used
- Routes must be as generic as possible
- The lab setup must be portable and executed just by launching the `vagrant up` command

# Project solution

## Subnetting

We decide to divide our network in 4 sub-networks, with 2 of these that are VLAN based (to "split" the switch into two virtual switches). 

The 4 networks are:
- *"Hosts-A"*: this subnet contains **"host-a"**, other **178 hosts** and the **router-1 port** (enp0s8.2)
- *"Hosts-B"*: this subnet contains **"host-b"**, other **292 hosts** and the **router-2 port** (enp0s8.3)
- *"Hub"*: this subnet contains **"host-c"**, other **76 hosts** and the **router-2 port (enp0s8)**
- *"Connection"*: this subnet contains the 2 ports left on both routers (enp0s9 on both)

## Assign IP Adresses

We used IPs starting from 15.0.0.0 because there is no specification for a certain pool of addresses in requirements.

To assign IP adresses to the VMs we had to follow the requirements, that say:
- *"Hosts-A"* contains "host-a" and must be able to scale up to 180 usable addresses
- *"Hosts-B"* contains "host-b" and must be able to scale up to 294 usable addresses
- *"Hub"* contains "host-c" must be able to scale up to 78 usable addresses

|     Subnet     |        Address        |      Netmask    |    Hosts needed    | Hosts available |   Host Min  |   Host Max   |
|:---------------:|:---------------------:|:---------------:|:------------------:|:---------------:|:-----------:|:------------:|
| *Hosts-A*       |  15.0.0.0             |       /24       |         180        |      254        |  15.0.0.1   |  15.0.0.254  |
| *Hosts-B*       |  15.0.2.0             |       /23       |         294        |      510        |  15.0.2.1   |  15.0.3.254  |
| *Hub*           |  15.0.4.0             |       /25       |         78         |      126        |  15.0.4.1   |  15.0.4.126  |
| *Connection*    |  15.0.6.0             |       /30       |         2          |      2          |  15.0.6.1   |  15.0.6.2    |

In order to calculate the number of IPs available, we use this formula:
```
Number of available IPs for network = ((2^X)-2)
```

- **X** refers to the number of bits dedicated to the **host part**.
For our "*Hosts-a*" subnet we chose to assign (32-24=8) 8 bits for the hosts part, so that the number of IP available was closer to the one ask in the requirements
- "-2" is because in every network there are 2 unavailable IP, one for network and one for broadcast

## Set a VLAN

| Subnet | Interface | Vlan tag |     IP     |
|:------:|:---------:|:--------:|:----------:|
|    *Hosts-A*   | enp0s8.2  |    2    | 15.0.0.1 |
|    *Hosts-B*   | enp0s8.3  |    3    | 15.0.2.1 |

We decided to use vlans for the networks "*Hosts-A*" and "*Hosts-B*", so we can split the switch in two virtual switches. 

- SWITCH: split in two VLAN: "VLAN 2" and "VLAN 3"
- ROUTER-1: created a link between router-1 and VLANs in trunk mode

## Updated Network map with IP's and VLAN

```


        +----------------------------------------------------------+
        |                            15.0.6.1/30     15.0.6.2/30  |
        |                                 enp0s9       enp0s9      |enp0s3
        +--+--+                +------------+  ^          ^   +------------+
        |     |                |            |  |          |   |            |
        |     |          enp0s3|            |  |          |   |            |
        |     +----------------+  router-1  +-----------------+  router-2  |
        |     |                |            |                 |            |
        |     |                |            |                 |            |
        |  M  |                +------------+                 +------------+
        |  A  |         15.0.0.1/24  |  enp0s8.2                 |enp0s8 15.0.4.1/25
        |  N  |         15.0.2.1/23  |  enp0s8.3                 |
        |  A  |                      |                           |enp0s8 15.0.4.2/25
        |  G  |                      |                     +-----+----+
        |  E  |                      |  enp0s8             |          |
        |  M  |            +-------------------+           |          |
        |  E  |      enp0s3|                   |           |  host-c  |
        |  N  +------------+      SWITCH       |           |          |
        |  T  |            |  5             6  |           |          |
        |     |            +-------------------+           +----------+
        |  V  |        enp0s9 |             | enp0s10            |enp0s3
        |  A  |               |             |                    |
        |  G  |               |15.0.0.2/24  |15.0.2.2/23         |
        |  R  |               |enp0s8       |enp0s8              |
        |  A  |        +----------+     +----------+             |
        |  N  |        |          |     |          |             |
        |  T  |  enp0s3|          |     |          |             |
        |     +--------+  host-a  |     |  host-b  |             |
        |     |        |          |     |          |             |
        |     |        |          |     |          |             |
        ++-+--+        +----------+     +----------+             |
        | |                              |enp0s3                 |
        | |                              |                       |
        | +------------------------------+                       |
        |                                                        |
        |                                                        |
        +--------------------------------------------------------+



```

# Vagrantfile

This is an example extract from the Vagrantfile, that shows how Vagrant create a new VM, based on our settings.

We modified 2 things:
- at line 5 we change the path of the .sh file for every VM, linking the correct configuration file for every machine
- at line 7 we increase the memory just for Host-c, because it is "hosting" the docker and need a bit more "energy"

```
1   config.vm.define "host-c" do |hostc|
2       hostc.vm.box = "ubuntu/bionic64"
3       hostc.vm.hostname = "host-c"
4       hostc.vm.network "private_network", virtualbox__intnet: "broadcast_router-south-2", auto_config: false
5       hostc.vm.provision "shell", path: "hostc.sh"
6       hostc.vm.provider "virtualbox" do |vb|
7         vb.memory = 512
```



# Configuring the network

## ROUTER-1

```
export DEBIAN_FRONTEND=noninteractive
sudo su
apt-get update

1. Install tcpdump for debug and sniffing purposes

apt-get install -y tcpdump --assume-yes

2. Enable IP forwarding

sysctl net.ipv4.ip_forward=1

3. Add IP address to the interface linked to router-2 and set it "up"

ip add add 15.0.6.1/30 dev enp0s9
ip link set enp0s9 up

4. Create a subinterface for VLAN 2

ip link add link enp0s8 name enp0s8.2 type vlan id 2
ip add add 15.0.0.1/24 dev enp0s8.2

5. Create a subinterfaces for VLAN 3

ip link add link enp0s8 name enp0s8.3 type vlan id 3
ip add add 15.0.2.1/23 dev enp0s8.3

6. Set interfaces towards the switch up

ip link set enp0s8 up
ip link set enp0s8.2 up
ip link set enp0s8.3

7. Delete the default gateway

ip route del default

8. Create a static route to reach subnet "Hub" (where there is Host-c) via router-2

ip route add 15.0.4.0/25 via 15.0.6.2 dev enp0s9
```


## ROUTER-2

```
export DEBIAN_FRONTEND=noninteractive
sudo su
apt-get update

1. Install tcpdump for debug and sniffing purposes

apt-get install -y tcpdump --assume-yes

2. Enable IP forwarding

sysctl net.ipv4.ip_forward=1 

3. Add IP address to the interfaces and set them "up"

ip add add 15.0.4.1/25 dev enp0s8
ip add add 15.0.6.2/30 dev enp0s9
ip link set enp0s8 up
ip link set enp0s9 up

4. Delete the dafault gateway

ip route del default

5. Both lines are used to create static routes to reach subnet "Hosts-A" and "Hosts-B" via router-1

ip route add 15.0.0.0/24 via 15.0.6.1 dev enp0s9
ip route add 15.0.2.0/23 via 15.0.6.1 dev enp0s9
```


## SWITCH

```
export DEBIAN_FRONTEND=noninteractive

sudo su
apt-get update

1. Install tcpdump, openvswitch and curl

apt-get install -y tcpdump
apt-get install -y openvswitch-common openvswitch-switch apt-transport-https ca-certificates curl software-properties-common

2. Create a new bridge "br0"

ovs-vsctl add-br br0

3. Create a trunk port and set interface up

ovs-vsctl add-port br0 enp0s8
ip link set enp0s8 up

4. Add a port on the bridge with tag=2 (VLAN 2) and set the interface up

ovs-vsctl add-port br0 enp0s9 tag=2
ip link set enp0s9 up

5. Add a port on the bridge with tag=3 (VLAN 3) and set the interface up

ovs-vsctl add-port br0 enp0s10 tag=3
ip link set enp0s10 up
```


## HOST-A

```
export DEBIAN_FRONTEND=noninteractive
sudo su
apt-get update

1. Install tcpdump for debug and sniffing purposes

apt-get install -y tcpdump --assume-yes

2. Add IP address to the interface and set it "up"

ip add add 15.0.0.2/24 dev enp0s8
ip link set enp0s8 up

3. Delete the default gateway

ip route del default

4. Set the default gateway on router-1

ip route add default via 15.0.0.1
```


## HOST-B

```
export DEBIAN_FRONTEND=noninteractive
sudo su
apt-get update

1. Install tcpdump for debug and sniffing purposes

apt-get install -y tcpdump --assume-yes

2. Add IP address to the interface and set it "up"

ip add add 15.0.2.2/23 dev enp0s8
ip link set enp0s8 up

3. Delete the default gateway

ip route del default

4. Set the default gateway on router-1

ip route add default via 15.0.2.1
```


## HOST-C

```
export DEBIAN_FRONTEND=noninteractive

sudo su
apt-get update

1. Install docker and curl

apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce

2. First clean and then run docker image "dustnic82/nginx-test"

docker system prune -a
docker run --name DNCSWebserver -p 80:80 -d dustnic82/nginx-test

3. Add IP address to the interface and set it "up"

ip add add 15.0.4.2/25 dev enp0s8
ip link set enp0s8 up

4. Both lines are used to create static routes to reach subnet "Hosts-A" and "Hosts-B" via router-2

ip route add 15.0.0.0/24 via 15.0.4.1
ip route add 15.0.2.0/23 via 15.0.4.1
```


# How to test

1. Install [VirtualBox](https://www.virtualbox.org/) and [Vagrant](https://www.vagrantup.com/)
2. Clone this repository in your computer, using "Download ZIP" or using the "git clone" command
3. Open a terminal and navigate to the folder that you installed (using the command "cd") and then use the command ```vagrant up``` to start generating all the Virtual Machines. This process can take several minutes to install all VMs.
4. Once the terminal has ended all the process of installation, you can check if everything is working fine using the command ```vagrant status```. It should return these lines:

```
Current machine states:

router-1                  running (virtualbox)
router-2                  running (virtualbox)
switch                    running (virtualbox)
host-a                    running (virtualbox)
host-b                    running (virtualbox)
host-c                    running (virtualbox)
```

If your terminal displays something different just uninstall the setup with ```vagrant destroy``` and try the installation process again.

5. Once your environment is up and running you can log into every single VM just by typing ```vagrant ssh VMname``` , changing "VMname" with the name of the VM which you want to move into. For example if you want to navigate to router-1 you have to type:

```
vagrant ssh router-1
```

and this will display some information about the VM

```
$ vagrant ssh router-1
Welcome to Ubuntu 18.04.5 LTS (GNU/Linux 4.15.0-112-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Fri Aug 21 13:55:20 UTC 2020

  System load:  0.0               Processes:             84
  Usage of /:   12.0% of 9.63GB   Users logged in:       0
  Memory usage: 48%               IP address for enp0s3: 10.0.2.15
  Swap usage:   0%                IP address for enp0s9: 15.0.6.1


3 packages can be updated.
3 updates are security updates.


Last login: Thu Aug 20 11:16:28 2020 from 10.0.2.2

```

6. ```ifconfig``` 

For every VM we can use the command to display the list of all Ethernet interfaces on the host, with their own options. This is an example on host-a:

```
vagrant@host-a:~$ ifconfig
enp0s3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.2.15  netmask 255.255.255.0  broadcast 10.0.2.255
        inet6 fe80::95:95ff:fe10:caf7  prefixlen 64  scopeid 0x20<link>
        ether 02:95:95:10:ca:f7  txqueuelen 1000  (Ethernet)
        RX packets 28144  bytes 21423990 (21.4 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 13180  bytes 909597 (909.5 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

enp0s8: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 15.0.0.2  netmask 255.255.255.0  broadcast 0.0.0.0
        inet6 fe80::a00:27ff:fe80:99a1  prefixlen 64  scopeid 0x20<link>
        ether 08:00:27:80:99:a1  txqueuelen 1000  (Ethernet)
        RX packets 50  bytes 13836 (13.8 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 72  bytes 5922 (5.9 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 42  bytes 4024 (4.0 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 42  bytes 4024 (4.0 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0


```

Here we have "enp0s3" that links our VM to the Ethernet card of our PC; enp0s8 is the interface that links the host-a with the switch and "lo" is an imaginary interface, that is the local-host 

7. ```route -nve``` 

This command shows on the terminal the routing table of the VM. This is an example of the command on host-a:

```
vagrant@host-a:~$ route -nve
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         15.0.0.1        0.0.0.0         UG        0 0          0 enp0s8
10.0.2.0        0.0.0.0         255.255.255.0   U         0 0          0 enp0s3
10.0.2.2        0.0.0.0         255.255.255.255 UH        0 0          0 enp0s3
15.0.0.0        0.0.0.0         255.255.255.0   U         0 0          0 enp0s8
```


8. ```ping "IPaddress"```

In this command you have to change "IPaddress" with the actual IP address of the interface you want to reach. For example if you want to ping host-c from host-a you have to type in terminal ```ping 15.0.4.2``` and this is the output:

```
vagrant@host-a:~$ ping 15.0.4.2
PING 15.0.4.2 (15.0.4.2) 56(84) bytes of data.
64 bytes from 15.0.4.2: icmp_seq=1 ttl=62 time=12.1 ms
64 bytes from 15.0.4.2: icmp_seq=2 ttl=62 time=2.47 ms
64 bytes from 15.0.4.2: icmp_seq=3 ttl=62 time=2.10 ms
64 bytes from 15.0.4.2: icmp_seq=4 ttl=62 time=2.02 ms
64 bytes from 15.0.4.2: icmp_seq=5 ttl=62 time=2.39 ms
64 bytes from 15.0.4.2: icmp_seq=6 ttl=62 time=2.04 ms
64 bytes from 15.0.4.2: icmp_seq=7 ttl=62 time=2.22 ms
64 bytes from 15.0.4.2: icmp_seq=8 ttl=62 time=1.97 ms
64 bytes from 15.0.4.2: icmp_seq=9 ttl=62 time=2.35 ms
64 bytes from 15.0.4.2: icmp_seq=10 ttl=62 time=2.26 ms
64 bytes from 15.0.4.2: icmp_seq=11 ttl=62 time=1.92 ms
64 bytes from 15.0.4.2: icmp_seq=12 ttl=62 time=2.05 ms
64 bytes from 15.0.4.2: icmp_seq=13 ttl=62 time=2.20 ms
64 bytes from 15.0.4.2: icmp_seq=14 ttl=62 time=2.12 ms
^Z
[1]+  Stopped                 ping 15.0.4.2

```

9. ```tcpdump -i "InterfaceName"```

In this command you have to change "InterfaceName" with the name of the interface where you want to sniff packets that are passing through it. In this example we ping host-c from host-a meanwhile switch, router-1 is sniffing packets on enp0s8:

![Tcpdump image](https://github.com/Pavel2121/dncs-lab/blob/master/Screenshot%20test/test.PNG)

10. ```curl 15.0.4.2```

From host-a or host-b you can retrieve data of a web-page (dustnic82/nginx-test) hosted in host-2-c that will be browsed on terminal. This is an example of the command on host-a:

```
vagrant@host-a:~$ curl 15.0.4.2
<!DOCTYPE html>
<html>
<head>
<title>Hello World</title>
<link href="data:image/png;base64,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" rel="icon" type="image/png" />
<style>
body {
  margin: 0px;
  font: 20px 'RobotoRegular', Arial, sans-serif;
  font-weight: 100;
  height: 100%;
  color: #0f1419;
}
div.info {
  display: table;
  background: #e8eaec;
  padding: 20px 20px 20px 20px;
  border: 1px dashed black;
  border-radius: 10px;
  margin: 0px auto auto auto;
}
div.info p {
    display: table-row;
    margin: 5px auto auto auto;
}
div.info p span {
    display: table-cell;
    padding: 10px;
}
img {
    width: 176px;
    margin: 36px auto 36px auto;
    display:block;
}
div.smaller p span {
    color: #3D5266;
}
h1, h2 {
  font-weight: 100;
}
div.check {
    padding: 0px 0px 0px 0px;
    display: table;
    margin: 36px auto auto auto;
    font: 12px 'RobotoRegular', Arial, sans-serif;
}
#footer {
    position: fixed;
    bottom: 36px;
    width: 100%;
}
#center {
    width: 400px;
    margin: 0 auto;
    font: 12px Courier;
}

</style>
<script>
var ref;
function checkRefresh(){
    if (document.cookie == "refresh=1") {
        document.getElementById("check").checked = true;
        ref = setTimeout(function(){location.reload();}, 1000);
    } else {
    }
}
function changeCookie() {
    if (document.getElementById("check").checked) {
        document.cookie = "refresh=1";
        ref = setTimeout(function(){location.reload();}, 1000);
    } else {
        document.cookie = "refresh=0";
        clearTimeout(ref);
    }
}
</script>
</head>
<body onload="checkRefresh();">
<img alt="NGINX Logo" src="http://d37h62yn5lrxxl.cloudfront.net/assets/nginx.png"/>
<div class="info">
<p><span>Server&nbsp;address:</span> <span>172.17.0.2:80</span></p>
<p><span>Server&nbsp;name:</span> <span>9e520c9139a4</span></p>
<p class="smaller"><span>Date:</span> <span>20/Aug/2020:11:18:28 +0000</span></p>
<p class="smaller"><span>URI:</span> <span>/</span></p>
</div>
<br>
<div class="info">
    <p class="smaller"><span>Host:</span> <span>15.0.4.2</span></p>
    <p class="smaller"><span>X-Forwarded-For:</span> <span></span></p>
</div>

<div class="check"><input type="checkbox" id="check" onchange="changeCookie()"> Auto Refresh</div>
    <div id="footer">
        <div id="center" align="center">
            Request ID: eb3e5e74a280b084eae62fa184093c41<br/>
            &copy; NGINX, Inc. 2018
        </div>
    </div>
</body>
</html>


```

# Repository information

We started the project by forking this repository: [https://github.com/dustnic/dncs-lab](https://github.com/dustnic/dncs-lab).