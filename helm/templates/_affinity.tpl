# This file defines template snippets for scheduler affinity and anti-affinity

{{/* Generic control-plane affinity */}}
{{- define "affinity.controlPlane" -}}
# prefer to not run on an invoker node (only prefer because of single node clusters)
nodeAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    preference:
      matchExpressions:
      - key: openwhisk-role
        operator: NotIn
        values:
        - {{ .Values.global.affinity.invokerNodeLabel }}
# prefer to run on a control-plane node
nodeAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 80
    preference:
      matchExpressions:
      - key: openwhisk-role
        operator: In
        values:
        - {{ .Values.global.affinity.controlPlaneNodeLabel }}
{{- end -}}


{{/* Invoker node affinity */}}
{{- define "affinity.invoker" -}}
# run only on nodes labeled with openwhisk-role={{ .Values.global.affinity.invokerNodeLabel }}
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
    - matchExpressions:
      - key: openwhisk-role
        operator: In
        values:
        - {{ .Values.global.affinity.invokerNodeLabel }}
{{- end -}}


{{/* Self anti-affinity */}}
{{- define "affinity.selfAntiAffinity" -}}
# Fault tolerance: prevent multiple instances of {{ . }} from running on the same node
podAntiAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchExpressions:
      - key: name
        operator: In
        values:
        - {{ . }}
    topologyKey: "kubernetes.io/hostname"
{{- end -}}