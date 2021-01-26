#!/bin/bash
hostssh=`cat creds |grep ^hostssh |awk -F"'" '{print $2}'`
passwordssh=`cat creds |grep ^passwordssh |awk -F"'" '{print $2}'`

rm -rf cluster-vish-key*
ssh-keygen -f cluster-vish-key -N ''
sshpass -p $passwordssh ssh-copy-id  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no $hostssh

scp -r configs day2ops.sh ${hostssh}:~/
ssh -t ${hostssh} './day2ops.sh'
