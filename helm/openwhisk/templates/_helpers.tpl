# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements; and to You under the Apache License, Version 2.0.

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

{{/* hostname for kafka */}}
{{- define "openwhisk.kafka_host" -}}
{{ .Release.Name }}-kafka.{{ .Release.Namespace }}.svc.{{ .Values.k8s.domain }}
{{- end -}}

{{/* hostname for redis */}}
{{- define "openwhisk.redis_host" -}}
{{ .Release.Name }}-redis.{{ .Release.Namespace }}.svc.{{ .Values.k8s.domain }}
{{- end -}}

{{/* client connection string for zookeeper cluster (server1:port server2:port ... serverN:port)*/}}
{{- define "openwhisk.zookeeper_connect" -}}
{{- $zkname := printf "%s-zookeeper" .Release.Name }}
{{- $zkport := .Values.zookeeper.port }}
{{- $kubeDomain := .Values.k8s.domain }}
{{- range $i, $e := until (int .Values.zookeeper.replicaCount) -}}{{ if ne $i 0 }},{{ end }}{{ $zkname }}-{{ . }}.{{ $zkname }}.{{ $.Release.Namespace }}.svc.{{ $kubeDomain }}:{{ $zkport }}{{ end }}
{{- end -}}

{{/* host name for server.0 in zookeeper cluster */}}
{{- define "openwhisk.zookeeper_zero_host" -}}
{{- $zkname := printf "%s-zookeeper" .Release.Name }}
{{ $zkname }}-0.{{ $zkname }}.{{ $.Release.Namespace }}.svc.{{ .Values.k8s.domain }}
{{- end -}}


{{/* Runtimes manifest */}}
{{- define "openwhisk.runtimes_manifest" -}}
{{ .Files.Get .Values.whisk.runtimes | quote }}
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

{{/* Environment variables for configuring kafka topics */}}
{{- define "openwhisk.kafkaConfigEnvVars" -}}
- name: "CONFIG_whisk_kafka_replicationFactor"
  value: {{ .Values.whisk.kafka.replicationFactor | quote }}
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
{{- end -}}

{{/* tlssecretname for ingress */}}
{{- define "openwhisk.tls_secret_name" -}}
{{ .Values.whisk.ingress.tls.secretname | default "ow-ingress-tls-secret" | quote }}
{{- end -}}
