#!/bin/bash

set -x

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../../"

cd $ROOTDIR

echo "Gathering logs to upload to https://app.box.com/v/openwhisk-travis-logs"

mkdir logs

# Logs from all the pods
kubectl -n openwhisk logs -lname=couchdb >& logs/couchdb.log
kubectl -n openwhisk logs -lname=zookeeper >& logs/zookeeper.log
kubectl -n openwhisk logs -lname=kafka >& logs/kafka.log
kubectl -n openwhisk logs controller-0 >& logs/controller-0.log
kubectl -n openwhisk logs controller-1 >& logs/controller-1.log
kubectl -n openwhisk logs -lname=invoker -c docker-pull-runtimes >& logs/invoker-docker-pull.log
kubectl -n openwhisk logs -lname=invoker -c invoker >& logs/invoker-invoker.log
kubectl -n openwhisk logs -lname=nginx >& logs/nginx.log
kubectl -n openwhisk logs -lname=kafkaprovider >& logs/kafkaprovider.log
kubectl -n openwhisk logs jobs/install-routemgmt >& logs/routemgmt.log
kubectl -n openwhisk logs jobs/install-catalog >& logs/catalog.log
kubectl -n openwhisk logs jobs/kafkapkginstaller >& logs/kafkapkginstaller.log
kubectl get pods --all-namespaces -o wide --show-all >& logs/all-pods.txt

# System level logs from minikube
minikube logs >& logs/minikube.log
