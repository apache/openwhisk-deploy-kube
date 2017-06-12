#!/bin/bash

set -ex

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../"

cd $ROOTDIR

# TODO: need official repo
# build openwhisk images
# This way everything that is tested will use the latest openwhisk builds

./deploy_minikube.sh

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

# Don't try and perform wsk actions the second it finishes deploying.
# The CI ocassionaly fails if you perform actions to quickly.
sleep 30

AUTH_SECRET=$(kubectl -n openwhisk get secret openwhisk-auth-tokens -o yaml | grep 'auth_whisk_system:' | awk '{print $2}' | base64 --decode)
WSK_PORT=$(kubectl -n openwhisk describe service nginx | grep https-api | grep NodePort| awk '{print $3}' | cut -d'/' -f1)
WSK_HOST=$(minikube ip)
WSK_URL="https://$WSK_HOST:$WSK_PORT"

# download the wsk cli from nginx
wget --no-check-certificate $WSK_URL/cli/go/download/linux/amd64/wsk
chmod +x wsk

# setup the wsk cli
./wsk property set --auth $AUTH_SECRET --apihost $WSK_URL

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
  exit 1
fi

echo "PASSED! Deployed openwhisk and invoked custom action"

# push the images to an official repo
