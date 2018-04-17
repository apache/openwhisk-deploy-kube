{ Generate controller url */}}
{{- define "controller_url" -}}
http://{{ .Values.global.controllerStatefulSetName | default "controller" }}-0.{{ .Values.global.controllerServiceName | default "controller" }}.{{ .Release.Namespace }}:{{ .Values.global.controllerPort | default 8080 }}
{{- end -}}

{ Generate controller url witout port */}}
{{- define "controller_url_without_port" -}}
{{ .Values.global.controllerStatefulSetName | default "controller" }}-0.{{ .Values.global.controllerServiceName | default "controller" }}.{{ .Release.Namespace }}
{{- end -}}

{{/* Set deployment name */}}
{{- define "nginx_deployment_name" -}}
{{ .Values.deploymentName | default "nginx" | quote }}
{{- end -}}

{{/* Set service name */}}
{{- define "nginx_service_name" -}}
{{ .Values.serviceName | default "nginx" | quote }}
{{- end -}}

{{/* Set secret name */}}
{{- define "nginx_secret_name" -}}
{{ .Values.secretName | default "nginx" | quote }}
{{- end -}}

{{/* Set configmap name */}}
{{- define "nginx_configmap_name" -}}
{{ .Values.configmapName | default "nginx" | quote }}
{{- end -}}

{{/* Set http port */}}
{{- define "nginx_http_port" -}}
{{ .Values.httpPort | default 80 }}
{{- end -}}

{{/* Set https port */}}
{{- define "nginx_https_port" -}}
{{ .Values.httpsPort | default 443 }}
{{- end -}}

{{/* Set https admin port */}}
{{- define "nginx_https_admin_port" -}}
{{ .Values.httpsAdminPort | default 8443 }}
{{- end -}}

{{/* Set controller statefulset name */}}
{{- define "controller_statefulset_name" -}}
{{ .Values.global.controllerStatefulSetName | default "controller" }}
{{- end -}}
