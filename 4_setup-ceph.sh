#!/bin/bash
hostssh=`cat creds |grep ^hostssh |awk -F"'" '{print $2}'`

scp -r configs ceph.sh  ${hostssh}:~/
ssh -t ${hostssh} './ceph.sh'
