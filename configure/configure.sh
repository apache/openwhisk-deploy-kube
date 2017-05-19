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

# Currently, Consul needs to be seeded with the proper Invoker name to DNS address. To account for
# this, we need to use StatefulSets(https://kubernetes.io/stutorials/stateful-application/basic-stateful-set/)
# to generate the Invoker addresses in a guranteed pattern. We can then use properties from the
# StatefulSet yaml file for OpenWhisk deployment configuration options.

INVOKER_REP_COUNT=$(cat /incubator-openwhisk-deploy-kube/ansible-kube/environments/kube/files/invoker.yml | grep 'replicas:' | awk '{print $2}')
INVOKER_COUNT=${INVOKER_REP_COUNT:-1}
sed -ie "s/REPLACE_INVOKER_COUNT/$INVOKER_COUNT/g" /incubator-openwhisk-deploy-kube/ansible-kube/environments/kube/group_vars/all

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
  kubectl apply -f environments/kube/files/consul-service.yml
  kubectl apply -f environments/kube/files/zookeeper-service.yml
  kubectl apply -f environments/kube/files/kafka-service.yml
  kubectl apply -f environments/kube/files/controller-service.yml
  kubectl apply -f environments/kube/files/invoker-service.yml
  kubectl apply -f environments/kube/files/nginx-service.yml

  if deployCouchDB; then
    # Create and configure the CouchDB deployment
    ansible-playbook -i environments/kube couchdb.yml
    ansible-playbook -i environments/kube initdb.yml
    ansible-playbook -i environments/kube wipe.yml
  fi

  # Run through the openwhisk deployment
  ansible-playbook -i environments/kube openwhisk.yml

  # Post deploy step
  ansible-playbook -i environments/kube postdeploy.yml
popd
