{{/* Get statefulset name */}}
{{- define "kafka_statefulset_name" -}}
{{ .Values.statefulsetName | default "kafka" | quote }}
{{- end -}}

{{/* Get service name */}}
{{- define "kafka_service_name" -}}
{{ .Values.global.kafkaServiceName | default "kafka" | quote }}
{{- end -}}

{{/* Generate Zookeeper service address */}}
{{- define "zookeeper_service_address" -}}
{{ .Values.global.zookeeperServiceName }}.{{ .Release.Namespace }}:{{ .Values.global.zookeeperPort }}
{{- end -}}

{{/* Get kafka port */}}
{{- define "kafka_port" -}}
{{ .Values.global.kafkaPort | default 9092 }}
{{- end -}}
