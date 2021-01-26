#!/bin/bash
infra_inst_type='m4.2xlarge'
  
if [ -d /home/avishnia-redhat.com/ocp4cluster1/auth ];then
  export KUBECONFIG=/home/avishnia-redhat.com/ocp4cluster1/auth/kubeconfig
fi
oc get no
version=`oc get clusterversion/version -o jsonpath='{.spec.channel}' |awk -F '-' {'print $2'}`
sed -i "s|___version___|$version|" configs/4_logging-subscription-es.yaml
sed -i "s|___version___|$version|" configs/4_logging-subscription-cluster.yaml

if [ $? -ne 0 ];then
  echo 'Bad auth'
  exit
fi

echo "Create  infra nodes"
oc get machinesets -n openshift-machine-api -o name |while read line
do 
  echo "Create Machineset from $line"
  oc get $line -n openshift-machine-api -o yaml |sed '/uid:/d;/resourceVersion:/d;/selfLink/d;/status:/,+5 d' |sed 's/worker-us-/infra-us-/g;s/machine-role: worker/machine-role: infra/;s/machine-type: worker/machine-type: infra/' |sed 's|^      metadata:.*|      metadata:\n        labels:\n          node-role.kubernetes.io/infra: ""|' |sed "s/ instanceType:.*.$/ instanceType: ${infra_inst_type}/" |oc create -f - 
done

echo "Apply delete policy to Machinesets"
oc get machinesets -n openshift-machine-api -o name | while read line;do oc patch $line -n openshift-machine-api --type=merge -p '{"spec":{"deletePolicy":"Newest"}}';done

echo "Create MachineConfig Infra Pool"
oc create -f ./configs/1_infra-mcp.yaml

while [ `oc get machinesets -n openshift-machine-api -o jsonpath='{range .items[*].status}{.readyReplicas}'` != '111111' ]
do
  sleep 5
done

echo "Remove worker role from infra node"
oc label no node-role.kubernetes.io/worker- -l node-role.kubernetes.io/infra=

#TO DO. Implement Taints for infra

echo "Apply taints to infra nodes"
oc adm taint nodes -l node-role.kubernetes.io/infra  infra=reserved:NoSchedule infra=reserved:NoExecute

echo "Reassign Router to infra nodes"
oc patch ingresscontroller/default -n  openshift-ingress-operator  --type=merge -p '{"spec":{"nodePlacement": {"nodeSelector": {"matchLabels": {"node-role.kubernetes.io/infra": ""}},"tolerations": [{"effect":"NoSchedule","key": "infra","value": "reserved"},{"effect":"NoExecute","key": "infra","value": "reserved"}]}}}'
oc patch ingresscontroller/default -n openshift-ingress-operator --type=merge -p '{"spec":{"replicas": 3}}'

echo "Reassign Registy to infra nodes"
oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge -p '{"spec":{"nodeSelector": {"node-role.kubernetes.io/infra": ""},"tolerations": [{"effect":"NoSchedule","key": "infra","value": "reserved"},{"effect":"NoExecute","key": "infra","value": "reserved"}]}}'
oc patch configs.imageregistry.operator.openshift.io/cluster  --type=merge -p '{"spec":{"replicas": 3}}'

echo "Reassign Monitoring to infra nodes"
oc create -f configs/2_cluster-monitoring-config.yaml

#temp solution because thanos desnt supports by operator changing and fall back to basic tolerations
oc patch deploy/thanos-querier --type=merge -p '{"spec":{"template":{"spec":{"nodeSelector":{"node-role.kubernetes.io/infra":""},"tolerations":[{"effect":"NoSchedule","key":"infra","value":"reserved"},{"effect":"NoExecute","key":"infra","value":"reserved"}]}}}}'



#TO DO. Implement Anti-affinity for infra services

echo "Prepare redhat operators"
oc create -f configs/3_operator-redhat-namespace.yaml
oc create -f configs/3_operator-redhat-group.yaml

echo "Install Logging"
oc create -f configs/4_logging-namespace.yaml
oc create -f configs/4_logging-group-cluster.yaml
oc create -f configs/4_logging-subscription-es.yaml
oc create -f configs/4_logging-subscription-cluster.yaml
while [ `oc get crd -o name |grep  clusterloggings.logging.openshift.io`1 != 'customresourcedefinition.apiextensions.k8s.io/clusterloggings.logging.openshift.io1' ]
do 
  sleep 5
done

oc create -f configs/4_logging-crd.yaml

echo "ETCD encryption"
echo "...Routes, Oauth tokens encryptions..."
oc patch apiserver cluster --type=merge -p '{"spec":{"encryption":{"type":"aescbc"}}}'

echo "Apply Cluster Autoscaler"
oc create -f configs/5_cluster-autoscaler.yaml

echo "Apply Machine autoscaler"
oc get machinesets -n openshift-machine-api -o name |awk -F'/' {'print $2'} |while read line;do cat configs/5_machine-autoscaler.yaml |sed "s/node-machineset/$line/" | oc create -f - ;done

echo "Apply HTpasswd oauth provider"
htpasswd -c -B -b users.htpasswd admin compaq
oc create secret generic htpass-secret --from-file=htpasswd=users.htpasswd -n openshift-config
oc patch oauth/cluster  --type=merge -p '{"spec":{"identityProviders":[{"htpasswd":{"fileData":{"name":"htpass-secret"}},"mappingMethod":"claim","name":"my_htpasswd_provider","type":"HTPasswd"}]}}'

echo "Add cluster-admin role to admin user"
oc adm policy add-cluster-role-to-user cluster-admin admin
