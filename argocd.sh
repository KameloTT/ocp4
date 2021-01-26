#!/bin/bash

echo "Install ArgoCD"
if [ -d /home/avishnia-redhat.com/ocp4cluster1/auth ];then
  export KUBECONFIG=/home/avishnia-redhat.com/ocp4cluster1/auth/kubeconfig
fi

oc create namespace argocd-cluster
oc project argocd-cluster

oc create -f configs/11_argocd_group.yaml
oc create -f configs/11_argocd_subscription.yaml

while [ `oc get crd -o name |grep argocds.argoproj.io`1 != 'customresourcedefinition.apiextensions.k8s.io/argocds.argoproj.io1' ]
do 
  sleep 5
done

#oc create -f configs/11_argocd_crd.yaml
oc create -f configs/11_argocd_crd_oauth.yaml

while [ `oc get secret -o name -n argocd-cluster |grep "argocd-secret$"`1 != 'secret/argocd-secret1' ]
do
  sleep 5
done

echo '---Install ArgoCD tool---'
rm -rf openshift-client-linux-
sudo curl -L https://github.com/argoproj/argo-cd/releases/download/v1.7.8/argocd-linux-amd64 -o /usr/bin/argocd
sudo chmod +x /usr/bin/argocd

oc adm policy add-cluster-role-to-user cluster-admin -z argocd-application-controller -n argocd-cluster
oc adm policy add-cluster-role-to-user cluster-admin -z argocd-dex-server -n argocd-cluster
oc adm policy add-cluster-role-to-user cluster-admin -z argocd-server -n argocd-cluster

ARGOCD_PASSWORD=$(oc -n argocd-cluster get secret argocd-cluster -o jsonpath='{.data.admin\.password}' | base64 -d)
ARGOCD_SERVER=$(oc -n argocd-cluster get route argocd-server -o jsonpath='{.spec.host}'):443
echo 'y' | argocd --insecure --grpc-web login ${ARGOCD_SERVER} --username admin --password ${ARGOCD_PASSWORD}
