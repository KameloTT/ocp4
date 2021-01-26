#!/bin/bash
hostssh=`cat creds |grep ^hostssh |awk -F"'" '{print $2}'`
domainname=`cat creds |grep ^domainname |awk -F"'" '{print $2}'`
clustername=`cat creds |grep ^clustername |awk -F"'" '{print $2}'`
passwordssh=`cat creds |grep ^passwordssh |awk -F"'" '{print $2}'`
accesskey=`cat creds |grep ^accesskey |awk -F"'" '{print $2}'`
secretkey=`cat creds |grep ^secretkey |awk -F"'" '{print $2}'`
pullsecret=`cat creds |grep ^pullsecret |awk -F"'" '{print $2}'`

#OCP_VERSION=4.5.13
OCP_VERSION=4.6.4
region=us-east-1

rm -rf cluster-vish-key*
ssh-keygen -f cluster-vish-key -N ''
echo "sshpass -p $passwordssh ssh-copy-id  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no $hostssh"
sshpass -p $passwordssh ssh-copy-id  -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no $hostssh
sshkey=`cat cluster-vish-key.pub |awk {'print $2'}`

cat << EOF >> credentials
[default]
aws_access_key_id = ${accesskey}
aws_secret_access_key = ${secretkey}
region = ${region}
EOF

cat << EOF >> install-config.yaml
apiVersion: v1
baseDomain: $domainname
metadata:
  name: $clustername
controlPlane:
  hyperthreading: Enabled
  name: master
  platform:
    aws:
      zones:
      - ${region}a
      - ${region}b
      - ${region}c
      rootVolume:
        iops: 4000
        size: 120
        type: io1
      type: m4.xlarge
  replicas: 3
compute:
- hyperthreading: Enabled
  name: worker
  platform:
    aws:
      rootVolume:
        iops: 2000
        size: 120
        type: io1
      type: m4.xlarge
      zones:
      - ${region}a
      - ${region}b
      - ${region}c
  replicas: 3
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  aws:
    region: ${region}
    userTags:
      clustertype: dev
      version: ${OCP_VERSION}
pullSecret: '$pullsecret'
fips: false
publish: External
sshKey: 'ssh-rsa $sshkey'
EOF

ssh -t  $hostssh << EOSSH
rm -rf awsclibundle.zip
rm -rf ./awscli-bundle
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awsclibundle.zip"
unzip awsclibundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /bin/aws
export AWSKEY=$accesskey
export AWSSECRETKEY=$secretkey
export REGION=us-east-2
rm -rf ~/.aws
mkdir -p ~/.aws

#aws sts get-caller-identity

rm -rf openshift-install-linux-*
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-install-linux-${OCP_VERSION}.tar.gz
sudo sh -c 'tar -zxvf openshift-install-linux-${OCP_VERSION}.tar.gz -C /usr/bin/'
sudo rm -f /usr/bin/README.md
sudo chmod +x /usr/bin/openshift-install
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-client-linux-${OCP_VERSION}.tar.gz
sudo sh -c 'tar zxvf openshift-client-linux-${OCP_VERSION}.tar.gz -C /usr/bin'
sudo rm -f /usr/bin/README.md
sudo chmod +x /usr/bin/oc
sudo sh -c 'oc completion bash >/etc/bash_completion.d/openshift'
rm -rf ~/.ssh/cluster-vish-key*
ssh-keygen -f ~/.ssh/cluster-vish-key -N ''

mkdir -p ocp4cluster1

EOSSH


scp credentials $hostssh:~/.aws/credentials
scp install-config.yaml $hostssh:~/ocp4cluster1/install-config.yaml
scp cluster-vish-key* $hostssh:~/
rm -rf cluster-vish-key* credentials install-config.yaml
