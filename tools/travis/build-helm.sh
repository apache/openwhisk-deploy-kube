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
    KUBE_SUCCESSFUL_JOB=$(kubectl -n openwhisk get jobs -o wide | grep "$1" | awk '{print $3}')
    if [ "$KUBE_SUCCESSFUL_JOB" == "1" ]; then
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
    kubectl get jobs --all-namespaces -o wide --show-all

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
    kubectl get pods --all-namespaces -o wide --show-all
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

providers:
  alarm:
    enabled: true
  cloudant:
    enabled: true
  kafka:
    enabled: true

nginx:
  httpsNodePort: $WSK_PORT
EOF

echo "Contents of mycluster.yaml are:"
cat mycluster.yaml

helm install helm/openwhisk --namespace=openwhisk --name=ow4travis -f mycluster.yaml || exit 1

# Wait for controller to be up
statefulsetHealthCheck "controller"

# Wait for invoker to be up
deploymentHealthCheck "invoker"

# Wait for the controller to confirm that it has at least one healthy invoker
verifyHealthyInvoker

# Wait for install-packages job to complete successfully
jobHealthCheck "install-packages"

# Verify that the providers deployed successfully
deploymentHealthCheck "alarmprovider"
deploymentHealthCheck "cloudantprovider"
deploymentHealthCheck "kafkaprovider"


###
# Now run the tests provided in the Chart to sanity check the deployment
###
if helm test ow4travis; then
    echo "PASSED! Deployment verification tests passed."
else
    echo "FAILED: Deployment verification tests failed."
    kubectl logs -n openwhisk -low-testpod=true
    exit 1
fi


###
# Finally, clone the main openwhisk repo to get the test suite and run tests:testSystemBasic
# TODO: The following tests have issues under the KubernetesContainerFactory
#   1. WskActionTest "not be able to use 'ping' in an action" -- fails because user actions are full fledged pods with unrestricted network
#   2. Tests that read activation logs in retry loops fail; perhaps because log extraction is so slow
###
if [ "$OW_RUN_SYSTEM_TESTS" == "yes" ]; then
    (git clone https://github.com/apache/incubator-openwhisk openwhisk && cd openwhisk && \
         TERM=dumb ./gradlew install && \
         TERM=dumb ./gradlew :tests:testSystemBasic -Dwhisk.auth="$WSK_AUTH" -Dwhisk.server=https://$WSK_HOST:$WSK_PORT -Dopenwhisk.home=`pwd`) || exit 1
fi
