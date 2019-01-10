#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements; and to You under the Apache License, Version 2.0.

set -x

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../../"

cd $ROOTDIR

echo "Gathering logs to upload to https://app.box.com/v/openwhisk-travis-logs"

mkdir logs

# Logs from all the pods
kubectl -n openwhisk logs -lname=ow4travis-couchdb >& logs/couchdb.log
kubectl -n openwhisk logs -lname=ow4travis-zookeeper >& logs/zookeeper.log
kubectl -n openwhisk logs -lname=ow4travis-kafka >& logs/kafka.log
kubectl -n openwhisk logs -lname=ow4travis-controller >& logs/controller.log
kubectl -n openwhisk logs -lname=ow4travis-invoker -c docker-pull-runtimes >& logs/invoker-docker-pull.log
kubectl -n openwhisk logs -lname=ow4travis-invoker -c invoker >& logs/invoker-invoker.log
kubectl -n openwhisk logs -lname=ow4travis-nginx >& logs/nginx.log
kubectl -n openwhisk logs -lname=ow4travis-install-packages >& logs/install-packages.log
kubectl -n openwhisk logs -lname=ow4travis-init-couchdb >& logs/init-couchdb.log
kubectl logs -n openwhisk -low-testpod=true >& logs/helm-tests.log
kubectl -n openwhisk logs -lname=ow4travis-alarmprovider >& logs/kafkaprovider.log
kubectl -n openwhisk logs -lname=ow4travis-cloudantprovider >& logs/cloudantprovider.log
kubectl -n openwhisk logs -lname=ow4travis-kafkaprovider >& logs/kafkaprovider.log
kubectl get pods --all-namespaces -o wide --show-all >& logs/all-pods.txt

# System level logs from kubernetes cluster
$HOME/dind-cluster.sh dump >& logs/dind-cluster-dump.txt
