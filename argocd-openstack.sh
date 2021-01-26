#!/bin/bash

echo "Setup ArgoCD"
if [ -d /home/avishnia-redhat.com/ocp4cluster1/auth ];then
  export KUBECONFIG=/home/avishnia-redhat.com/ocp4cluster1/auth/kubeconfig
fi

ARGOCD_PASSWORD=$(oc -n argocd-cluster get secret argocd-cluster -o jsonpath='{.data.admin\.password}' | base64 -d)
ARGOCD_SERVER=$(oc -n argocd-cluster get route argocd-server -o jsonpath='{.spec.host}'):443
argocd --insecure --grpc-web login ${ARGOCD_SERVER} --username admin --password ${ARGOCD_PASSWORD}

echo "Add ooo-common Github repo"
argocd repo add git@github.com:KameloTT/ooo-common.git --ssh-private-key-path github-argocd-ssh-key

echo "Add Base application"
argocd app create -f configs/12_argocd_base-openstack.yaml

echo "Add Builds application"
argocd app create -f configs/12_argocd_builds-openstack.yaml 

echo "Add Mysql application"
argocd app create -f configs/12_argocd_mysql-openstack.yaml 

echo "Add Rabbitmq application"
argocd app create -f configs/12_argocd_rabbitmq-openstack.yaml

echo "Add Keystone application"
argocd app create -f configs/12_argocd_keystone-openstack.yaml

echo "Add Horizon application"
argocd app create -f configs/12_argocd_horizon-openstack.yaml

echo "Add Glance application"
argocd app create -f configs/12_argocd_glance-openstack.yaml
