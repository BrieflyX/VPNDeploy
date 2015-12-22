#!/bin/bash

route_add=/etc/openvpn/vpn-up.sh
route_del=/etc/openvpn/vpn-down.sh

wget http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest -O /tmp/apnic.txt
grep apnic /tmp/apnic.txt |grep ipv4 |grep CN  |awk -F'|' '{print $4,$5}' >/tmp/chn-ip.txt


echo "#!/bin/bash" >$route_del
echo "export PATH=/bin:/sbin:/usr/sbin:/usr/bin" >>$route_del


cat >$route_add <<E_O_D
#!/bin/bash
export PATH=/bin:/sbin:/usr/sbin:/usr/bin
OLDGW=\`netstat -ar |grep default | grep -v tun | awk '{print \$2}'\`
if [ "\$OLDGW" == '' ]; then
    exit 0
fi

if [ ! -e /tmp/openvpn_oldgw ]; then
    echo \$OLDGW > /tmp/openvpn_oldgw
fi
E_O_D

while read startip num
do
    a=0xffffffff
    let "b=$num-1"
    let "c=$a^$b"
    netmask="null"
    for i in  1 2 3 
    do
        let "x=($c >> (32-$i*8)) &0xff "
        if [ $netmask == "null" ] 
        then
            netmask=$x
        else
            netmask=$netmask"."$x
        fi
    done 

    netmask=$netmask".0"
    echo "route add -net $startip netmask $netmask gw \$OLDGW" >>$route_add
    echo "route del -net $startip netmask $netmask" >>$route_del
done  < /tmp/chn-ip.txt

rm  /tmp/chn-ip.txt

echo "rm /tmp/openvpn_oldgw" >>$route_del

chmod +x $route_add
chmod +x $route_del

rm /tmp/apnic.txt
