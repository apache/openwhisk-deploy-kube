{{/* Set Couchdb service name */}}
{{- define "couchdb_service_name" -}}
{{ .Values.global.couchdbServiceName | default "couchdb" | quote }}
{{- end -}}

{{/* Set Couchdb port */}}
{{- define "couchdb_port" -}}
{{ .Values.global.couchdbPort | default 5984 }}
{{- end -}}

{{/* Set Couchdb deployment name */}}
{{- define "couchdb_deployment_name" -}}
{{ .Values.deploymentName | default "couchdb" | quote }}
{{- end -}}

{{/* Set Couchdb PVC name */}}
{{- define "couchdb_pvc_name" -}}
{{ .Values.pvcName | default "couchdb-pvc" | quote }}
{{- end -}}
