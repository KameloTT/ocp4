hostssh=`cat creds |grep ^hostssh |awk -F"'" '{print $2}'`
ssh $hostssh <<EOF

echo '---Destroy cluster----'
openshift-install destroy cluster --dir=ocp4cluster1

EOF
