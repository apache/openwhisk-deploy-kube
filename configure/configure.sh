#!/usr/bin/env bash

# this script is used to deploy OpenWhisk from a pod already running in
# kubernetes.
#
# Note: This pod assumes that there is an openwhisk namespace and the pod
# running this script has been created in that namespace.

deployCouchDB() {
  COUCH_DEPLOYED=$(kubectl -n openwhisk get pods --show-all | grep couchdb | grep "1/1")

  if [ -z "$COUCH_DEPLOYED" ]; then
   return 0;
  else
   return 1;
  fi
}

set -ex

# copy the ansible playbooks and tools to this repo
cp -R /openwhisk/ansible/ /incubator-openwhisk-deploy-kube/ansible
cp -R /openwhisk/tools/ /incubator-openwhisk-deploy-kube/tools
cp -R /openwhisk/bin/ /incubator-openwhisk-deploy-kube/bin

mkdir -p /incubator-openwhisk-deploy-kube/core
cp -R /openwhisk/core/routemgmt /incubator-openwhisk-deploy-kube/core/routemgmt

# overwrite the default openwhisk ansible with the kube ones.
cp -R /incubator-openwhisk-deploy-kube/ansible-kube/. /incubator-openwhisk-deploy-kube/ansible/

# start kubectl in proxy mode so we can talk to the Kube Api server
kubectl proxy -p 8001 &

pushd /incubator-openwhisk-deploy-kube/ansible
  ansible-playbook -i environments/kube setup.yml

  # Create all of the necessary services
  kubectl apply -f environments/kube/files/db-service.yml

  if deployCouchDB; then
    # Create and configure the CouchDB deployment
    ansible-playbook -i environments/kube couchdb.yml
    ansible-playbook -i environments/kube initdb.yml
    ansible-playbook -i environments/kube wipe.yml
  fi
popd
