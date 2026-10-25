#!/bin/sh
echo $@ > /root/preptmp
partner=`echo $@ | awk '{print $1}'`
partnerip=`echo $@ | awk '{print $2}'`
cd /TopStordata/
mkdir ${partner} 2>/dev/null
cd ${partner} 
# keep the key pair when it is there: the receiver may already hold it (the key is delivered asynchronously)
if [ ! -s ${partnerip} ] || [ ! -s ${partnerip}.pub ] || ! ssh-keygen -y -f ${partnerip} >/dev/null 2>&1; then
 rm -rf ${partnerip} 2>/dev/null
 rm -rf ${partnerip}.pub 2>/dev/null
 ssh-keygen -f $partnerip -N "" 1>/dev/null
fi
cat ${partnerip}.pub

