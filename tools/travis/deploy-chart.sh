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
    KUBE_READY_COUNT=$(kubectl -n openwhisk get pods -l name="$1" -o wide | grep "$1" | awk '{print $2}' | awk -F / '{print $1}')
    if [[ "$KUBE_DEPLOY_STATUS" == "Running" ]] && [[ "$KUBE_READY_COUNT" != "0" ]]; then
      PASSED=true
      echo "The deployment $1 is ready"
      break
    fi

    kubectl get pods -n openwhisk -o wide

    let TIMEOUT=TIMEOUT+1
    sleep 10
  done

  if [ "$PASSED" == "false" ]; then
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
    KUBE_READY_COUNT=$(kubectl -n openwhisk get pods -l name="$1" -o wide | grep "$1"-0 | awk '{print $2}' | awk -F / '{print $1}')
    if [[ "$KUBE_DEPLOY_STATUS" == "Running" ]] && [[ "$KUBE_READY_COUNT" != "0" ]]; then
      PASSED=true
      echo "The statefulset $1 is ready"
      break
    fi

    kubectl get pods -n openwhisk -o wide

    let TIMEOUT=TIMEOUT+1
    sleep 10
  done

  if [ "$PASSED" == "false" ]; then
    echo "Failed to finish deploying $1"
    # Dump all namespaces in case the problem is with a pod in the kube-system namespace
    kubectl get pods --all-namespaces -o wide

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
    KUBE_DEPLOY_STATUS=$(kubectl -n openwhisk get pods -l name="$1" -o wide | grep "$1" | awk '{print $3}')
    if [ "$KUBE_DEPLOY_STATUS" == "Completed" ]; then
      PASSED=true
      echo "The job $1 has completed"
      break
    fi

    kubectl get pods -n openwhisk -o wide

    let TIMEOUT=TIMEOUT+1
    sleep 10
  done

  if [ "$PASSED" == "false" ]; then
    echo "Failed to finish running $1"
    # Dump all namespaces in case the problem is with a pod in the kube-system namespace
    kubectl get pods --all-namespaces -o wide

    kubectl -n openwhisk logs jobs/$1
    exit 1
  fi

  echo "$1 completed"
}


verifyHealthyInvoker () {
  PASSED=false
  TIMEOUT=0
  until $PASSED || [ $TIMEOUT -eq $TIMEOUT_STEP_LIMIT ]; do
    wget -qO /tmp/count.txt --no-check-certificate https://$WSK_HOST:$WSK_PORT/invokers/healthy/count
    NUM_HEALTHY_INVOKERS=$(cat /tmp/count.txt)
    if [ $NUM_HEALTHY_INVOKERS -gt 0 ]; then
      PASSED=true
      echo "There are $NUM_HEALTHY_INVOKERS healthy invokers"
      break
    fi

    kubectl get pods -n openwhisk -o wide

    let TIMEOUT=TIMEOUT+1
    sleep 10
  done

  if [ "$PASSED" == "false" ]; then
    # Dump all namespaces in case the problem is with a pod in the kube-system namespace
    kubectl get pods --all-namespaces -o wide
    echo "No healthy invokers available"

    exit 1
  fi
}



#################
# Main body of script -- deploy OpenWhisk
#################

set -x

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../../"

# Default to docker container factory if not specified
OW_CONTAINER_FACTORY=${OW_CONTAINER_FACTORY:="docker"}

# Default to not including system tests in helm test suite
OW_INCLUDE_SYSTEM_TESTS=${$OW_INCLUDE_SYSTEM_TESTS:="false"}

# Default timeout limit to 60 steps
TIMEOUT_STEP_LIMIT=${TIMEOUT_STEP_LIMIT:=60}

# Label nodes for affinity.
# For DockerContainerFactory, at least one must be labeled as an invoker.
echo "Labeling nodes with openwhisk-role assignments"
kubectl label nodes kube-node-1 openwhisk-role=core
kubectl label nodes kube-node-2 openwhisk-role=invoker

# Configure a NodePort Ingress assuming kubeadm-dind-cluster conventions.
# Use kube-node-1 as the ingress, since we labeled it as our core node above.
# (But using kube-node-2 would also work because Kubernetes
#  exposes the same NodePort service on all worker nodes.)
WSK_PORT=31001
WSK_HOST=$(kubectl describe node kube-node-1 | grep InternalIP: | awk '{print $2}')
if [ -z "$WSK_HOST" ]; then
  echo "FAILED! Could not determine value for WSK_HOST"
  exit 1
fi

# Deploy OpenWhisk using Helm
cd $ROOTDIR

cat > mycluster.yaml <<EOF
whisk:
  ingress:
    type: NodePort
    apiHostName: $WSK_HOST
    apiHostPort: $WSK_PORT
  runtimes: "runtimes-minimal-travis.json"
  testing:
    includeSystemTests: $OW_INCLUDE_SYSTEM_TESTS

# TODO: instead document how to enable dynamic volume provisioning for dind
k8s:
  persistence:
    enabled: false

invoker:
  containerFactory:
    dind: true
    impl: $OW_CONTAINER_FACTORY
    kubernetes:
      agent:
        enabled: false

nginx:
  httpsNodePort: $WSK_PORT
EOF

echo "Contents of mycluster.yaml are:"
cat mycluster.yaml

helm install helm/openwhisk --namespace=openwhisk --name=ow4travis -f mycluster.yaml || exit 1

# Wait for controller to be up
statefulsetHealthCheck "ow4travis-controller"

# Wait for invoker to be up
deploymentHealthCheck "ow4travis-invoker"

# Wait for the controller to confirm that it has at least one healthy invoker
verifyHealthyInvoker

# Wait for install-packages job to complete successfully
jobHealthCheck "ow4travis-install-packages"

# Verify that the providers deployed successfully
deploymentHealthCheck "ow4travis-alarmprovider"
deploymentHealthCheck "ow4travis-cloudantprovider"
deploymentHealthCheck "ow4travis-kafkaprovider"

