{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "reposilite.clientSettingsPolicy.annotations" -}}
{{ include "reposilite.annotations" . }}
{{- if .Values.gatewayAPI.nginx.clientSettingsPolicy.annotations }}
{{ toYaml .Values.gatewayAPI.nginx.clientSettingsPolicy.annotations }}
{{- end }}
{{- end }}

{{/* enabled */}}

{{- define "reposilite.clientSettingsPolicy.enabled" -}}
{{- if and (eq (include "reposilite.httpRoute.enabled" $) "true")
           .Values.gatewayAPI.nginx.clientSettingsPolicy.enabled
-}}
true
{{- else -}}
false
{{- end -}}
{{- end }}

{{/* labels */}}

{{- define "reposilite.clientSettingsPolicy.labels" -}}
{{ include "reposilite.labels" . }}
{{- if .Values.gatewayAPI.nginx.clientSettingsPolicy.labels }}
{{ toYaml .Values.gatewayAPI.nginx.clientSettingsPolicy.labels }}
{{- end }}
{{- end }}
