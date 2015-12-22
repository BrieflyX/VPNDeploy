#!/bin/bash
# Deploy script for double-linked vpn node.

if [ `id -u` -ne 0 ]; then
    echo "The script should be run on root."
    exit 1
fi

PATH="$PATH:/bin:/sbin"

# Prepare openvpn
echo "Installing openvpn ..."
apt-get -y install openvpn &> /dev/null || yum -y install openvpn &> /dev/null

# Prepare config file
echo "Test the key file ..."
if [ ! -e "config" ]; then
    echo "config file cannot be run."
    exit 1
else
    source config
fi

echo "Copying config file ..."
sed -e "s/\[s_port\]/$s_port/" -e "s/\[s_ca\]/$s_ca/" -e "s/\[s_cert\]/$s_cert/" -e "s/\[s_key\]/$s_key/" -e "s/\[s_dh\]/$s_dh/" -e "s/\[s_ippool\]/$s_ippool/" -e "s/\[s_netmask\]/$s_netmask/" server.conf > /etc/openvpn/server.conf
sed -e "s/\[server\]/$server/" -e "s/\[port\]/$port/" -e "s/\[localaddr\]/$localaddr/" -e "s/\[remoteaddr\]/$remoteaddr/" -e "s/\[secert\]/$secert/" client.conf > /etc/openvpn/client.conf

echo "Copying key file ..."
cp $s_ca $s_cert $s_key $s_dh $secert /etc/openvpn

echo "Copying scripts ..."
cp vpn-up.sh vpn-down.sh chnroute-update.sh /etc/openvpn

# Restart service & config iptables rules

echo "Config for system ..."
service openvpn restart
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
iptables -A FORWARD -i $s_subnet -j ACCPET
iptables -A FORWARD -o $s_subnet -j ACCPET
iptables -t nat -A POSTROUING -i $s_subnet ! -o $s_subnet -j MASQUERADE

iptables-save > /etc/iptables.ipv4.rules
echo "up iptables-restore < /etc/iptables.ipv4.rules" >> /etc/network/interfaces

# add crontab for updating route
crontab crontab.txt

echo "Done!"