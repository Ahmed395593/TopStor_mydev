#!/bin/sh
export ETCDCTL_API=3
ipaddr=`echo $@ | awk '{print $1}'`
ipsubnet=`echo $@ | awk '{print $2}'`
/TopStor/netaddr.sh add ${ipaddr}/$ipsubnet
echo '# init' > /etc/exports
cat /TopStordata/exportip.* > /etc/exports
exportfs -r
