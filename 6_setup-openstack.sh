#!/bin/bash
hostssh=`cat creds |grep ^hostssh |awk -F"'" '{print $2}'`

scp -r configs argocd-openstack.sh github-ocp4build-ssh-key ${hostssh}:~/
ssh -t ${hostssh} './argocd-openstack.sh'
