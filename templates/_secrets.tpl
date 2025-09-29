{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "reposilite.secrets.prometheusBasicAuth.annotations" -}}
{{ include "reposilite.annotations" . }}
{{- if .Values.prometheus.metrics.secret.new.annotations }}
{{ toYaml .Values.prometheus.metrics.secret.new.annotations }}
{{- end }}
{{- end }}

{{/* labels */}}

{{- define "reposilite.secrets.prometheusBasicAuth.labels" -}}
{{ include "reposilite.labels" . }}
{{- if .Values.prometheus.metrics.secret.new.labels }}
{{ toYaml .Values.prometheus.metrics.secret.new.labels }}
{{- end }}
{{- end }}

{{/* names */}}

{{- define "reposilite.secrets.prometheusBasicAuth.name" -}}
{{- if and .Values.prometheus.metrics.secret.existing.enabled (gt (len .Values.prometheus.metrics.secret.existing.secretName) 0) }}
{{- print .Values.prometheus.metrics.secret.existing.secretName -}}
{{- else if and .Values.prometheus.metrics.secret.existing.enabled (eq (len .Values.prometheus.metrics.secret.existing.secretName) 0) }}
{{ fail "Name of the existing secret that contains the credentials for basic auth is not defined!" }}
{{- else if not .Values.prometheus.metrics.secret.existing.enabled }}
{{- printf "%s-basic-auth-credentials" (include "reposilite.fullname" $) -}}
{{- end }}
{{- end }}

{{/* secretKeyNames */}}

{{- define "reposilite.secrets.prometheusBasicAuth.passwordKey" -}}
{{- if and .Values.prometheus.metrics.secret.existing.enabled (gt (len .Values.prometheus.metrics.secret.existing.basicAuthPasswordKey) 0) -}}
{{- .Values.prometheus.metrics.secret.existing.basicAuthPasswordKey -}}
{{- else if and .Values.prometheus.metrics.secret.existing.enabled (eq (len .Values.prometheus.metrics.secret.existing.basicAuthPasswordKey) 0) }}
{{ fail "Name of the key in the secret that contains the password for basic auth is not defined!" }}
{{- else if and (not .Values.prometheus.metrics.secret.existing.enabled) }}
{{- print "password" -}}
{{- end }}
{{- end }}

{{- define "reposilite.secrets.prometheusBasicAuth.usernameKey" -}}
{{- if and .Values.prometheus.metrics.secret.existing.enabled (gt (len .Values.prometheus.metrics.secret.existing.basicAuthUsernameKey) 0) -}}
{{- .Values.prometheus.metrics.secret.existing.basicAuthUsernameKey -}}
{{- else if and .Values.prometheus.metrics.secret.existing.enabled (eq (len .Values.prometheus.metrics.secret.existing.basicAuthUsernameKey) 0) }}
{{ fail "Name of the key in the secret that contains the username for basic auth is not defined!" }}
{{- else if and (not .Values.prometheus.metrics.secret.existing.enabled) }}
{{- print "username" -}}
{{- end }}
{{- end }}
