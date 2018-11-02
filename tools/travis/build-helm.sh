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


packageListingCheck() {
  if [ -z "$1" ]; then
    echo "Error, package listing check called without a package name"
    exit 1
  fi

  # Try several times to accommodate eventual consistency of CouchDB
  PACKAGE_LIST_PASSED=false
  PACKAGE_LIST_ATTEMPTS=0
  until $PACKAGE_LIST_PASSED; do
      RESULT=$(wsk package list /whisk.system -i | grep "$1")
      if [ -z "$RESULT" ]; then
          let PACKAGE_LIST_ATTEMPTS=PACKAGE_LIST_ATTEMPTS+1
          if [ $PACKAGE_LIST_ATTEMPTS -gt 5 ]; then
              echo "FAILED! Could not list package $1"
              exit 1
          fi
          echo "wsk package list did not find $1; sleep 5 seconds and try again"
          sleep 5
      else
          echo "success: wsk package list included $1"
          PACKAGE_LIST_PASSED=true
      fi
  done
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

# Create namespace
echo "Create openwhisk namespace"
kubectl create namespace openwhisk

# Configure a NodePort Ingress assuming kubeadm-dind-cluster conventions.
# Use kube-node-1 as the ingress, since that is where nginx will actually
# be running, but using kube-node-2 would also work because Kubernetes
# exposes the same NodePort service on all worker nodes.
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
statefulsetHealthCheck "controller"

# Wait for invoker to be up
deploymentHealthCheck "invoker"

# Wait for the controller to confirm that it has at least one healthy invoker
verifyHealthyInvoker

# Wait for catalog and routemgmt jobs to complete successfully
jobHealthCheck "install-catalog"
jobHealthCheck "install-routemgmt"

# Configure wsk CLI
WSK_AUTH=$(kubectl -n openwhisk get secret whisk.auth -o jsonpath='{.data.guest}' | base64 --decode)
wsk property set --auth $WSK_AUTH --apihost $WSK_HOST:$WSK_PORT

#################
# Sniff test: create and invoke a simple Hello world action
#################

# create wsk action
cat > /tmp/hello.js << EOL
function main() {
  return {body: 'Hello world'}
}
EOL
wsk -i action create hello /tmp/hello.js --web true

# first list actions and expect to see hello
# Try several times to accommodate eventual consistency of CouchDB
ACTION_LIST_PASSED=false
ACTION_LIST_ATTEMPTS=0
until $ACTION_LIST_PASSED; do
  RESULT=$(wsk -i action list | grep hello)
  if [ -z "$RESULT" ]; then
    let ACTION_LIST_ATTEMPTS=ACTION_LIST_ATTEMPTS+1
    if [ $ACTION_LIST_ATTEMPTS -gt 5 ]; then
      echo "FAILED! Could not list hello action via CLI"
      exit 1
    fi
    echo "wsk action list did not include hello; sleep 5 seconds and try again"
    sleep 5
  else
      echo "success: wsk action list included hello"
      ACTION_LIST_PASSED=true
  fi
done

# next invoke the new hello world action via the CLI
RESULT=$(wsk -i action invoke --blocking hello | grep "\"status\": \"success\"")
if [ -z "$RESULT" ]; then
  echo "FAILED! Could not invoke hello action via CLI"
  exit 1
fi

# now run it as a web action
HELLO_URL=$(wsk -i action get hello --url | grep "https://")
RESULT=$(wget --no-check-certificate -qO- $HELLO_URL | grep 'Hello world')
if [ -z "$RESULT" ]; then
  echo "FAILED! Could not invoke hello as a web action"
  exit 1
fi

# now define it as an api and invoke it that way
wsk -i api create /demo /hello get hello
API_URL=$(wsk -i api list | grep hello | awk '{print $4}')
RESULT=$(wget --no-check-certificate -qO- "$API_URL" | grep 'Hello world')
if [ -z "$RESULT" ]; then
  echo "FAILED! Could not invoke hello via apigateway"
  exit 1
fi

echo "PASSED! Created Hello action and invoked via cli, web and apigateway"

###
# Now install all the provider helm charts.
# To reduce testing latency we first install all the charts,
# then we check for correct deployment of each one.
###
helm install helm/openwhisk-providers/charts/ow-kafka --namespace=openwhisk --name=kafkap4travis  || exit 1
helm install helm/openwhisk-providers/charts/ow-alarm --namespace=openwhisk --name alarmp4travis --set alarmprovider.persistence.storageClass=none || exit 1
helm install helm/openwhisk-providers/charts/ow-cloudant --namespace=openwhisk --name cloudantp4travis --set cloudantprovider.persistence.storageClass=none || exit 1


####
# Verify kafka provider and messaging package
####
jobHealthCheck "install-package-kafka"
deploymentHealthCheck "kafkaprovider"
packageListingCheck "messaging"
echo "PASSED! Deployed Kafka provider and package"


####
# Verify alarm provider and alarms package
####
jobHealthCheck "install-package-alarm"
deploymentHealthCheck "alarmprovider"
packageListingCheck "alarms"
echo "PASSED! Deployed Alarms provider and package"


####
# Verify Cloudant provider and cloudant package
####
jobHealthCheck "install-package-cloudant"
deploymentHealthCheck "cloudantprovider"
packageListingCheck "cloudant"
echo "PASSED! Deployed Cloudant provider and package"


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
