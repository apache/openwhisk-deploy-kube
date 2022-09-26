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

{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "openwhisk.fullname" -}}
{{- $name := default .Chart.Name -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* boilerplate labels */}}
{{- define "openwhisk.label_boilerplate" -}}
heritage: {{ .Release.Service | quote }}
release: {{ .Release.Name | quote }}
chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
app: {{ template "openwhisk.fullname" . }}
{{- end -}}

{{/* hostname for apigateway */}}
{{- define "openwhisk.apigw_host" -}}
{{ .Release.Name }}-apigateway.{{ .Release.Namespace }}.svc.{{ .Values.k8s.domain }}
{{- end -}}

{{/* hostname for controller */}}
{{- define "openwhisk.controller_host" -}}
{{ .Release.Name }}-controller.{{ .Release.Namespace }}.svc.{{ .Values.k8s.domain }}
{{- end -}}

{{/* hostname for scheduler */}}
{{- define "openwhisk.scheduler_host" -}}
{{ .Release.Name }}-scheduler.{{ .Release.Namespace }}.svc.{{ .Values.k8s.domain }}
{{- end -}}

{{/* hostname for database */}}
{{- define "openwhisk.db_host" -}}
{{- if .Values.db.external -}}
{{ .Values.db.host }}
{{- else -}}
{{ .Release.Name }}-couchdb.{{ .Release.Namespace }}.svc.{{ .Values.k8s.domain }}
{{- end -}}
{{- end -}}

{{- define "openwhisk.db_authentication" -}}
{{ .Values.db.auth.username }}:{{ .Values.db.auth.password }}
{{- end -}}

{{- define "openwhisk.elasticsearch_authentication" -}}
{{ .Values.elasticsearch.username }}:{{ .Values.elasticsearch.password }}
{{- end -}}

{{/* hostname for redis */}}
{{- define "openwhisk.redis_host" -}}
{{- if .Values.redis.external -}}
{{ .Values.redis.host }}
{{- else -}}
{{ .Release.Name }}-redis.{{ .Release.Namespace }}.svc.{{ .Values.k8s.domain }}
{{- end -}}
{{- end -}}

{{/* hostname for etcd */}}
{{- define "openwhisk.etcd_host" -}}
{{- if .Values.etcd.external -}}
{{ .Values.etcd.host }}
{{- else -}}
{{ .Release.Name }}-etcd.{{ .Release.Namespace }}.svc.{{ .Values.k8s.domain }}
{{- end -}}
{{- end -}}

{{/* client connection string for zookeeper cluster (server1:port,server2:port, ... serverN:port)*/}}
{{- define "openwhisk.zookeeper_connect" -}}
{{- if .Values.zookeeper.external -}}
{{ .Values.zookeeper.connect_string }}
{{- else -}}
{{- $zkname := printf "%s-zookeeper" .Release.Name }}
{{- $zkport := .Values.zookeeper.port }}
{{- $kubeDomain := .Values.k8s.domain }}
{{- range $i, $e := until (int .Values.zookeeper.replicaCount) -}}{{ if ne $i 0 }},{{ end }}{{ $zkname }}-{{ . }}.{{ $zkname }}.{{ $.Release.Namespace }}.svc.{{ $kubeDomain }}:{{ $zkport }}{{ end }}
{{- end -}}
{{- end -}}

{{/* host name for server.0 in zookeeper cluster */}}
{{- define "openwhisk.zookeeper_zero_host" -}}
{{- if .Values.zookeeper.external -}}
{{ .Values.zookeeper.host }}
{{- else -}}
{{- $zkname := printf "%s-zookeeper" .Release.Name }}
{{ $zkname }}-0.{{ $zkname }}.{{ $.Release.Namespace }}.svc.{{ .Values.k8s.domain }}
{{- end -}}
{{- end -}}

{{/* client connection string for kafka cluster (server1:port,server2:port, ... serverN:port)*/}}
{{- define "openwhisk.kafka_connect" -}}
{{- if .Values.kafka.external -}}
{{ .Values.kafka.connect_string }}
{{- else -}}
{{- $kname := printf "%s-kafka" .Release.Name }}
{{- $kport := .Values.kafka.port }}
{{- $kubeDomain := .Values.k8s.domain }}
{{- range $i, $e := until (int .Values.kafka.replicaCount) -}}{{ if ne $i 0 }},{{ end }}{{ $kname }}-{{ . }}.{{ $kname }}.{{ $.Release.Namespace }}.svc.{{ $kubeDomain }}:{{ $kport }}{{ end }}
{{- end -}}
{{- end -}}

{{/* Runtimes manifest */}}
{{- define "openwhisk.runtimes_manifest" -}}
{{ .Files.Get .Values.whisk.runtimes | quote }}
{{- end -}}

{{/* Whisk Config */}}
{{- define "openwhisk.whiskconfig" -}}
{{ .Files.Get .Values.metrics.whiskconfigFile | b64enc }}
{{- end -}}

{{/* Environment variables required for accessing CouchDB from a pod */}}
{{- define "openwhisk.dbEnvVars" -}}
- name: "CONFIG_whisk_couchdb_username"
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-db.auth
      key: db_username
- name: "CONFIG_whisk_couchdb_password"
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-db.auth
      key: db_password
- name: "CONFIG_whisk_couchdb_port"
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-db.config
      key: db_port
- name: "CONFIG_whisk_couchdb_protocol"
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-db.config
      key: db_protocol
- name: "CONFIG_whisk_couchdb_host"
  value: {{ include "openwhisk.db_host" . | quote }}
- name: "CONFIG_whisk_couchdb_provider"
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-db.config
      key: db_provider
- name: "CONFIG_whisk_couchdb_databases_WhiskActivation"
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-db.config
      key: db_whisk_activations
- name: "CONFIG_whisk_couchdb_databases_WhiskEntity"
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-db.config
      key: db_whisk_actions
- name: "CONFIG_whisk_couchdb_databases_WhiskAuth"
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-db.config
      key: db_whisk_auths
{{- end -}}

{{/* Environment variables for specifying action limits */}}
{{- define "openwhisk.limitsEnvVars" -}}
- name: "LIMITS_ACTIONS_INVOKES_PERMINUTE"
  value: {{ .Values.whisk.limits.actionsInvokesPerminute | quote }}
- name: "LIMITS_ACTIONS_INVOKES_CONCURRENT"
  value: {{ .Values.whisk.limits.actionsInvokesConcurrent | quote }}
- name: "LIMITS_TRIGGERS_FIRES_PERMINUTE"
  value: {{ .Values.whisk.limits.triggersFiresPerminute | quote }}
- name: "LIMITS_ACTIONS_SEQUENCE_MAXLENGTH"
  value: {{ .Values.whisk.limits.actionsSequenceMaxlength | quote }}
- name: "CONFIG_whisk_timeLimit_min"
  value: {{ .Values.whisk.limits.actions.time.min | quote }}
- name: "CONFIG_whisk_timeLimit_max"
  value: {{ .Values.whisk.limits.actions.time.max | quote }}
- name: "CONFIG_whisk_timeLimit_std"
  value: {{ .Values.whisk.limits.actions.time.std | quote }}
- name: "CONFIG_whisk_memory_min"
  value: {{ .Values.whisk.limits.actions.memory.min | quote }}
- name: "CONFIG_whisk_memory_max"
  value: {{ .Values.whisk.limits.actions.memory.max | quote }}
- name: "CONFIG_whisk_memory_std"
  value: {{ .Values.whisk.limits.actions.memory.std | quote }}
- name: "CONFIG_whisk_concurrencyLimit_min"
  value: {{ .Values.whisk.limits.actions.concurrency.min | quote }}
- name: "CONFIG_whisk_concurrencyLimit_max"
  value: {{ .Values.whisk.limits.actions.concurrency.max | quote }}
- name: "CONFIG_whisk_concurrencyLimit_std"
  value: {{ .Values.whisk.limits.actions.concurrency.std | quote }}
- name: "CONFIG_whisk_logLimit_min"
  value: {{ .Values.whisk.limits.actions.log.min | quote }}
- name: "CONFIG_whisk_logLimit_max"
  value: {{ .Values.whisk.limits.actions.log.max | quote }}
- name: "CONFIG_whisk_logLimit_std"
  value: {{ .Values.whisk.limits.actions.log.std | quote }}
- name: "CONFIG_whisk_activation_payload_max"
  value: {{ .Values.whisk.limits.activation.payload.max | quote }}
{{- end -}}

{{/* Environment variables for configuring etcd */}}
{{- define "openwhisk.etcdConfigEnvVars" -}}
- name: "CONFIG_whisk_cluster_name"
  value: {{ .Values.etcd.clusterName | quote }}
- name: "CONFIG_whisk_etcd_hosts"
  value: {{ include "openwhisk.etcd_host" . }}:{{ .Values.etcd.port }}
- name: "CONFIG_whisk_etcd_lease_timeout"
  value: {{ .Values.etcd.leaseTimeout | quote }}
- name: "CONFIG_whisk_etcd_pool_threads"
  value: {{ .Values.etcd.poolThreads | quote }}
{{- end -}}

{{/* Environment variables for configuring kafka topics */}}
{{- define "openwhisk.kafkaConfigEnvVars" -}}
- name: "CONFIG_whisk_kafka_replicationFactor"
  value: {{ .Values.whisk.kafka.replicationFactor | quote }}
- name: "CONFIG_whisk_kafka_topics_prefix"
  value: {{ .Values.whisk.kafka.topics.prefix | quote }}
- name: "CONFIG_whisk_kafka_topics_cacheInvalidation_retentionBytes"
  value: {{ .Values.whisk.kafka.topics.cacheInvalidation.retentionBytes | quote }}
- name: "CONFIG_whisk_kafka_topics_cacheInvalidation_retentionMs"
  value: {{ .Values.whisk.kafka.topics.cacheInvalidation.retentionMs | quote }}
- name: "CONFIG_whisk_kafka_topics_cacheInvalidation_segmentBytes"
  value: {{ .Values.whisk.kafka.topics.cacheInvalidation.segmentBytes | quote }}
- name: "CONFIG_whisk_kafka_topics_completed_retentionBytes"
  value: {{ .Values.whisk.kafka.topics.completed.retentionBytes | quote }}
- name: "CONFIG_whisk_kafka_topics_completed_retentionMs"
  value: {{ .Values.whisk.kafka.topics.completed.retentionMs | quote }}
- name: "CONFIG_whisk_kafka_topics_completed_segmentBytes"
  value: {{ .Values.whisk.kafka.topics.completed.segmentBytes | quote }}
- name: "CONFIG_whisk_kafka_topics_events_retentionBytes"
  value: {{ .Values.whisk.kafka.topics.events.retentionBytes | quote }}
- name: "CONFIG_whisk_kafka_topics_events_retentionMs"
  value: {{ .Values.whisk.kafka.topics.events.retentionMs | quote }}
- name: "CONFIG_whisk_kafka_topics_events_segmentBytes"
  value: {{ .Values.whisk.kafka.topics.events.segmentBytes | quote }}
- name: "CONFIG_whisk_kafka_topics_health_retentionBytes"
  value: {{ .Values.whisk.kafka.topics.health.retentionBytes | quote }}
- name: "CONFIG_whisk_kafka_topics_health_retentionMs"
  value: {{ .Values.whisk.kafka.topics.health.retentionMs | quote }}
- name: "CONFIG_whisk_kafka_topics_health_segmentBytes"
  value: {{ .Values.whisk.kafka.topics.health.segmentBytes | quote }}

- name: "CONFIG_whisk_kafka_topics_invoker_retentionBytes"
  value: {{ .Values.whisk.kafka.topics.invoker.retentionBytes | quote }}
- name: "CONFIG_whisk_kafka_topics_invoker_retentionMs"
  value: {{ .Values.whisk.kafka.topics.invoker.retentionMs | quote }}
- name: "CONFIG_whisk_kafka_topics_invoker_segmentBytes"
  value: {{ .Values.whisk.kafka.topics.invoker.segmentBytes | quote }}

- name: "CONFIG_whisk_kafka_topics_scheduler_retentionBytes"
  value: {{ .Values.whisk.kafka.topics.scheduler.retentionBytes | quote }}
- name: "CONFIG_whisk_kafka_topics_scheduler_retentionMs"
  value: {{ .Values.whisk.kafka.topics.scheduler.retentionMs | quote }}
- name: "CONFIG_whisk_kafka_topics_scheduler_segmentBytes"
  value: {{ .Values.whisk.kafka.topics.scheduler.segmentBytes | quote }}

- name: "CONFIG_whisk_kafka_topics_creationAck_retentionBytes"
  value: {{ .Values.whisk.kafka.topics.creationAck.retentionBytes | quote }}
- name: "CONFIG_whisk_kafka_topics_creationAck_retentionMs"
  value: {{ .Values.whisk.kafka.topics.creationAck.retentionMs | quote }}
- name: "CONFIG_whisk_kafka_topics_creationAck_segmentBytes"
  value: {{ .Values.whisk.kafka.topics.creationAck.segmentBytes | quote }}
{{- end -}}

{{/* tlssecretname for ingress */}}
{{- define "openwhisk.tls_secret_name" -}}
{{ .Values.whisk.ingress.tls.secretname | default "ow-ingress-tls-secret" | quote }}
{{- end -}}

{{/* Create imagePullSecrets for private docker-registry*/}}
{{- define "openwhisk.dockerRegistrySecret" -}}
{{- if ne .Values.docker.registry.name "" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.docker.registry.name (printf "%s:%s" .Values.docker.registry.username .Values.docker.registry.password | b64enc) | b64enc }}
{{- end }}
{{- end -}}

{{/* ImagePullSecrets in pods and job*/}}
{{- define "openwhisk.docker.imagePullSecrets" -}}
{{- if ne .Values.docker.registry.name "" }}
imagePullSecrets:
- name: {{ .Release.Name }}-private-registry.auth
{{- end }}
{{- end -}}

{{/* Environment variables required for Lean OW configuration */}}
{{- define "openwhisk.lean.provider" -}}
{{- if .Values.controller.lean -}}
- name: "CONFIG_whisk_spi_MessagingProvider"
  value: "org.apache.openwhisk.connector.lean.LeanMessagingProvider"
- name: "CONFIG_whisk_spi_LoadBalancerProvider"
  value: "org.apache.openwhisk.core.loadBalancer.LeanBalancer"
{{- end -}}
{{- end -}}

{{/* Environment variables required for invoker API HOST configuration */}}
{{- define "openwhisk.invoker.apihost" -}}
- name: "WHISK_API_HOST_PROTO"
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-whisk.config
      key: whisk_internal_api_host_proto
- name: "WHISK_API_HOST_PORT"
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-whisk.config
      key: whisk_internal_api_host_port
- name: "WHISK_API_HOST_NAME"
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-whisk.config
      key: whisk_internal_api_host_name
{{- end -}}

{{/* Environment variables required for invoker containerpool/containerfactory configuration */}}
{{- define "openwhisk.invoker.containerconfig" -}}
- name: "CONFIG_whisk_docker_containerFactory_useRunc"
  value: {{ .Values.invoker.containerFactory.useRunc | quote }}
- name: "CONFIG_whisk_containerPool_userMemory"
  value: {{ .Values.whisk.containerPool.userMemory | quote }}
{{- end -}}

{{/* Environment variables required for invoker volumes configuration */}}
{{- define "openwhisk.invoker.volumes" -}}
{{- if eq .Values.invoker.containerFactory.impl "docker" }}
      volumes:
{{ include "openwhisk.docker_volumes" . | indent 6 }}
      - name: scripts-dir
        configMap:
          name: {{ .Release.Name }}-invoker-scripts
{{- end }}
{{- end }}

{{/* Environment variables required for invoker volumes configuration */}}
{{- define "openwhisk.invoker.volume_mounts" -}}
{{- if (eq .Values.invoker.containerFactory.impl "docker") }}
        volumeMounts:
{{ include "openwhisk.docker_volume_mounts" . | indent 8 }}
{{- if .Values.invoker.containerFactory.networkConfig.dns.inheritInvokerConfig }}
        - name: scripts-dir
          mountPath: "/invoker-scripts/configureDNS.sh"
          subPath: "configureDNS.sh"
{{- end }}
{{- end }}
{{- end }}

{{/* invoker additional options */}}
{{- define "openwhisk.invoker.add_opts" -}}
{{- if eq .Values.invoker.containerFactory.impl "docker" -}}
-Dwhisk.spi.ContainerFactoryProvider=org.apache.openwhisk.core.containerpool.docker.DockerContainerFactoryProvider
{{- else -}}
-Dkubernetes.master=https://$KUBERNETES_SERVICE_HOST -Dwhisk.spi.ContainerFactoryProvider=org.apache.openwhisk.core.containerpool.kubernetes.KubernetesContainerFactoryProvider
{{- end -}}
{{- end -}}

{{/* hostname for prometheus server */}}
{{- define "openwhisk.prometheus_server_host" -}}
{{ .Release.Name }}-prometheus-server.{{ .Release.Namespace }}.svc.{{ .Values.k8s.domain }}
{{- end -}}

{{/* hostname for grafana */}}
{{- define "openwhisk.grafana_host" -}}
{{ .Release.Name }}-grafana.{{ .Release.Namespace }}.svc.{{ .Values.k8s.domain }}
{{- end -}}

{{/* nginx cert */}}
{{- define "openwhisk.nginx_cert" -}}
{{- if .Values.nginx.certificate.external }}
{{ .Files.Get .Values.nginx.certificate.cert_file }}
{{- end -}}
{{- end -}}

{{/* nginx key */}}
{{- define "openwhisk.nginx_key" -}}
{{- if .Values.nginx.certificate.external }}
{{ .Files.Get .Values.nginx.certificate.key_file }}
{{- end -}}
{{- end -}}

{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "elasticsearch.name" -}}
{{- default .Chart.Name .Values.elasticsearch.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "elasticsearch.fullname" -}}
{{- $name := default .Chart.Name .Values.elasticsearch.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "elasticsearch.uname" -}}
{{- if empty .Values.elasticsearch.fullnameOverride -}}
{{- if empty .Values.elasticsearch.nameOverride -}}
{{ .Values.elasticsearch.clusterName }}-{{ .Values.elasticsearch.nodeGroup }}
{{- else -}}
{{ .Values.elasticsearch.nameOverride }}-{{ .Values.elasticsearch.nodeGroup }}
{{- end -}}
{{- else -}}
{{ .Values.elasticsearch.fullnameOverride }}
{{- end -}}
{{- end -}}

{{- define "elasticsearch.masterService" -}}
{{- if empty .Values.elasticsearch.masterServiceValue -}}
{{- if empty .Values.elasticsearch.fullnameOverride -}}
{{- if empty .Values.elasticsearch.nameOverride -}}
{{ .Values.elasticsearch.clusterName }}-master
{{- else -}}
{{ .Values.elasticsearch.nameOverride }}-master
{{- end -}}
{{- else -}}
{{ .Values.elasticsearch.fullnameOverride }}
{{- end -}}
{{- else -}}
{{ .Values.elasticsearch.masterServiceValue }}
{{- end -}}
{{- end -}}

{{- define "elasticsearch.endpoints" -}}
{{- $replicas := int (toString (.Values.elasticsearch.replicaCount)) }}
{{- $uname := printf "%s-elasticsearch" .Release.Name }}
  {{- range $i, $e := untilStep 0 $replicas 1 -}}
{{ $uname }}-{{ $i }},
  {{- end -}}
{{- end -}}

{{- define "elasticsearch.esMajorVersion" -}}
{{- if .Values.elasticsearch.esMajorVersionValue -}}
{{ .Values.elasticsearch.esMajorVersionValue }}
{{- else -}}
{{- $version := int (index (.Values.elasticsearch.imageTag | splitList ".") 0) -}}
  {{- if and (contains "docker.elastic.co/elasticsearch/elasticsearch" .Values.elasticsearch.image) (not (eq $version 0)) -}}
{{ $version }}
  {{- else -}}
7
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for statefulset.
*/}}
{{- define "elasticsearch.statefulset.apiVersion" -}}
{{- if semverCompare "<1.9-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "apps/v1beta2" -}}
{{- else -}}
{{- print "apps/v1" -}}
{{- end -}}
{{- end -}}

{{- define "openwhisk.elasticsearch_connect" -}}
{{- if .Values.elasticsearch.external -}}
{{ .Values.elasticsearch.connect_string }}
{{- else -}}
{{- $kname := printf "%s-elasticsearch" .Release.Name }}
{{- $kport := .Values.elasticsearch.httpPort }}
{{- $kubeDomain := .Values.k8s.domain }}
{{- range $i, $e := until (int .Values.elasticsearch.replicaCount) -}}{{ if ne $i 0 }},{{ end }}{{ $kname }}-{{ . }}.{{ $kname }}.{{ $.Release.Namespace }}.svc.{{ $kubeDomain }}:{{ $kport }}{{ end }}
{{- end -}}
{{- end -}}

{{/* host name for server.0 in elasticsearch cluster */}}
{{- define "openwhisk.elasticsearch_zero_host" -}}
{{- if .Values.elasticsearch.external -}}
{{ .Values.elasticsearch.host }}
{{- else -}}
{{ .Release.Name }}-elasticsearch-0.{{ .Release.Name }}-elasticsearch.{{ .Release.Namespace }}.svc.{{ .Values.k8s.domain }}
{{- end -}}
{{- end -}}
