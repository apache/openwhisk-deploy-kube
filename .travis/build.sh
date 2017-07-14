#!/bin/bash

set -x

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../"

cd $ROOTDIR

# setup the appropriate configuration image
sed -ie "s/whisk_config:v1.5.6/whisk_config:$TRAVIS_KUBE_VERSION/g" configure/configure_whisk.yml

kubectl apply -f configure/openwhisk_kube_namespace.yml
kubectl apply -f configure/configure_whisk.yml

sleep 5

CONFIGURE_POD=$(kubectl get pods --all-namespaces -o wide | grep configure | awk '{print $2}')

PASSED=false
TIMEOUT=0
until $PASSED || [ $TIMEOUT -eq 25 ]; do
  KUBE_DEPLOY_STATUS=$(kubectl -n openwhisk get jobs | grep configure-openwhisk | awk '{print $3}')
  if [ $KUBE_DEPLOY_STATUS -eq 1 ]; then
    PASSED=true
    break
  fi

  kubectl get pods --all-namespaces -o wide --show-all

  let TIMEOUT=TIMEOUT+1
  sleep 30
done

if [ "$PASSED" = false ]; then
  kubectl -n openwhisk logs $CONFIGURE_POD
  kubectl get jobs --all-namespaces -o wide --show-all
  kubectl get pods --all-namespaces -o wide --show-all

  echo "The job to configure OpenWhisk did not finish with an exit code of 1"
  exit 1
fi

echo "The job to configure OpenWhisk finished successfully"

deploymentHealthCheck () {
  if [ -z "$1" ]; then
    echo "Error, component health check called without a component parameter"
    exit 1
  fi

  PASSED=false
  TIMEOUT=0
  until $PASSED || [ $TIMEOUT -eq 25 ]; do
    KUBE_DEPLOY_STATUS=$(kubectl -n openwhisk get pods -o wide | grep "$1" | awk '{print $3}')
    if [ "$KUBE_DEPLOY_STATUS" == "Running" ]; then
      PASSED=true
      break
    fi

    kubectl get pods --all-namespaces -o wide --show-all

    let TIMEOUT=TIMEOUT+1
    sleep 30
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
  until $PASSED || [ $TIMEOUT -eq 25 ]; do
    KUBE_DEPLOY_STATUS=$(kubectl -n openwhisk get pods -o wide | grep "$1"-0 | awk '{print $3}')
    if [ "$KUBE_DEPLOY_STATUS" == "Running" ]; then
      PASSED=true
      break
    fi

    kubectl get pods --all-namespaces -o wide --show-all

    let TIMEOUT=TIMEOUT+1
    sleep 30
  done

  if [ "$PASSED" = false ]; then
    echo "Failed to finish deploying $1"

    kubectl -n openwhisk logs $(kubectl -n openwhisk get pods -o wide | grep "$1"-0 | awk '{print $1}')
    exit 1
  fi

  echo "$1-0 is up and running"

}

# setup zookeeper
pushd kubernetes/zookeeper
  kubectl apply -f zookeeper.yml

  deploymentHealthCheck "zookeeper"
popd

# setup kafka
pushd kubernetes/kafka
  kubectl apply -f kafka.yml

  deploymentHealthCheck "kafka"
popd

# setup the controller
pushd kubernetes/controller
  kubectl apply -f controller.yml

  statefulsetHealthCheck "controller"
popd

# setup the invoker
pushd kubernetes/invoker
  kubectl apply -f invoker.yml

  # wait until the invoker is ready
  statefulsetHealthCheck "invoker"
popd

# setup nginx
pushd kubernetes/nginx
  ./certs.sh localhost
  kubectl -n openwhisk create configmap nginx --from-file=nginx.conf
  kubectl -n openwhisk create secret tls nginx --cert=certs/cert.pem --key=certs/key.pem
  kubectl apply -f nginx.yml

  # wait until nginx is ready
  deploymentHealthCheck "nginx"
popd

AUTH_WSK_SECRET=789c46b1-71f6-4ed5-8c54-816aa4f8c502:abczO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP
AUTH_GUEST=23bc46b1-71f6-4ed5-8c54-816aa4f8c502:123zO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP
WSK_PORT=$(kubectl -n openwhisk describe service nginx | grep https-api | grep NodePort| awk '{print $3}' | cut -d'/' -f1)

# download and setup the wsk cli from nginx
wget --no-check-certificate https://localhost:$WSK_PORT/cli/go/download/linux/amd64/wsk
chmod +x wsk
sudo cp wsk /usr/local/bin/wsk

./wsk property set --auth $AUTH_GUEST --apihost https://localhost:$WSK_PORT


# setup the catalog
pushd /tmp
  git clone https://github.com/apache/incubator-openwhisk
  export OPENWHISK_HOME=$PWD/incubator-openwhisk

  git clone https://github.com/apache/incubator-openwhisk-catalog

  pushd incubator-openwhisk-catalog/packages
    export WHISK_CLI_PATH=/usr/local/bin/wsk

    # This script currently has an issue where the cli path is the 4th argument
    ./installCatalog.sh $AUTH_WSK_SECRET https://localhost:$WSK_PORT $WHISK_CLI_PATH
  popd
popd

# create wsk action
cat > hello.js << EOL
function main() {
  return {payload: 'Hello world'};
}
EOL

./wsk -i action create hello hello.js

sleep 5

# run the new hello world action
RESULT=$(./wsk -i action invoke --blocking hello | grep "\"status\": \"success\"")

if [ -z "$RESULT" ]; then
  echo "FAILED! Could not invoked custom action"

  echo " ----------------------------- controller logs ---------------------------"
  kubectl -n openwhisk logs $(kubectl get pods --all-namespaces -o wide | grep controller | awk '{print $2}')

  echo " ----------------------------- invoker logs ---------------------------"
  kubectl -n openwhisk logs $(kubectl get pods --all-namespaces -o wide | grep invoker | awk '{print $2}')
  exit 1
fi

echo "PASSED! Deployed openwhisk and invoked custom action"
