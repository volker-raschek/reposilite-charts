{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "reposilite.httpRoute.annotations" -}}
{{ include "reposilite.annotations" . }}
{{- if .Values.gatewayAPI.core.httpRoute.annotations }}
{{ toYaml .Values.gatewayAPI.core.httpRoute.annotations }}
{{- end }}
{{- end }}

{{/* enabled */}}

{{- define "reposilite.httpRoute.enabled" -}}
{{- if and .Values.gatewayAPI.enabled
           .Values.gatewayAPI.core.httpRoute.enabled
           .Values.service.enabled
-}}
true
{{- else -}}
false
{{- end -}}
{{- end }}

{{/* labels */}}

{{- define "reposilite.httpRoute.labels" -}}
{{ include "reposilite.labels" . }}
{{- if .Values.gatewayAPI.core.httpRoute.labels }}
{{ toYaml .Values.gatewayAPI.core.httpRoute.labels }}
{{- end }}
{{- end }}
