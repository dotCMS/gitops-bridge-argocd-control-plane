{{/*
Expand the name of the chart.
*/}}
{{- define "linkerd-test-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "linkerd-test-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "linkerd-test-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "linkerd-test-app.labels" -}}
helm.sh/chart: {{ include "linkerd-test-app.chart" . }}
{{ include "linkerd-test-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: gitops-bridge
environment: {{ .Values.environment }}
{{- end }}

{{/*
Frontend selector labels
*/}}
{{- define "linkerd-test-app.frontend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "linkerd-test-app.name" . }}-frontend
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Backend selector labels  
*/}}
{{- define "linkerd-test-app.backend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "linkerd-test-app.name" . }}-backend
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Common selector labels
*/}}
{{- define "linkerd-test-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "linkerd-test-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
