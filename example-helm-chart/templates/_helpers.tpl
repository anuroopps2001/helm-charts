{{- define "mychart.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name  | trunc 15 | trimSuffix "-" -}}  {{/* trunc to keep only 15 chars and trimSuffic to remove "-" if any at the end of the string */}}
{{- end -}}



{{- define "mychart.labels" -}}
app.kubernetes.io/name: {{ include "mychart.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
{{- end }}
