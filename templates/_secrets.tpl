{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "reposilite.secrets.prometheusBasicAuth.annotations" -}}
{{ include "reposilite.annotations" . }}
{{- end }}

{{/* labels */}}

{{- define "reposilite.secrets.prometheusBasicAuth.labels" -}}
{{ include "reposilite.labels" . }}
{{- end }}

{{/* names */}}

{{- define "reposilite.secrets.prometheusBasicAuth.name" -}}
{{ include "reposilite.fullname" . }}-basic-auth-credentials
{{- end -}}
