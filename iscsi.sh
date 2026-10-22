#!/bin/sh
cd /TopStor
export ETCDCTL_API=3
echo $@ > /root/iscsiparam

resname=`echo $@ | awk '{print $1}'`
#mounts=`echo $@ | awk '{print $2}' | sed 's/\-v/ \-v /g'`
vol=`echo $@ | awk '{print $2}' | awk -F'/' '{print $2}' `
pool=`echo $@ | awk '{print $2}' | awk -F'/' '{print $1}' `
ipaddr=`echo $@ | awk '{print $3}'`
ipsubnet=`echo $@ | awk '{print $4}'`
vtype=`echo $@ | awk '{print $5}'`
#docker rm -f $resname
# Only touch NetworkManager when the address is really missing.  VolumeCheck re-runs this script every 10 s while a LUN is
# not in the target table, and the unconditional remove/add + 'conn up' re-applied bond0 each time (link down/up every few
# seconds, node unreachable, iSCSI logins failing).
if ip -4 -o addr show | grep -qw "${ipaddr}/${ipsubnet}" && nmcli -g ipv4.addresses conn show cmynode 2>/dev/null | tr ', |' '\n' | grep -qw "${ipaddr}/${ipsubnet}"; then
 echo "address ${ipaddr}/${ipsubnet} already present, network left untouched"
else
 /TopStor/netaddr.sh add ${ipaddr}/$ipsubnet
fi
# Announce the address (gratuitous ARP, as docker_primary.sh does for the cluster IP).  After a take over the clients still
# have another MAC cached for it (the old owner, or whatever answered while nobody owned it) and could not connect until
# that entry expired: the proxy could not log in to the LUN served by the new node.
for garpdev in `ip -o -4 route show to match $ipaddr 2>/dev/null | grep -v '^default' | sed -n 's/.* dev \([^ ]*\).*/\1/p' | sort -u`
do
 arping -U -c 2 -I $garpdev -s $ipaddr $ipaddr >/dev/null 2>&1
done
enpdev='enp0s8'
portalport=`echo $@ | awk '{print $6}'`
targetiqn=`echo $@ | awk '{print $7}'`
chapuser=`echo $@ | awk '{print $8}'`
chappas=`echo $@ | awk '{print $9}'`
myhost=`docker exec etcdclient /TopStor/etcdgetlocal.py clusternode`
	myhostip=`docker exec etcdclient /TopStor/etcdgetlocal.py clusternodeip`
	leader=`docker exec etcdclient /TopStor/etcdgetlocal.py leader`
	echo $leader | grep $myhost
	if [ $? -ne 0 ];
	then
 		etcd=$myhostip
	else
 		etcd=$leaderip
 	fi

echo /pace/addzfsvolumeastarget.sh $pool ${vol} $ipaddr $portalport $targetiqn $chapuser $chappas
 for i in $(echo $targetiqn | sed "s/,/ /g")
 do
#pdhcp2524812990 pool1is_250024055 10.11.11.11 3263 iqn.1991-05.com.microsoft:desktop-jckvhk3 MoatazNegm MezoAdmin
  /pace/addzfsvolumeastarget.sh $pool $vol $ipaddr $portalport $i $chapuser $chappas 

    # call your procedure/other scripts here below
 done
#/pace/addzfsvolumeastarget.sh $pool ${vol} $ipaddr $portalport $targetiqn $chapuser $chappas
