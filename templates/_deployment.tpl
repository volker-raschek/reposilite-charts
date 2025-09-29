{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "reposilite.deployment.annotations" -}}
{{ include "reposilite.annotations" . }}
{{- if .Values.deployment.annotations }}
{{ toYaml .Values.deployment.annotations }}
{{- end }}
{{- end }}


{{/* env */}}

{{- define "reposilite.deployment.reposilite.env" -}}
{{- $env := .Values.deployment.reposilite.env | default list }}
{{- if .Values.persistentVolumeClaim.enabled }}
{{- $env = concat $env (list (dict "name" "REPOSILITE_DATA" "value" .Values.persistentVolumeClaim.path )) }}
{{- end }}

{{- if eq (include "reposilite.podMonitor.enabled" $) "true" }}
{{- $env = concat $env (list (dict "name" "REPOSILITE_PROMETHEUS_PATH" "value" .Values.prometheus.metrics.podMonitor.path )) }}
{{- end }}

{{- if eq (include "reposilite.serviceMonitor.enabled" $) "true" }}
{{- $env = concat $env (list (dict "name" "REPOSILITE_PROMETHEUS_PATH" "value" .Values.prometheus.metrics.serviceMonitor.path )) }}
{{- end }}

{{- if or (eq (include "reposilite.podMonitor.enabled" $ ) "true") (eq (include "reposilite.serviceMonitor.enabled" $ ) "true") -}}
{{- $env = concat $env (list (dict "name" "REPOSILITE_PROMETHEUS_USER" "valueFrom" (dict "secretKeyRef" (dict "name" (include "reposilite.secrets.prometheusBasicAuth.name" $) "key" (include "reposilite.secrets.prometheusBasicAuth.usernameKey" $))))) }}
{{- $env = concat $env (list (dict "name" "REPOSILITE_PROMETHEUS_PASSWORD" "valueFrom" (dict "secretKeyRef" (dict "name" (include "reposilite.secrets.prometheusBasicAuth.name" $) "key" (include "reposilite.secrets.prometheusBasicAuth.passwordKey" $))))) }}
{{- end }}

{{ toYaml (dict "env" $env) }}
{{- end -}}

{{/* image */}}

{{- define "reposilite.deployment.images.plugin.fqin" -}}
{{- $registry := .Values.deployment.pluginContainer.image.registry -}}
{{- $repository := .Values.deployment.pluginContainer.image.repository -}}
{{- $tag := default .Chart.AppVersion .Values.deployment.pluginContainer.image.tag -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- end -}}

{{- define "reposilite.deployment.images.reposilite.fqin" -}}
{{- $registry := .Values.deployment.reposilite.image.registry -}}
{{- $repository := .Values.deployment.reposilite.image.repository -}}
{{- $tag := default .Chart.AppVersion .Values.deployment.reposilite.image.tag -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- end -}}

{{/* labels */}}

{{- define "reposilite.deployment.labels" -}}
{{ include "reposilite.labels" . }}
{{- if .Values.deployment.labels }}
{{ toYaml .Values.deployment.labels }}
{{- end }}
{{- end }}

{{/* initContainers */}}

{{- define "reposilite.deployment.initContainers" -}}
{{- $initContainers := .Values.deployment.initContainers | default list -}}
{{- $pluginContainerImage := (include "reposilite.deployment.images.plugin.fqin" . ) }}
{{- $pluginContainerArgs := .Values.deployment.pluginContainer.args | default list }}
{{- $pluginContainerArgs := concat $pluginContainerArgs (list "--output-dir" "/app/data/plugins" ) }}
{{- $pluginContainerVolumeMounts := list (dict "name" "plugins" "mountPath" "/app/data/plugins") }}

{{- if eq (include "reposilite.plugins.prometheus.enabled" $) "true" }}
{{- $fileName := splitList "/" (tpl .Values.config.plugins.prometheus.url $) | last }}
{{- $individualArgs := concat $pluginContainerArgs (list "--output" $fileName (tpl .Values.config.plugins.prometheus.url $)) }}
{{- $initContainers = concat $initContainers (list (dict "args" $individualArgs "name" "download-prometheus-plugin" "image" $pluginContainerImage "volumeMounts" $pluginContainerVolumeMounts)) }}
{{- end }}

{{ toYaml (dict "initContainers" $initContainers) }}

{{- end }}

{{/* plugins */}}
{{- define "reposilite.plugins.prometheus.enabled" -}}
{{- if or .Values.config.plugins.prometheus.enabled .Values.prometheus.metrics.enabled -}}
true
{{- else -}}
false
{{- end -}}
{{- end }}

{{/* serviceAccount */}}

{{- define "reposilite.deployment.serviceAccount" -}}
{{- if .Values.serviceAccount.existing.enabled -}}
{{- printf "%s" .Values.serviceAccount.existing.serviceAccountName -}}
{{- else -}}
{{- include "reposilite.fullname" . -}}
{{- end -}}
{{- end }}

{{/* volumeMounts */}}

{{- define "reposilite.deployment.reposilite.volumeMounts" -}}
{{- $volumeMounts := .Values.deployment.reposilite.volumeMounts | default list }}
{{- if .Values.persistentVolumeClaim.enabled }}
{{- $volumeMounts = concat $volumeMounts (list (dict "name" "data" "mountPath" .Values.persistentVolumeClaim.path )) }}
{{- end }}

{{- if eq (include "reposilite.plugins.prometheus.enabled" $) "true" }}
{{- $volumeMounts = concat $volumeMounts (list (dict "name" "plugins" "mountPath" "/app/data/plugins")) }}
{{- end }}

{{ toYaml (dict "volumeMounts" $volumeMounts) }}
{{- end -}}

{{/* volumes */}}

{{- define "reposilite.deployment.volumes" -}}
{{- $volumes := .Values.deployment.volumes | default list }}

{{- if and .Values.persistentVolumeClaim.enabled (not .Values.persistentVolumeClaim.existing.enabled) }}
{{- $persistentVolumeClaimName := include "reposilite.persistentVolumeClaim.name" $ -}}
{{- $volumes = concat $volumes (list (dict "name" "data" "persistentVolumeClaim" (dict "claimName" $persistentVolumeClaimName))) }}
{{- else if and .Values.persistentVolumeClaim.enabled .Values.persistentVolumeClaim.existing.enabled .Values.persistentVolumeClaim.existing.persistentVolumeClaimName -}}
{{- $persistentVolumeClaimName := .Values.persistentVolumeClaim.existing.persistentVolumeClaimName -}}
{{- $volumes = concat $volumes (list (dict "name" "data" "persistentVolumeClaim" (dict "claimName" $persistentVolumeClaimName))) }}
{{- end }}

{{- if eq (include "reposilite.plugins.prometheus.enabled" $) "true" }}
{{- $volumes = concat $volumes (list (dict "name" "plugins" "emptyDir" dict)) }}
{{- end }}

{{ toYaml (dict "volumes" $volumes) }}

{{- end -}}