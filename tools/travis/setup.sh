# This script assumes Docker is already installed
#!/bin/bash

set -x

# download and install the wsk cli
wget -q https://github.com/apache/incubator-openwhisk-cli/releases/download/latest/OpenWhisk_CLI-latest-linux-amd64.tgz
tar xzf OpenWhisk_CLI-latest-linux-amd64.tgz
sudo cp wsk /usr/local/bin/wsk

# set docker0 to promiscuous mode
sudo ip link set docker0 promisc on

# Download and install kubectl and minikube following the recipe in the minikube
# project README.md for using minikube for Linux Continuous Integration with VM Support
curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$TRAVIS_KUBE_VERSION/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin
curl -Lo minikube https://storage.googleapis.com/minikube/releases/$TRAVIS_MINIKUBE_VERSION/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin

export MINIKUBE_WANTUPDATENOTIFICATION=false
export MINIKUBE_WANTREPORTERRORPROMPT=false
export MINIKUBE_HOME=$HOME
export CHANGE_MINIKUBE_NONE_USER=true
mkdir $HOME/.kube || true
touch $HOME/.kube/config

export KUBECONFIG=$HOME/.kube/config
sudo -E /usr/local/bin/minikube start --vm-driver=none --kubernetes-version=$TRAVIS_KUBE_VERSION

# Wait until we have a ready node in minikube
TIMEOUT=0
TIMEOUT_COUNT=60
until [ $TIMEOUT -eq $TIMEOUT_COUNT ]; do
  if [ -n "$(/usr/local/bin/kubectl get nodes | grep Ready)" ]; then
    break
  fi

  echo "minikube is not up yet"
  let TIMEOUT=TIMEOUT+1
  sleep 5
done

if [ $TIMEOUT -eq $TIMEOUT_COUNT ]; then
  echo "Failed to start minikube"
  exit 1
fi

echo "minikube is deployed and reachable"
/usr/local/bin/kubectl describe nodes
