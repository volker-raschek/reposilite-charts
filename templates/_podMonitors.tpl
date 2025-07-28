{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}
{{- define "reposilite.podMonitor.annotations" -}}
{{ include "reposilite.annotations" . }}
{{- if .Values.prometheus.metrics.podMonitor.annotations }}
{{ toYaml .Values.prometheus.metrics.podMonitor.annotations }}
{{- end }}
{{- end }}

{{/* enabled */}}
{{- define "reposilite.podMonitor.enabled" -}}
{{- if and .Values.prometheus.metrics.enabled .Values.prometheus.metrics.podMonitor.enabled (not .Values.prometheus.metrics.serviceMonitor.enabled) -}}
true
{{- else -}}
false
{{- end -}}
{{- end }}

{{/* labels */}}

{{- define "reposilite.podMonitor.labels" -}}
{{ include "reposilite.labels" . }}
{{- if .Values.prometheus.metrics.podMonitor.labels }}
{{ toYaml .Values.prometheus.metrics.podMonitor.labels }}
{{- end }}
{{- end }}
