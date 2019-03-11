#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements; and to You under the Apache License, Version 2.0.

set -x

# Install kubernetes-dind-cluster and boot it
wget https://github.com/kubernetes-sigs/kubeadm-dind-cluster/releases/download/v0.1.0/dind-cluster-v$TRAVIS_KUBE_VERSION.sh -O $HOME/dind-cluster.sh && chmod +x $HOME/dind-cluster.sh
if [[ "$TRAVIS_KUBE_VERSION" == "1.12" ]]; then
    patch $HOME/dind-cluster.sh ./tools/travis/dind-cluster-v12.patch
fi
USE_HAIRPIN=true $HOME/dind-cluster.sh up

# Install kubectl in /usr/local/bin so subsequent scripts can find it
sudo cp $HOME/.kubeadm-dind-cluster/kubectl-v$TRAVIS_KUBE_VERSION* /usr/local/bin/kubectl


echo "Kubernetes cluster is deployed and reachable"
kubectl describe nodes

# Download and install misc packages and utilities
pushd /tmp
  # Need socat for helm to forward connections to tiller on ubuntu 16.04
  sudo apt update
  sudo apt install -y socat

  # download and install the wsk cli
  wget -q https://github.com/apache/incubator-openwhisk-cli/releases/download/latest/OpenWhisk_CLI-latest-linux-amd64.tgz
  tar xzf OpenWhisk_CLI-latest-linux-amd64.tgz
  sudo cp wsk /usr/local/bin/wsk

  # Download and install helm
  curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh && chmod +x get_helm.sh && ./get_helm.sh
popd

# Pods running in kube-system namespace should have cluster-admin role
kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default

# Install tiller into the cluster
/usr/local/bin/helm init --service-account default

# Wait for tiller to be ready
TIMEOUT=0
TIMEOUT_COUNT=60
until [ $TIMEOUT -eq $TIMEOUT_COUNT ]; do
  TILLER_STATUS=$(kubectl -n kube-system get pods -o wide | grep tiller-deploy | awk '{print $3}')
  TILLER_READY_COUNT=$(kubectl -n kube-system get pods -o wide | grep tiller-deploy | awk '{print $2}')
  if [[ "$TILLER_STATUS" == "Running" ]] && [[ "$TILLER_READY_COUNT" == "1/1" ]]; then
    break
  fi
  echo "Waiting for tiller to be ready"
  kubectl -n kube-system get pods -o wide
  let TIMEOUT=TIMEOUT+1
  sleep 5
done

if [ $TIMEOUT -eq $TIMEOUT_COUNT ]; then
  echo "Failed to install tiller"

  # Dump lowlevel logs to help diagnose failure to start tiller
  $HOME/dind-cluster.sh dump
  kubectl -n kube-system describe pods
  exit 1
fi
