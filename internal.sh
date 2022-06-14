#!/bin/bash


dns=8.8.8.8
gwaddr=192.168.10.1

sudo ifconfig enp0s3 down
sudo ifconfig enp0s8 192.168.10.2 netmask 255.255.255.0 broadcast 192.168.10.255
sudo route add default gw $gwaddr

echo "nameserver $dns" > /etc/resolv.conf

iptables -F
iptables -X