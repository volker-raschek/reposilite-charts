---

{{/* annotations */}}

{{- define "reposilite.pod.annotations" -}}
{{ include "reposilite.annotations" . }}
{{- if .Values.prometheus.metrics.enabled -}}
{{- printf "checksum/secret-%s: %s" (include "reposilite.secrets.prometheusBasicAuth.name" $) (include (print $.Template.BasePath "/secretPrometheusBasicAuth.yaml") . | sha256sum) }}
{{- end -}}
{{- end }}

{{/* labels */}}

{{- define "reposilite.pod.labels" -}}
{{ include "reposilite.labels" . }}
{{- end }}

{{- define "reposilite.pod.selectorLabels" -}}
{{ include "reposilite.selectorLabels" . }}
{{- end }}