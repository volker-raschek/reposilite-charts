{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "reposilite.service.annotations" -}}
{{ include "reposilite.annotations" . }}
{{- if .Values.service.annotations }}
{{ toYaml .Values.service.annotations }}
{{- end }}
{{/* Add label to select the correct service via `selector.matchLabels` of the serviceMonitor resource. */}}
app.kubernetes.io/service-name: http
{{- end }}

{{/* labels */}}

{{- define "reposilite.service.labels" -}}
{{ include "reposilite.labels" . }}
{{- if .Values.service.labels }}
{{ toYaml .Values.service.labels }}
{{- end }}
{{- end }}

{{/* names */}}

{{- define "reposilite.service.name" -}}
{{- if .Values.service.enabled -}}
{{ include "reposilite.fullname" . }}
{{- end -}}
{{- end -}}