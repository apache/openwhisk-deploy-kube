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

{{/* Init container that waits for couchdb to be ready */}}
{{- define "openwhisk.readiness.waitForCouchDB" -}}
{{ if not .Values.db.wipeAndInit }}
# if not db.wipeAndInit, the external db must already be ready; so no need for init container
{{- else -}}
- name: "wait-for-couchdb"
  image: "{{- .Values.docker.registry.name -}}{{- .Values.busybox.imageName -}}:{{- .Values.busybox.imageTag -}}"
  imagePullPolicy: "IfNotPresent"
  env:
  - name: "READINESS_URL"
    value: {{ .Values.db.protocol }}://{{ include "openwhisk.db_host" . }}:{{ .Values.db.port }}/ow_kube_couchdb_initialized_marker
  command: ["sh", "-c", "while true; do echo 'checking CouchDB readiness'; wget -T 5 --spider $READINESS_URL --header=\"Authorization: Basic {{ include "openwhisk.db_authentication" . | b64enc }}\"; result=$?; if [ $result -eq 0 ]; then echo 'Success: CouchDB is ready!'; break; fi; echo '...not ready yet; sleeping 3 seconds before retry'; sleep 3; done;"]
{{- end -}}
{{- end -}}

{{/* Init container that waits for kafka to be ready */}}
{{- define "openwhisk.readiness.waitForKafka" -}}
- name: "wait-for-kafka"
  image: "{{- .Values.docker.registry.name -}}{{- .Values.utility.imageName -}}:{{- .Values.utility.imageTag -}}"
  imagePullPolicy: "IfNotPresent"
  command: ["sh", "-c", 'cacert="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"; token="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"; while true; do rc=$(curl -sS --cacert $cacert --header "Authorization: Bearer $token" https://kubernetes.default.svc/api/v1/namespaces/{{ .Release.Namespace }}/endpoints/{{ .Release.Name }}-kafka | jq -r ".subsets[].addresses | length"); echo "num ready kafka endpoints is $rc"; if [ $rc -gt 0 ]; then echo "Success: ready kafka endpoint!"; break; fi; echo "kafka not ready yet; sleeping for 3 seconds"; sleep 3; done;']
{{- end -}}

{{/* Init container that waits for etcd to be ready */}}
{{- define "openwhisk.readiness.waitForEtcd" -}}
- name: "wait-for-etcd"
  image: "{{- .Values.docker.registry.name -}}{{- .Values.utility.imageName -}}:{{- .Values.utility.imageTag -}}"
  imagePullPolicy: "IfNotPresent"
  env:
  - name: "READINESS_URL"
    value: http://{{ include "openwhisk.etcd_host" . }}:{{ .Values.etcd.port }}/health
  command: ["sh", "-c", "while true; do echo 'checking etcd readiness'; health_result=$(curl -m 5 $READINESS_URL) && echo $health_result | jq -e '. | select(.health==\"true\")'; result=$?; if [ $result -eq 0 ]; then echo 'Success: etcd is ready!'; break; fi; echo '...not ready yet; sleeping 3 seconds before retry'; sleep 3; done;"]
{{- end -}}

{{/* Init container that waits for zookeeper to be ready */}}
{{- define "openwhisk.readiness.waitForZookeeper" -}}
- name: "wait-for-zookeeper"
  image: "{{- .Values.docker.registry.name -}}{{- .Values.busybox.imageName -}}:{{- .Values.busybox.imageTag -}}"
  imagePullPolicy: "IfNotPresent"
  command: ["sh", "-c", 'result=1; until [ $result -eq 0 ]; do OK=$(echo ruok | nc -w 1 {{ include "openwhisk.zookeeper_zero_host" . }} {{ .Values.zookeeper.port }}); if [ "$OK" == "imok" ]; then result=0; echo "zookeeper returned imok!"; else echo waiting for zookeeper to be ready; sleep 1; fi; done; echo "Success: zookeeper is up"']
{{- end -}}

{{/* Init container that waits for controller to be ready */}}
{{- define "openwhisk.readiness.waitForController" -}}
- name: "wait-for-controller"
  image: "{{- .Values.docker.registry.name -}}{{- .Values.busybox.imageName -}}:{{- .Values.busybox.imageTag -}}"
  imagePullPolicy: "IfNotPresent"
  env:
  - name: "READINESS_URL"
    value: http://{{ include "openwhisk.controller_host" . }}:{{ .Values.controller.port }}/ping
  command: ["sh", "-c", "result=1; until [ $result -eq 0 ]; do echo 'Checking controller readiness'; wget -T 5 --spider $READINESS_URL; result=$?; sleep 1; done; echo 'Success: controller is ready'"]
{{- end -}}

{{/* Init container that waits for scheduler to be ready */}}
{{- define "openwhisk.readiness.waitForScheduler" -}}
- name: "wait-for-scheduler"
  image: "{{- .Values.docker.registry.name -}}{{- .Values.busybox.imageName -}}:{{- .Values.busybox.imageTag -}}"
  imagePullPolicy: "IfNotPresent"
  env:
  - name: "READINESS_URL"
    value: http://{{ include "openwhisk.scheduler_host" . }}:{{ .Values.scheduler.endpoints.port }}/ping
  command: ["sh", "-c", "result=1; until [ $result -eq 0 ]; do echo 'Checking scheduler readiness'; wget -T 5 --spider $READINESS_URL; result=$?; sleep 1; done; echo 'Success: scheduler is ready'"]
{{- end -}}

{{/* Init container that waits for at least 1 healthy invoker */}}
{{- define "openwhisk.readiness.waitForHealthyInvoker" -}}
- name: "wait-for-healthy-invoker"
  image: "{{- .Values.docker.registry.name -}}{{- .Values.busybox.imageName -}}:{{- .Values.busybox.imageTag -}}"
  imagePullPolicy: "IfNotPresent"
  env:
  - name: "READINESS_URL"
    value: "http://{{ include "openwhisk.controller_host" . }}:{{ .Values.controller.port }}/invokers/healthy/count"
  command: ["sh", "-c", "echo 0 > /tmp/count.txt; while true; do echo 'waiting for healthy invoker'; wget -T 5 -qO /tmp/count.txt --no-check-certificate \"$READINESS_URL\"; NUM_HEALTHY_INVOKERS=$(cat /tmp/count.txt); if [ $NUM_HEALTHY_INVOKERS -gt 0 ]; then echo \"Success: there are $NUM_HEALTHY_INVOKERS healthy invokers\"; break; fi; echo '...not ready yet; sleeping 3 seconds before retry'; sleep 3; done;"]
{{- end -}}

{{/* Init container that waits for ElasticSearch to be ready */}}
{{- define "openwhisk.readiness.waitForElasticSearch" -}}
- name: "wait-for-elasticsearch"
  image: "{{- .Values.docker.registry.name -}}{{- .Values.busybox.imageName -}}:{{- .Values.busybox.imageTag -}}"
  imagePullPolicy: "IfNotPresent"
  env:
  - name: "READINESS_URL"
    value: {{ .Values.elasticsearch.protocol  }}://{{ include "openwhisk.elasticsearch_zero_host" . }}:{{ .Values.elasticsearch.httpPort }}/_cluster/health
  command: ["sh", "-c", "while true; do echo 'checking ElasticSearch readiness'; wget -T 5 --spider $READINESS_URL --header=\"Authorization: Basic {{ include "openwhisk.elasticsearch_authentication" . | b64enc }}\"; result=$?; if [ $result -eq 0 ]; then echo 'Success: ElasticSearch is ready!'; break; fi; echo '...not ready yet; sleeping 3 seconds before retry'; sleep 3; done;"]
{{- end -}}
