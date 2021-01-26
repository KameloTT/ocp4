#!/bin/bash
hostssh=`cat creds |grep ^hostssh |awk -F"'" '{print $2}'`
#domainname=`cat creds |grep ^domainname |awk -F"'" '{print $2}'`
#clustername=`cat creds |grep ^clustername |awk -F"'" '{print $2}'`
#api=

echo $hostssh
scp -r configs argocd.sh github-argocd-ssh-key ${hostssh}:~/
ssh -t ${hostssh} './argocd.sh'
