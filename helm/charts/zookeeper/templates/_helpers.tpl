{{/* Get deployment name */}}
{{- define "zookeeper_deployment_name" -}}
{{ .Values.deploymentName | default "zookeeper" | quote }}
{{- end -}}

{{/* Get service name */}}
{{- define "zookeeper_service_name" -}}
{{ .Values.global.zookeepserServiceName | default "zookeeper" | quote }}
{{- end -}}

{{/* Set zookeeper port */}}
{{- define "zookeeper_port" -}}
{{ .Values.global.zookeeperPort | default 2181 }}
{{- end -}}

{{/* Set server port */}}
{{- define "zookeeper_server_port" -}}
{{ .Values.serverPort | default 2888 }}
{{- end -}}

{{/* Set leader election port */}}
{{- define "zookeeper_leader_election_port" -}}
{{ .Values.leaderElectionPort | default 3888 }}
{{- end -}}
