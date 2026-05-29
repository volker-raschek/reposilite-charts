{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "reposilite.backendTLSConfig.annotations" -}}
{{ include "reposilite.annotations" . }}
{{- if .Values.gatewayAPI.core.backendTLSConfig.annotations }}
{{ toYaml .Values.gatewayAPI.core.backendTLSConfig.annotations }}
{{- end }}
{{- end }}

{{/* enabled */}}

{{- define "reposilite.backendTLSConfig.enabled" -}}
{{- if and .Values.gatewayAPI.enabled
           .Values.gatewayAPI.core.backendTLSConfig.enabled
           .Values.service.enabled
-}}
true
{{- else -}}
false
{{- end -}}
{{- end }}

{{/* labels */}}

{{- define "reposilite.backendTLSConfig.labels" -}}
{{ include "reposilite.labels" . }}
{{- if .Values.gatewayAPI.core.backendTLSConfig.labels }}
{{ toYaml .Values.gatewayAPI.core.backendTLSConfig.labels }}
{{- end }}
{{- end }}
