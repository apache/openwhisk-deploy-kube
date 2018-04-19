{{/* Set controller service name */}}
{{- define "controller_service_name" -}}
{{ .Values.global.controllerServiceName | default "controller" | quote }}
{{- end -}}

{{/* Set controller statefulset name */}}
{{- define "controller_statefulset_name" -}}
{{ .Values.global.controllerStatefulSetName | default "controller" | quote }}
{{- end -}}

{{/* Set controller port */}}
{{- define "controller_port" -}}
{{ .Values.global.controllerPort | default 8080 }}
{{- end -}}

{{/* Set activations table */}}
{{- define "activations_table" -}}
{{ .Values.activationsTable | default "test_activations" | quote }}
{{- end -}}

{{/* Set activations table */}}
{{- define "activations_table_unquoted" -}}
{{ .Values.activationsTable | default "test_activations" }}
{{- end -}}

{{/* Set actions table */}}
{{- define "actions_table" -}}
{{ .Values.actionsTable | default "test_whisks" | quote }}
{{- end -}}

{{/* Set auths table */}}
{{- define "auths_table" -}}
{{ .Values.authTable | default "test_subjects" | quote }}
{{- end -}}

{{/* Set invoker "deployment" name */}}
{{- define "invoker_deployment_name" -}}
{{ .Values.invokerDeploymentName | default "invoker" | quote }}
{{- end -}}

{{/* Generate kafka url without port */}}
{{- define "kafka_url_without_port" -}}
{{ .Values.global.kafkaServiceName | default "kafka" }}.{{ .Release.Namespace }}
{{- end -}}


{{/* Set Couchdb user name */}}
{{- define "couchdb_username" -}}
{{ .Values.global.couchdbUserName | default "whisk_admin" | quote }}
{{- end -}}

{{/* Set Couchdb password */}}
{{- define "couchdb_password" -}}
{{ .Values.global.couchdbPassword | default "some_passw0rd" | quote }}
{{- end -}}

{{/* Generate Couchdb url without port */}}
{{- define "couchdb_url_without_port" -}}
{{ .Values.global.couchdbServiceName | default "couchdb" }}.{{ .Release.Namespace }}
{{- end -}}

{{/* Set Couchdb port */}}
{{- define "couchdb_port" -}}
{{ .Values.global.couchdb_port | default 5984 }}
{{- end -}}

{{/* Set API Gateway service name */}}
{{- define "apigateway_service_name" -}}
{{ .Values.serviceName | default "apigateway" | quote }}
{{- end -}}

{{/* Set API Gateway management port */}}
{{- define "apigateway_mgmt_port" -}}
{{ .Values.mgmtPort | default 8080 }}
{{- end -}}

{{/* Set API Gateway API port */}}
{{- define "apigateway_api_port" -}}
{{ .Values.apiPort | default 9000 }}
{{- end -}}

{{/* Set API Gateway deployment name */}}
{{- define "apigateway_deployment_name" -}}
{{ .Values.deploymentName | default "apigateway" | quote }}
{{- end -}}

{{/* Runtimes manifest */}}
{{- define "runtimes_manifest" -}}
{{- if .Values.global.travis -}}
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