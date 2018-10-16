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

# Label nodes for affinity. For DockerContainerFactory, at least one invoker node is required.
echo "Labeling nodes with openwhisk-role assignments"
kubectl label nodes kube-node-1 openwhisk-role=core
kubectl label nodes kube-node-1 openwhisk-role=edge
kubectl label nodes kube-node-2 openwhisk-role=invoker

# Create namespace
echo "Create openwhisk namespace"
kubectl create namespace openwhisk

# configure a NodePort Ingress assuming kubeadm-dind-cluster conventions
# use kube-node-1 as the ingress, since that is where nginx will be running
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
    api_host_name: $WSK_HOST
    api_host_port: $WSK_PORT
  runtimes: "runtimes-minimal-travis.json"

invoker:
  containerFactory:
    impl: $OW_CONTAINER_FACTORY
    kubernetes:
      agent:
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

# Wait for catalog and routemgmt jobs to complete successfully
jobHealthCheck "install-catalog"
jobHealthCheck "install-routemgmt"

# Configure wsk CLI
wsk property set --auth `kubectl -n openwhisk get secret whisk.auth -o jsonpath='{.data.guest}' | base64 --decode` --apihost $WSK_HOST:$WSK_PORT

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

# first list the actions and expect to see hello
RESULT=$(wsk -i action list | grep hello)
if [ -z "$RESULT" ]; then
  echo "FAILED! Could not list hello action via CLI"
  exit 1
fi

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

RESULT=$(wsk package list /whisk.system -i | grep messaging)
if [ -z "$RESULT" ]; then
  echo "FAILED! Could not list messaging package via CLI"
  exit 1
else
  echo "PASSED! Deployed Kafka provider and package"
fi

####
# Verify alarm provider and alarms package
####
jobHealthCheck "install-package-alarm"
deploymentHealthCheck "alarmprovider"

RESULT=$(wsk package list /whisk.system -i | grep alarms)
if [ -z "$RESULT" ]; then
  echo "FAILED! Could not list alarms package via CLI"
  exit 1
else
  echo "PASSED! Deployed Alarms provider and package"
fi

####
# Verify Cloudant provider and cloudant package
####
jobHealthCheck "install-package-cloudant"
deploymentHealthCheck "cloudantprovider"

RESULT=$(wsk package list /whisk.system -i | grep cloudant)
if [ -z "$RESULT" ]; then
  echo "FAILED! Could not list cloudant package via CLI"
  exit 1
else
  echo "PASSED! Deployed Cloudant provider and package"
fi
