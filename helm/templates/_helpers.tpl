# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements; and to You under the Apache License, Version 2.0.

{{/* hostname for apigateway */}}
{{- define "apigw_host" -}}
{{ .Values.apigw.name }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{/* hostname for controller */}}
{{- define "controller_host" -}}
{{ .Values.controller.name }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{/* hostname for database */}}
{{- define "db_host" -}}
{{ .Values.db.name }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{/* hostname for kafka */}}
{{- define "kafka_host" -}}
{{ .Values.kafka.name }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{/* hostname for zookeeper */}}
{{- define "zookeeper_host" -}}
{{ .Values.zookeeper.name }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{/* Runtimes manifest */}}
{{- define "runtimes_manifest" -}}
{{ .Files.Get .Values.whisk.runtimes | quote }}
{{- end -}}

{{/* Environment variables required for accessing CouchDB from a pod */}}
{{- define "whisk.dbEnvVars" -}}
- name: "CONFIG_whisk_couchdb_username"
  value: {{ .Values.db.auth.username | quote }}
- name: "CONFIG_whisk_couchdb_password"
  value: {{ .Values.db.auth.password | quote }}
- name: "CONFIG_whisk_couchdb_port"
  value: {{ .Values.db.port | quote}}
- name: "CONFIG_whisk_couchdb_protocol"
  value: {{ .Values.db.protocol | quote }}
- name: "CONFIG_whisk_couchdb_host"
  value: {{ include "db_host" . | quote }}
- name: "CONFIG_whisk_couchdb_provider"
  value: {{ .Values.db.provider | quote }}
- name: "CONFIG_whisk_couchdb_databases_WhiskActivation"
  value: {{ .Values.db.activationsTable | quote }}
- name: "CONFIG_whisk_couchdb_databases_WhiskEntity"
  value: {{ .Values.db.actionsTable | quote }}
- name: "CONFIG_whisk_couchdb_databases_WhiskAuth"
  value: {{ .Values.db.authsTable | quote }}
{{- end -}}
