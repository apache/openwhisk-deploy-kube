#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements; and to You under the Apache License, Version 2.0.

#################
# Helper functions for verifying pod creation
#################

deploymentHealthCheck () {
  if [ -z "$1" ]; then
    echo "Error, component health check called without a component parameter"
    exit 1
  fi

  PASSED=false
  TIMEOUT=0
  until $PASSED || [ $TIMEOUT -eq $TIMEOUT_STEP_LIMIT ]; do
    KUBE_DEPLOY_STATUS=$(kubectl -n openwhisk get pods -l name="$1" -o wide | grep "$1" | awk '{print $3}')
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

    kubectl -n openwhisk logs $(kubectl -n openwhisk get pods -l name="$1" -o wide | grep "$1" | awk '{print $1}')
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
  until $PASSED || [ $TIMEOUT -eq $TIMEOUT_STEP_LIMIT ]; do
    KUBE_DEPLOY_STATUS=$(kubectl -n openwhisk get pods -l name="$1" -o wide | grep "$1"-0 | awk '{print $3}')
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
  until $PASSED || [ $TIMEOUT -eq $TIMEOUT_STEP_LIMIT ]; do
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

# If TRAVIS and !TRAVIS_USE_HELM, just exit (don't test HELM deploy)
if [[ "$TRAVIS" = "true" ]] && [[ "$TRAVIS_USE_HELM" = "false" ]]; then
    exit 0
fi

# Default to docker container factory if not specified
OW_CONTAINER_FACTORY=${OW_CONTAINER_FACTORY:="docker"}

# Default timeout limit to 60 steps
TIMEOUT_STEP_LIMIT=${TIMEOUT_STEP_LIMIT:=60}

# Label invoker nodes (needed for DockerContainerFactory-based invoker deployment)
echo "Labeling invoker node"
kubectl label nodes --all openwhisk-role=invoker
kubectl describe nodes

# Create namespace
echo "Create openwhisk namespace"
kubectl create namespace openwhisk

# configure Ingress and wsk CLI
#
# FIXME: Helm deploy hardwires ports to specific values -- need to make this less fragile!
WSK_PORT=31001
APIGW_PORT=31004
WSK_HOST=$(kubectl describe nodes | grep Hostname: | awk '{print $2}')
if [ "$WSK_HOST" = "minikube" ]; then
    WSK_HOST=$(minikube ip)
fi
wsk property set --auth `cat $ROOTDIR/kubernetes/cluster-setup/auth.guest` --apihost $WSK_HOST:$WSK_PORT

# Deploy OpenWhisk using Helm
cd $ROOTDIR/helm

cat > mycluster.yaml <<EOF
whisk:
  ingress:
    api_host: $WSK_HOST:$WSK_PORT
    apigw_url: $WSK_HOST:$APIGW_PORT
EOF

cat mycluster.yaml

helm install . --namespace=openwhisk --name=ow4travis -f mycluster.yaml

# Wait for controller and invoker to be up
statefulsetHealthCheck "controller"
deploymentHealthCheck "invoker"

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
