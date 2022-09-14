#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
kubectl -n openwhisk logs -lname=ow4travis-scheduler >& logs/scheduler.log
kubectl -n openwhisk logs -lname=ow4travis-invoker -c docker-pull-runtimes >& logs/invoker-docker-pull.log
kubectl -n openwhisk logs -lname=ow4travis-invoker -c invoker >& logs/invoker-invoker.log
kubectl -n openwhisk logs -lname=ow4travis-nginx >& logs/nginx.log
kubectl -n openwhisk logs -lname=ow4travis-install-packages >& logs/install-packages.log
kubectl -n openwhisk logs -lname=ow4travis-init-couchdb >& logs/init-couchdb.log
kubectl logs -n openwhisk -low-testpod=true --tail=-1 >& logs/helm-tests.log
kubectl -n openwhisk logs -lname=ow4travis-alarmprovider >& logs/kafkaprovider.log
kubectl -n openwhisk logs -lname=ow4travis-kafkaprovider >& logs/kafkaprovider.log
kubectl -n openwhisk logs -lname=ow4travis-user-events >& logs/user-events.log
kubectl -n openwhisk logs -lname=ow4travis-prometheus >& logs/prometheus.log
kubectl -n openwhisk logs -lname=ow4travis-grafana >& logs/grafana.log
kubectl get pods --all-namespaces -o wide >& logs/all-pods.txt
