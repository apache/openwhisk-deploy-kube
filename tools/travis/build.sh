#!/bin/bash

#################
# Helper functions for verifying pod creation
#################

couchdbHealthCheck () {
  # wait for the pod to be created before getting the job name
  sleep 5
  POD_NAME=$(kubectl -n openwhisk get pods -o wide --show-all | grep "couchdb" | awk '{print $1}')

  PASSED=false
  TIMEOUT=0
  until [ $TIMEOUT -eq 60 ]; do
    if [ -n "$(kubectl -n openwhisk logs $POD_NAME | grep "successfully setup and configured CouchDB")" ]; then
      PASSED=true
      break
    fi

    let TIMEOUT=TIMEOUT+1
    sleep 10
  done

  if [ "$PASSED" = false ]; then
    echo "Failed to finish deploying CouchDB"

    kubectl -n openwhisk logs $POD_NAME
    exit 1
  fi

  echo "CouchDB is up and running"
}

deploymentHealthCheck () {
  if [ -z "$1" ]; then
    echo "Error, component health check called without a component parameter"
    exit 1
  fi

  PASSED=false
  TIMEOUT=0
  until $PASSED || [ $TIMEOUT -eq 60 ]; do
    KUBE_DEPLOY_STATUS=$(kubectl -n openwhisk get pods -o wide | grep "$1" | awk '{print $3}')
    if [ "$KUBE_DEPLOY_STATUS" == "Running" ]; then
      PASSED=true
      break
    fi

    kubectl get pods --all-namespaces -o wide --show-all

    let TIMEOUT=TIMEOUT+1
    sleep 10
  done

  if [ "$PASSED" = false ]; then
    echo "Failed to finish deploying $1"

    kubectl -n openwhisk logs $(kubectl -n openwhisk get pods -o wide | grep "$1" | awk '{print $1}')
    exit 1
  fi

  echo "$1 is up and running"
}

statefulsetHealthCheck () {
  if [ -z "$1" ]; then
    echo "Error, StatefulSet health check called without a parameter"
    exit 1
  fi

  PASSED=false
  TIMEOUT=0
  until $PASSED || [ $TIMEOUT -eq 60 ]; do
    KUBE_DEPLOY_STATUS=$(kubectl -n openwhisk get pods -o wide | grep "$1"-0 | awk '{print $3}')
    if [ "$KUBE_DEPLOY_STATUS" == "Running" ]; then
      PASSED=true
      break
    fi

    kubectl get pods --all-namespaces -o wide --show-all

    let TIMEOUT=TIMEOUT+1
    sleep 10
  done

  if [ "$PASSED" = false ]; then
    echo "Failed to finish deploying $1"

    kubectl -n openwhisk logs $(kubectl -n openwhisk get pods -o wide | grep "$1"-0 | awk '{print $1}')
    exit 1
  fi

  echo "$1-0 is up and running"

}

jobHealthCheck () {
  if [ -z "$1" ]; then
    echo "Error, job health check called without a component parameter"
    exit 1
  fi

  PASSED=false
  TIMEOUT=0
  until $PASSED || [ $TIMEOUT -eq 60 ]; do
    KUBE_SUCCESSFUL_JOB=$(kubectl -n openwhisk get jobs -o wide | grep "$1" | awk '{print $3}')
    if [ "$KUBE_SUCCESSFUL_JOB" == "1" ]; then
      PASSED=true
      break
    fi

    kubectl get jobs --all-namespaces -o wide --show-all

    let TIMEOUT=TIMEOUT+1
    sleep 10
  done

  if [ "$PASSED" = false ]; then
    echo "Failed to finish running $1"

    kubectl -n openwhisk logs jobs/$1
    exit 1
  fi

  echo "$1 completed"
}


#################
# Main body of script -- deploy OpenWhisk
#################

set -x

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../../"

cd $ROOTDIR

# Label invoker nodes (needed for daemonset-based invoker deployment)
echo "Labeling invoker node"
kubectl label nodes --all openwhisk=invoker
kubectl describe nodes

# Initial cluster setup
echo "Performing steps from cluster-setup"
pushd kubernetes/cluster-setup
  kubectl apply -f namespace.yml
  kubectl apply -f services.yml
  kubectl -n openwhisk create cm whisk.config --from-env-file=config.env
  kubectl -n openwhisk create cm whisk.runtimes --from-file=runtimes=runtimes.json
  kubectl -n openwhisk create cm whisk.limits --from-env-file=limits.env
  kubectl -n openwhisk create secret generic whisk.auth --from-file=system=auth.whisk.system --from-file=guest=auth.guest
popd

# configure Ingress and wsk CLI
# We use the NodePorts for nginx and apigateway services for Travis CI testing
pushd kubernetes/ingress
  WSK_PORT=$(kubectl -n openwhisk describe service nginx | grep https-api | grep NodePort| awk '{print $3}' | cut -d'/' -f1)
  APIGW_PORT=$(kubectl -n openwhisk describe service apigateway | grep mgmt | grep NodePort| awk '{print $3}' | cut -d'/' -f1)
  WSK_HOST=$(kubectl describe nodes | grep Hostname: | awk '{print $2}')
  if [ "$WSK_HOST" = "minikube" ]; then
      WSK_HOST=$(minikube ip)
  fi
  kubectl -n openwhisk create configmap whisk.ingress --from-literal=api_host=$WSK_HOST:$WSK_PORT --from-literal=apigw_url=http://$WSK_HOST:$APIGW_PORT
  wsk property set --auth `cat ../cluster-setup/auth.guest` --apihost $WSK_HOST:$WSK_PORT
popd

# setup couchdb
echo "Deploying couchdb"
pushd kubernetes/couchdb
  kubectl -n openwhisk create secret generic db.auth --from-literal=db_username=whisk_admin --from-literal=db_password=some_passw0rd
  kubectl -n openwhisk create configmap db.config --from-literal=db_protocol=http --from-literal=db_provider=CouchDB --from-literal=db_whisk_activations=test_activations --from-literal=db_whisk_actions=test_whisks --from-literal=db_whisk_auths=test_subjects --from-literal=db_prefix=test_
  kubectl apply -f couchdb.yml

  couchdbHealthCheck
popd

# setup apigateway
echo "Deploying apigateway"
pushd kubernetes/apigateway
  kubectl apply -f apigateway.yml

  deploymentHealthCheck "apigateway"
popd

# setup zookeeper
echo "Deploying zookeeper"
pushd kubernetes/zookeeper
  kubectl apply -f zookeeper.yml

  deploymentHealthCheck "zookeeper"
popd

# setup kafka
echo "Deploying kafka"
pushd kubernetes/kafka
  kubectl apply -f kafka.yml

  deploymentHealthCheck "kafka"
popd

# setup the controller
echo "Deploying controller"
pushd kubernetes/controller
  kubectl -n openwhisk create cm controller.config --from-env-file=controller.env
  kubectl apply -f controller.yml

  statefulsetHealthCheck "controller"
popd

# setup the invoker
echo "Deploying invoker"
pushd kubernetes/invoker
  kubectl -n openwhisk create cm invoker.config --from-env-file=invoker.env
  kubectl apply -f invoker.yml

  # wait until the invoker is ready
  deploymentHealthCheck "invoker"
popd

# setup nginx
echo "Deploying nginx"
pushd kubernetes/nginx
  ./certs.sh localhost
  kubectl -n openwhisk create configmap nginx --from-file=nginx.conf
  kubectl -n openwhisk create secret tls nginx --cert=certs/cert.pem --key=certs/key.pem

  # have seen this fail where nginx pod is applied but never created. Hard to know
  # why that is happening without having access to Kube component logs.
  sleep 5

  kubectl apply -f nginx.yml

  # wait until nginx is ready
  deploymentHealthCheck "nginx"
popd

# install routemgmt
echo "Installing routemgmt"
pushd kubernetes/routemgmt
  kubectl apply -f install-routemgmt.yml
  jobHealthCheck "install-routemgmt"
popd

# install openwhisk-catalog
echo "Installing catalog"
pushd kubernetes/openwhisk-catalog
  kubectl apply -f install-catalog.yml
  jobHealthCheck "install-catalog"
popd

# install package-kafka
echo "Installing kafka package"
pushd kubernetes/package-kafka
  kubectl -n openwhisk create cm packages.kafkaprovider --from-literal=kafkapkg_db_prefix=mq
  kubectl apply -f kafkaprovider.yml
  kubectl apply -f kafkapkginstaller.yml
  jobHealthCheck "kafkapkginstaller"
popd

# list packages and actions now installed in /whisk.system
wsk -i --auth `cat kubernetes/cluster-setup/auth.whisk.system` package list
wsk -i --auth `cat kubernetes/cluster-setup/auth.whisk.system` action list


#################
# Sniff test: create and invoke a simple Hello world action
#################

# create wsk action
cat > hello.js << EOL
function main() {
  return {payload: 'Hello world'};
}
EOL

wsk -i action create hello hello.js

sleep 5

# run the new hello world action
RESULT=$(wsk -i action invoke --blocking hello | grep "\"status\": \"success\"")

if [ -z "$RESULT" ]; then
  echo "FAILED! Could not invoked custom action"

  echo " ----------------------------- controller logs ---------------------------"
  kubectl -n openwhisk logs controller-0

  echo " ----------------------------- invoker logs ---------------------------"
  kubectl -n openwhisk logs -l name=invoker
  exit 1
fi

echo "PASSED! Deployed openwhisk and invoked Hello action"
