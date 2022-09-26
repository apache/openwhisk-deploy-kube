#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
    if [[ $KUBE_DEPLOY_STATUS == *Completed* ]]; then
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

# Default to kubernetes container factory if not specified
OW_CONTAINER_FACTORY=${OW_CONTAINER_FACTORY:="kubernetes"}

# Default to not including system tests in helm test suite
OW_INCLUDE_SYSTEM_TESTS=${OW_INCLUDE_SYSTEM_TESTS:="false"}

# Default timeout limit to 60 steps
TIMEOUT_STEP_LIMIT=${TIMEOUT_STEP_LIMIT:=60}

# Default is to not use the scheduler component
OW_SCHEDULER_ENABLED=${OW_SCHEDULER_ENABLED:="false"}

# Create namespace
kubectl create namespace openwhisk

# Default to kind conventions of using localhost:31001
WSK_PORT=${WSK_PORT:=31001}
WSK_HOST=${WSK_HOST:=localhost}

# Deploy OpenWhisk using Helm
cd $ROOTDIR

cat > ow-config.yaml <<EOF
whisk:
  runtimes: "runtimes-minimal-travis.json"
  testing:
    includeSystemTests: $OW_INCLUDE_SYSTEM_TESTS

invoker:
  containerFactory:
    impl: $OW_CONTAINER_FACTORY

controller:
  lean: ${OW_LEAN_MODE:-false}

scheduler:
  enabled: $OW_SCHEDULER_ENABLED

metrics:
  userMetricsEnabled: true
EOF

echo "Contents of ow-config.yaml are:"
cat ow-config.yaml

helm lint helm/openwhisk -n openwhisk -f deploy/kind/mycluster.yaml -f ow-config.yaml || exit 1
helm install ow4travis helm/openwhisk -n openwhisk -f deploy/kind/mycluster.yaml -f ow-config.yaml || exit 1

# Wait for controller to be up
statefulsetHealthCheck "ow4travis-controller"

# Wait for invoker to be up
if [ "${OW_LEAN_MODE:-false}" == "false" ]; then

  # Wait for invoker to be up
  deploymentHealthCheck "ow4travis-invoker"

  # Wait for the controller to confirm that it has at least one healthy invoker
  verifyHealthyInvoker

  if [ "${OW_SCHEDULER_ENABLED:-false}" == "true" ]; then
    # Wait for scheduler to be up
    statefulsetHealthCheck "ow4travis-scheduler"
  fi

  # Verify that the user-metrics components were deployed successfully
  deploymentHealthCheck "ow4travis-user-events"
  # deploymentHealthCheck "ow4travis-prometheus-server"
  deploymentHealthCheck "ow4travis-grafana"
fi



# Wait for install-packages job to complete successfully
jobHealthCheck "ow4travis-install-packages"

# Verify that the providers deployed successfully
deploymentHealthCheck "ow4travis-alarmprovider"
deploymentHealthCheck "ow4travis-kafkaprovider"
