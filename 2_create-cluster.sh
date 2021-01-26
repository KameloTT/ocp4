hostssh=`cat creds |grep ^hostssh |awk -F"'" '{print $2}'`
ssh $hostssh <<EOSSH

echo '---Install cluster----'
openshift-install create cluster --dir=ocp4cluster1
echo 'KUBECONFIG=/home/avishnia-redhat.com/ocp4cluster1/auth/kubeconfig' | sudo tee -a /etc/environment
EOSSH
