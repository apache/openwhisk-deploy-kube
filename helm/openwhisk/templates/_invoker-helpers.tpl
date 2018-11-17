# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements; and to You under the Apache License, Version 2.0.

{{- define "openwhisk.docker_volumes" -}}
- name: cgroup
  hostPath:
    path: "/sys/fs/cgroup"
- name: runc
  hostPath:
    path: "/run/runc"
- name: dockerrootdir
  hostPath:
    {{- if .Values.invoker.containerFactory.dind }}
    path: "/dind/docker/containers"
    {{- else }}
    path: "/var/lib/docker/containers"
    {{- end }}
- name: dockersock
  hostPath:
    path: "/var/run/docker.sock"
{{- end -}}

{{- define "openwhisk.docker_volume_mounts" -}}
- name: cgroup
  mountPath: "/sys/fs/cgroup"
- name: runc
  mountPath: "/run/runc"
- name: dockersock
  mountPath: "/var/run/docker.sock"
- name: dockerrootdir
  mountPath: "/containers"
{{- end -}}

{{- define "openwhisk.docker_pull_runtimes" -}}
- name: docker-pull-runtimes
  imagePullPolicy: {{ .Values.utility.ansibleRunner.imagePullPolicy | quote }}
  image: "{{- .Values.utility.ansibleRunner.imageName -}}:{{- .Values.utility.ansibleRunner.imageTag -}}"
  volumeMounts:
  - name: dockersock
    mountPath: "/var/run/docker.sock"
  - name: task-dir
    mountPath: "/task/playbook.yml"
    subPath: "playbook.yml"
  env:
    # action runtimes
    - name: "RUNTIMES_MANIFEST"
      value: {{ template "openwhisk.runtimes_manifest" . }}
{{- if ne .Values.docker.registry.name "" }}
    - name: "RUNTIMES_REGISTRY"
      value: "{{- .Values.docker.registry.name -}}/"
    - name: "RUNTIMES_REGISTRY_USERNAME"
      valueFrom:
        secretKeyRef:
          name: docker.registry.auth
          key: docker_registry_username
    - name: "RUNTIMES_REGISTRY_PASSWORD"
      valueFrom:
        secretKeyRef:
          name: docker.registry.auth
          key: docker_registry_password
{{- end -}}
{{- end -}}

