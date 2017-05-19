#!/usr/bin/env bash

# this script is used to cleanup the OpenWhisk deployment

set -x

# delete OpenWhisk configure job
kubectl -n openwhisk delete job configure-openwhisk

# delete deployments
kubectl -n openwhisk delete deployment couchdb
kubectl -n openwhisk delete deployment consul
kubectl -n openwhisk delete deployment zookeeper
kubectl -n openwhisk delete deployment kafka
kubectl -n openwhisk delete deployment controller
kubectl -n openwhisk delete statefulsets invoker
kubectl -n openwhisk delete deployment nginx

# delete configmaps
kubectl -n openwhisk delete cm consul
kubectl -n openwhisk delete cm controller
kubectl -n openwhisk delete cm nginx

# delete services
kubectl -n openwhisk delete service couchdb
kubectl -n openwhisk delete service consul
kubectl -n openwhisk delete service zookeeper
kubectl -n openwhisk delete service kafka
kubectl -n openwhisk delete service controller
kubectl -n openwhisk delete service invoker
kubectl -n openwhisk delete service nginx

# delete secrets
kubectl -n openwhisk delete secret openwhisk-auth-tokens
