#!/bin/bash

echo "Install Ceph via operator"
ceph_inst_type=m4.2xlarge
if [ -d /home/avishnia-redhat.com/ocp4cluster1/auth ];then
  export KUBECONFIG=/home/avishnia-redhat.com/ocp4cluster1/auth/kubeconfig
fi

version=`oc get clusterversion/version -o jsonpath='{.spec.channel}' |awk -F '-' {'print $2'}`
sed -i "s|___version___|$version|" configs/6_ceph_subscription.yaml
sed -i "s|___version___|$version|" configs/6_ceph_crd_storagecluster.yaml

echo "Create  Ceph  nodes"
oc get machinesets -n openshift-machine-api -o name |grep '\-infra\-' |while read line
do 
  echo "Create Ceph Machineset from $line"
  oc get $line -n openshift-machine-api -o yaml |sed '/uid:/d;/resourceVersion:/d;/selfLink/d;/creationTimestamp/d;/status:/,+5 d' |sed 's/infra-us-/ceph-us-/g;s/machine-role: infra/machine-role: ceph/;s/machine-type: infra/machine-type: ceph/' |sed 's|          node-role.kubernetes.io/infra: ""|          node-role.kubernetes.io/ceph: ""\n          cluster.ocs.openshift.io/openshift-storage: ""\n          node.ocs.openshift.io/storage: ""|' |sed "s/ instanceType:.*.$/ instanceType: ${ceph_inst_type}/" |oc create -f - 
done

echo "Apply Ceph Machine autoscaler"
oc get machinesets -n openshift-machine-api -o name  |grep '\-ceph\-' |awk -F'/' {'print $2'} |while read line;do cat configs/5_machine-autoscaler.yaml |sed "s/node-machineset/$line/" | oc create -f - ;done

while [ `oc get no -l cluster.ocs.openshift.io/openshift-storage= 2>/dev/null |grep " Ready " |wc -l` -le 2 ]
do 
  sleep 1
done

echo "Remove worker role from infra node"
oc label no node-role.kubernetes.io/worker- -l node-role.kubernetes.io/ceph=

oc create namespace openshift-storage

oc create -f configs/6_ceph_group.yaml
oc create -f configs/6_ceph_subscription.yaml

while [ `oc get crd -o name | grep cephblockpools.ceph.rook.io`1 != 'customresourcedefinition.apiextensions.k8s.io/cephblockpools.ceph.rook.io1' ]
do 
  sleep 5
done
sleep 5

oc create -f configs/6_ceph_crd_storagecluster.yaml
oc create -f configs/6_ceph_crd_cephcluster.yaml	
oc create -f configs/6_ceph_crd_cephfilesystem.yaml

