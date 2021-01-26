#!/bin/bash
hostssh=`cat creds |grep ^hostssh |awk -F"'" '{print $2}'`
echo $hostssh
scp -r configs acm.sh ${hostssh}:~/
ssh -t ${hostssh} './acm.sh'
