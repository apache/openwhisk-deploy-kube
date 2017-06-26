#!/bin/bash

DIR=$( cd "$( dirname "$0" )" && pwd )

echo "Enabling promisc mode in minikube"
minikube ssh sudo ip link set docker0 promisc on

echo "Launching configure job"
kubectl apply -f $DIR/../configure/openwhisk_kube_namespace.yml
kubectl apply -f $DIR/../configure/configure_whisk.yml


printf "Waiting for invoker StatefulSet to exist"
TIMEOUT=0
TIMEOUT_COUNT=100
until $(kubectl -n openwhisk get statefulset invoker &> /dev/null) || [ $TIMEOUT -eq $TIMEOUT_COUNT ]; do
    printf "."
    let TIMEOUT=TIMEOUT+1
    sleep 5
done
echo

if [ $TIMEOUT -eq $TIMEOUT_COUNT ]; then
  echo "Gave up waiting for the invoker StatefulSet"
  exit 1
fi

echo "Patching the invoker StatefulSet to downgrade the docker API version"
kubectl -n openwhisk patch statefulset invoker --type=json -p '[{"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "DOCKER_API_VERSION", "value": "1.23"}}]'

echo "Deleting existing invoker pod so it will get recreated with new env"
kubectl -n openwhisk delete po/invoker-0

CONFIGURE_POD=$(kubectl get pods --all-namespaces -o wide | grep configure | awk '{print $2}')

printf "Waiting for the configure job to complete"
PASSED=false
TIMEOUT=0
TIMEOUT_COUNT=25
until $PASSED || [ $TIMEOUT -eq $TIMEOUT_COUNT ]; do
  KUBE_DEPLOY_STATUS=$(kubectl -n openwhisk get jobs | grep configure-openwhisk | awk '{print $3}')
  if [ $KUBE_DEPLOY_STATUS -eq 1 ]; then
    PASSED=true
    break
  fi
  printf "."
  let TIMEOUT=TIMEOUT+1
  sleep 30
done
echo

if [ "$PASSED" = false ]; then
  echo "The job to configure OpenWhisk did not finish successfully"
  echo "Execute \`kubectl -n openwhisk logs $CONFIGURE_POD\` to see the output from the configure job"
  exit 1
fi

port=$(kubectl -n openwhisk describe service nginx | grep https-api | grep NodePort | awk '{print $3}' | cut -d'/' -f1)
url="https://$(minikube ip):$port"

echo "OpenWhisk should now be available at $url"
