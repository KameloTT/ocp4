#!/bin/bash

echo "Install Advance Cluster Managment"

if [ -d /home/avishnia-redhat.com/ocp4cluster1/auth ];then
  export KUBECONFIG=/home/avishnia-redhat.com/ocp4cluster1/auth/kubeconfig
fi

oc create namespace openshift-acm
oc project openshift-acm
oc extract secret/pull-secret -n openshift-config  --to=./
oc create secret generic pullsecret -n openshift-acm --from-file=.dockerconfigjson --type=kubernetes.io/dockerconfigjson
rm -rf ./.dockerconfigjson

oc create -f configs/11_acm_group.yaml
oc create -f configs/11_acm_subscription.yaml

while [ `oc get crd -o name | grep multiclusterhubs.operator.open-cluster-management.io`1 != 'customresourcedefinition.apiextensions.k8s.io/multiclusterhubs.operator.open-cluster-management.io1' ]
do 
  sleep 5
done

oc create -f configs/11_acm_crd.yaml

#while [ `oc get deploy -o name |grep console-header` != 'deployment.apps/console-header' ]; do sleep 5;done

#oc patch deploy console-header -n openshift-acm -p '{"spec":{"template":{"spec":{"containers":[{"name":"console-header","env": [{"name": "featureFlags_baremetal","value":"true"}]}]}}}}'

#while [ `oc get deploy  -o name |grep consoleui` != 'deployment.apps/console-chart-acfed-consoleui' ]; do sleep 5;done

#oc patch -n openshift-acm  $(oc get deploy -o name | grep consoleui) -p '{"spec":{"template":{"spec":{"containers":[{"name":"hcm-ui","env": [{"name": "featureFlags_baremetal","value":"true"}]}]}}}}'
