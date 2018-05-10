{{/* Set controller service name */}}
{{- define "controller_service_name" -}}
{{ .Values.controller.serviceName | quote }}
{{- end -}}

{{/* Set controller statefulset name */}}
{{- define "controller_statefulset_name" -}}
{{ .Values.controller.statefulSetName | quote }}
{{- end -}}

{{/* Set controller port */}}
{{- define "controller_port" -}}
{{ .Values.controller.port }}
{{- end -}}

{{/* Set activations table */}}
{{- define "activations_table" -}}
{{ .Values.db.activationsTable | quote }}
{{- end -}}

{{/* Set activations table */}}
{{- define "activations_table_unquoted" -}}
{{ .Values.db.activationsTable }}
{{- end -}}

{{/* Set actions table */}}
{{- define "actions_table" -}}
{{ .Values.db.actionsTable | quote }}
{{- end -}}

{{/* Set auths table */}}
{{- define "auths_table" -}}
{{ .Values.db.authsTable | quote }}
{{- end -}}

{{/* Set invoker "deployment" name */}}
{{- define "invoker_deployment_name" -}}
{{ .Values.invokerDeploymentName | quote }}
{{- end -}}

{{/* Generate kafka url without port */}}
{{- define "kafka_url_without_port" -}}
{{ .Values.kafka.serviceName }}.{{ .Release.Namespace }}
{{- end -}}

{{/* Generate Zookeeper service address */}}
{{- define "zookeeper_service_address" -}}
{{ .Values.zookeeper.serviceName }}.{{ .Release.Namespace }}:{{ .Values.zookeeper.port }}
{{- end -}}

{{/* Set Couchdb user name */}}
{{- define "couchdb_username" -}}
{{ .Values.db.auth.username | quote }}
{{- end -}}

{{/* Set Couchdb password */}}
{{- define "couchdb_password" -}}
{{ .Values.db.auth.password | quote }}
{{- end -}}

{{/* Generate Couchdb url without port */}}
{{- define "couchdb_url_without_port" -}}
{{ .Values.db.serviceName }}.{{ .Release.Namespace }}
{{- end -}}

{{/* Set Couchdb port */}}
{{- define "couchdb_port" -}}
{{ .Values.db.port }}
{{- end -}}

{{/* Set API Gateway service name */}}
{{- define "apigateway_service_name" -}}
{{ .Values.apigw.serviceName | quote }}
{{- end -}}

{{/* Set API Gateway management port */}}
{{- define "apigateway_mgmt_port" -}}
{{ .Values.apigw.mgmtPort }}
{{- end -}}

{{/* Set API Gateway API port */}}
{{- define "apigateway_api_port" -}}
{{ .Values.apigw.apiPort }}
{{- end -}}

{{/* Set API Gateway deployment name */}}
{{- define "apigateway_deployment_name" -}}
{{ .Values.apigw.deploymentName | quote }}
{{- end -}}

{{/* Runtimes manifest */}}
{{- define "runtimes_manifest" -}}
{{- if .Values.travis -}}
{{ .Files.Get "runtimes-minimal-travis.json" | quote }}
{{- else -}}
{{ .Files.Get "runtimes.json" | quote }}
{{- end -}}
{{- end -}}

{{/* Environment variables required for accessing CouchDB */}}
{{- define "whisk.dbEnvVars" -}}
- name: "CONFIG_whisk_couchdb_username"
  value: {{ template "couchdb_username" . }}
- name: "CONFIG_whisk_couchdb_password"
  value: {{ template "couchdb_password" . }}
- name: "CONFIG_whisk_couchdb_port"
  value: {{ include "couchdb_port" . | quote}}
- name: "CONFIG_whisk_couchdb_protocol"
  value: "http"
- name: "CONFIG_whisk_couchdb_host"
  value: {{ include "couchdb_url_without_port" . | quote }}
- name: "CONFIG_whisk_couchdb_provider"
  value: "CouchDB"
- name: "CONFIG_whisk_couchdb_databases_WhiskActivation"
  value: {{ template "activations_table" . }}
- name: "CONFIG_whisk_couchdb_databases_WhiskEntity"
  value: {{ template "actions_table" . }}
- name: "CONFIG_whisk_couchdb_databases_WhiskAuth"
  value: {{ template "auths_table" . }}
{{- end -}}