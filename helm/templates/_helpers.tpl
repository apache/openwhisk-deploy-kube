{{/* Generate kafka url without port */}}
{{- define "kafka_url_without_port" -}}
{{ .Values.kafka.name }}.{{ .Release.Namespace }}
{{- end -}}

{{/* Generate Zookeeper service address */}}
{{- define "zookeeper_service_address" -}}
{{ .Values.zookeeper.name }}.{{ .Release.Namespace }}:{{ .Values.zookeeper.port }}
{{- end -}}

{{/* Generate Couchdb url without port */}}
{{- define "couchdb_url_without_port" -}}
{{ .Values.db.name }}.{{ .Release.Namespace }}
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
  value: {{ .Values.db.auth.username | quote }}
- name: "CONFIG_whisk_couchdb_password"
  value: {{ .Values.db.auth.password | quote }}
- name: "CONFIG_whisk_couchdb_port"
  value: {{ .Values.db.port | quote}}
- name: "CONFIG_whisk_couchdb_protocol"
  value: "http"
- name: "CONFIG_whisk_couchdb_host"
  value: {{ include "couchdb_url_without_port" . | quote }}
- name: "CONFIG_whisk_couchdb_provider"
  value: "CouchDB"
- name: "CONFIG_whisk_couchdb_databases_WhiskActivation"
  value: {{ .Values.db.activationsTable | quote }}
- name: "CONFIG_whisk_couchdb_databases_WhiskEntity"
  value: {{ .Values.db.actionsTable | quote }}
- name: "CONFIG_whisk_couchdb_databases_WhiskAuth"
  value: {{ .Values.db.authsTable | quote }}
{{- end -}}
