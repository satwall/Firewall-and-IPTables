#!/bin/bash


###################################################
#############User Configurable Section#############
###################################################

#interfaces
internalinterface="enp0s3"
externalinterface="enp0s8"


#ipaddress
externalip="192.168.1.84"
internalip="192.168.10.1"
internalserverip="192.168.10.2"
internalnet="192.168.10.0/24"

#ports allowed
allowedports="80,22,21,20" #TCPPorts
highports="1000:65535"
allowedudpports="53,5060"

#ICMP types
firsttypeallowed="8"
secondtypeallowed="0"

##################################################
##########Implementation of iptablesables rules########
##################################################


#network configuration
ifconfig $internalinterface $internalip up
sudo echo "1" >/proc/sys/net/ipv4/ip_forward


# Default Policies
iptables -F
iptables -X
iptables -t nat -F
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

#Forward packets

#Option1 Forwarding All Traffic
#iptables -A FORWARD -i $internalinterface -o $externalinterface -j ACCEPT
#iptables -A FORWARD -o $internalinterface -i $externalinterface -j ACCEPT

# POSTROUTING Outbounding Traffic
iptables -A POSTROUTING -t nat -o $externalinterface -j MASQUERADE

#iptables -A PREROUTING -t nat -i $externalinterface -j DNAT --to-destination $internalserverip

#option2 Forwarding desinged Traffic
#iptables -A PREROUTING -t nat -i $externalinterface -p tcp -d $externalip --dport 80 -j DNAT --to-destination $internalserverip

#iptables -A FORWARD -i $externalinterface -o $internalinterface -p tcp -d $internalserverip --dport 80 -m state --state NEW -j ACCEPT 

#Prerouting and forwaring TCP Traffic
iptables -A PREROUTING -t nat -i $externalinterface -p tcp --sport $highports -d $externalip -m multiport --dports $allowedports -j DNAT --to-destination $internalserverip

iptables -A FORWARD -i $externalinterface -o $internalinterface -p tcp --sport $highports -d $internalserverip -m multiport --dports $allowedports -m state --state NEW,ESTABLISHED -j ACCEPT

iptables -A FORWARD -i $internalinterface -o $externalinterface -p tcp -s $internalserverip -m multiport --sports $allowedports -d 0/0 -m multiport --dports $highports -m state --state ESTABLISHED,RELATED -j ACCEPT


#Preroutning and forwarding UDP Traffic
iptables -A PREROUTING -t nat -i $externalinterface -p udp --sport $highports -d $externalip -m multiport --dports $allowedudpports -j DNAT --to-destination $internalserverip

iptables -A FORWARD -i $externalinterface -o $internalinterface -p udp --sport $highports -d $internalserverip -m multiport --dports $allowedudpports -m state --state NEW,ESTABLISHED -j ACCEPT

iptables -A FORWARD -i $internalinterface -o $externalinterface -p udp -s $internalserverip -m multiport --sports $allowedudpports -d 0/0 -m multiport --dports $highports -m state --state ESTABLISHED,RELATED -j ACCEPT

# Forwarding ICMP Traffic

iptables -A PREROUTING -t nat -i $externalinterface -p icmp --icmp-type any -d $externalip -j DNAT --to-destination $internalserverip

iptables -A FORWARD -i $externalinterface -o $internalinterface -p icmp --icmp-type $firsttypeallowed -d $internalserverip -j ACCEPT

iptables -A FORWARD -i $externalinterface -o $internalinterface -p icmp --icmp-type $secondtypeallowed -d $internalserverip -j ACCEPT

iptables -A FORWARD -i $internalinterface -o $externalinterface -p icmp --icmp-type $firsttypeallowed -s $internalserverip -j ACCEPT

iptables -A FORWARD -i $internalinterface -o $externalinterface -p icmp --icmp-type $secondtypeallowed -s $internalserverip -j ACCEPT

#Allow TCP connections initiated from internal client
iptables -A FORWARD -i $internalinterface -o $externalinterface -p tcp -s $internalserverip --sport $highports -d 0/0 -m multiport --dports $allowedports -m state --state NEW,ESTABLISHED -j ACCEPT

iptables -A FORWARD -i $externalinterface -o $internalinterface -p tcp -m multiport --sports $allowedports -d $internalserverip -m multiport --dports $highports -m state --state ESTABLISHED,RELATED -j ACCEPT

#Allow UDP connections initiated from internal client
iptables -A FORWARD -i $internalinterface -o $externalinterface -p udp -s $internalserverip --sport $highports -d 0/0 -m multiport --dports $allowedudpports -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $externalinterface -o $internalinterface -p udp -m multiport --sports $allowedudpports -d $internalserverip -m multiport --dports $highports -m state --state ESTABLISHED,RELATED -j ACCEPT

#Drop spoofed packets (internal addresses as source coming from outside)
iptables -A FORWARD -i $externalinterface -o $internalinterface -s $internalnet -j DROP

#Minimum Delay for FTP and SSH, Maximum Throughput for FTP Data
iptables -t mangle -A PREROUTING -m multiport -p tcp --sports 21,22 -j TOS --set-tos Minimize-Delay
iptables -t mangle -A PREROUTING -p tcp --sport 20 -j TOS --set-tos Maximize-Throughput
iptables -t mangle -A PREROUTING -m multiport -p tcp --dports 21,22 -j TOS --set-tos Minimize-Delay
iptables -t mangle -A PREROUTING -p tcp --sport 20 -j TOS --set-tos Maximize-Throughput