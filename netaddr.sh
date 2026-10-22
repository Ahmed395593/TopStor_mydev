#!/bin/bash
# netaddr.sh add|del <ip>/<prefix>   |   netaddr.sh reapply
# Add or remove a service address (volume IP) of this node WITHOUT 'nmcli conn up cmynode'.
# 'conn up' re-applies the whole bond: the link goes down and up (carrier_changes +2) and every client of the node, the cluster IP
# included, is cut for 20-40 s -- at every volume create (seen in the Performance test, 15 failed requests in a row).
# The address is added/removed live with 'ip addr' and written to the saved connection profile with 'nmcli conn mod', which
# does not touch the link.  'reapply' applies a profile change (for example the DNS servers) to the running device in place.
op=$1; addr=$2
dev=`nmcli -g GENERAL.DEVICES connection show cmynode 2>/dev/null | head -1`
[ -z "$dev" ] && dev=bond0
case $op in
 add)
  nmcli -g ipv4.addresses conn show cmynode | tr ', ' '\n' | grep -qxF "$addr" || nmcli conn mod cmynode +ipv4.addresses $addr
  ip -4 -o addr show dev $dev | awk '{print $4}' | grep -qxF "$addr" || ip addr add $addr dev $dev noprefixroute
  arping -U -c 2 -I $dev -s ${addr%/*} ${addr%/*} >/dev/null 2>&1
  ;;
 del)
  nmcli conn mod cmynode -ipv4.addresses $addr
  ip -4 -o addr show dev $dev | awk '{print $4}' | grep -qxF "$addr" && ip addr del $addr dev $dev
  ;;
 reapply)
  nmcli device reapply $dev
  ;;
 *) echo "usage: $0 add|del <ip>/<prefix> | reapply"; exit 1;;
esac
exit 0
