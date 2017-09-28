#!/usr/bin/env bash

# this script is used to cleanup the OpenWhisk deployment

set -x

# delete deployments
kubectl -n openwhisk delete deployment couchdb
kubectl -n openwhisk delete deployment redis
kubectl -n openwhisk delete deployment apigateway
kubectl -n openwhisk delete deployment zookeeper
kubectl -n openwhisk delete deployment kafka
kubectl -n openwhisk delete statefulsets controller
kubectl -n openwhisk delete statefulsets invoker
kubectl -n openwhisk delete deployment nginx

# delete configmaps
kubectl -n openwhisk delete cm nginx

# delete secrets
kubectl -n openwhisk delete secret nginx

# delete services
kubectl -n openwhisk delete service couchdb
kubectl -n openwhisk delete service redis
kubectl -n openwhisk delete service apigateway
kubectl -n openwhisk delete service zookeeper
kubectl -n openwhisk delete service kafka
kubectl -n openwhisk delete service controller
kubectl -n openwhisk delete service nginx
