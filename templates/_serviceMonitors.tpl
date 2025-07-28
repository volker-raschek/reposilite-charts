{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "reposilite.serviceMonitor.annotations" -}}
{{ include "reposilite.annotations" . }}
{{- if .Values.prometheus.metrics.serviceMonitor.annotations }}
{{ toYaml .Values.prometheus.metrics.serviceMonitor.annotations }}
{{- end }}
{{- end }}

{{/* enabled */}}

{{- define "reposilite.serviceMonitor.enabled" -}}
{{- if and .Values.prometheus.metrics.enabled (not .Values.prometheus.metrics.podMonitor.enabled) .Values.prometheus.metrics.serviceMonitor.enabled .Values.service.enabled -}}
true
{{- else -}}
false
{{- end -}}
{{- end }}

{{/* labels */}}

{{- define "reposilite.serviceMonitor.labels" -}}
{{ include "reposilite.labels" . }}
{{- if .Values.prometheus.metrics.serviceMonitor.labels }}
{{ toYaml .Values.prometheus.metrics.serviceMonitor.labels }}
{{- end }}
{{- end }}

{{- define "reposilite.serviceMonitor.selectorLabels" -}}
{{ include "reposilite.selectorLabels" . }}
{{/* Add label to select the correct service via `selector.matchLabels` of the serviceMonitor resource. */}}
app.kubernetes.io/service-name: http
{{- end }}