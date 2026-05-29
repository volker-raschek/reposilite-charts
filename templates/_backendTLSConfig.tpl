{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "reposilite.backendTLSPolicy.annotations" -}}
{{ include "reposilite.annotations" . }}
{{- if .Values.gatewayAPI.core.backendTLSPolicy.annotations }}
{{ toYaml .Values.gatewayAPI.core.backendTLSPolicy.annotations }}
{{- end }}
{{- end }}

{{/* enabled */}}

{{- define "reposilite.backendTLSPolicy.enabled" -}}
{{- if and .Values.gatewayAPI.enabled
           .Values.gatewayAPI.core.backendTLSPolicy.enabled
           .Values.service.enabled
-}}
true
{{- else -}}
false
{{- end -}}
{{- end }}

{{/* labels */}}

{{- define "reposilite.backendTLSPolicy.labels" -}}
{{ include "reposilite.labels" . }}
{{- if .Values.gatewayAPI.core.backendTLSPolicy.labels }}
{{ toYaml .Values.gatewayAPI.core.backendTLSPolicy.labels }}
{{- end }}
{{- end }}
