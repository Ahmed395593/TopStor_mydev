#!/usr/bin/python3
# Run when a node joins / returns (docker_setup.sh).  Brings the node's local ActPool/<pool> records in line with the leader:
#  - a pool the leader does not know is reported to the leader ONLY if the pool really is on this node (imported or importable);
#    a record of a pool that was deleted while this node was down is stale and is removed here (it used to be pushed back to the
#    leader, i.e. a deleted pool came back to life)
#  - a record whose pool id differs from the leader's is removed (the leader's one wins)
import subprocess
from etcdput import etcdput as put
from etcdgetpy import etcdget as get
from etcddel import etcddel as dels

def run(cmdline):
    return subprocess.run(cmdline.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout.decode('utf-8')

leaderip = run('docker exec etcdclient /TopStor/etcdgetlocal.py leaderip').replace('\n', '').replace(' ', '')
myhostip = run('docker exec etcdclient /TopStor/etcdgetlocal.py mynodeip').replace('\n', '').replace(' ', '')

def records(ip):
    res = get(ip, 'ActPool', '--prefix')
    return [r for r in res if isinstance(r, tuple) and len(r) == 2 and '/' in r[0]]

localpools = set(run('/sbin/zpool list -H -o name').split())
for line in run('/sbin/zpool import').split('\n'):
    if line.strip().startswith('pool:'):
        localpools.add(line.split(':', 1)[1].strip())
leaderrecs = dict((r[0].split('/', 1)[1], r[1]) for r in records(leaderip))
for key, value in records(myhostip):
    pool = key.split('/', 1)[1]
    if pool not in leaderrecs:
        if pool in localpools:
            put(leaderip, key, value)
        else:
            dels(myhostip, key)
    elif leaderrecs[pool] != value:
        dels(myhostip, key)
