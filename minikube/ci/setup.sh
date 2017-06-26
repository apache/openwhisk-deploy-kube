#!/bin/bash

# Installs and starts minikube

set -x

# download kubectl
wget https://storage.googleapis.com/kubernetes-release/release/v1.5.4/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

# download minikube
wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube-linux-amd64
sudo mv minikube-linux-amd64 /usr/local/bin/minikube
minikube version

# assumes virtualbox, override with  --vm-driver virtualbox|kvm|xhyve|vmwarefusion
minikube start

# Wait until minikube is up and running
TIMEOUT=0
TIMEOUT_COUNT=40
until $(minikube status &> /dev/null) || [ $TIMEOUT -eq $TIMEOUT_COUNT ]; do
  echo "Minikube is not up yet"
  let TIMEOUT=TIMEOUT+1
  sleep 20
done

if [ $TIMEOUT -eq $TIMEOUT_COUNT ]; then
  echo "Minikube is not up and running"
  exit 1
fi

echo "Minikube is ready"



