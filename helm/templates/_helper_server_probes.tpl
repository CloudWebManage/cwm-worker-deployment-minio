{{- define "server.probes" }}
startupProbe:
  exec:
    command: ["curl", "--max-time", "{{ .root.Values.minio.startupProbe.curlMaxTimeSeconds }}", "--connect-timeout", "{{ .root.Values.minio.startupProbe.curlConnectTimeoutSeconds }}", "-s", http://localhost:8080{{ .root.Values.minio.startupProbe.path }}]
  initialDelaySeconds: {{ .root.Values.minio.startupProbe.initialDelaySeconds }}
  periodSeconds: {{ .root.Values.minio.startupProbe.periodSeconds }}
  timeoutSeconds: {{ .root.Values.minio.startupProbe.timeoutSeconds }}
  successThreshold: {{ .root.Values.minio.startupProbe.successThreshold }}
  failureThreshold: {{ .root.Values.minio.startupProbe.failureThreshold }}
livenessProbe:
  exec:
    command: ["curl", "--max-time", "{{ .root.Values.minio.livenessProbe.curlMaxTimeSeconds }}", "--connect-timeout", "{{ .root.Values.minio.livenessProbe.curlConnectTimeoutSeconds }}", "-s", http://localhost:8080{{ .root.Values.minio.livenessProbe.path }}]
  initialDelaySeconds: {{ .root.Values.minio.livenessProbe.initialDelaySeconds }}
  periodSeconds: {{ .root.Values.minio.livenessProbe.periodSeconds }}
  timeoutSeconds: {{ .root.Values.minio.livenessProbe.timeoutSeconds }}
  successThreshold: {{ .root.Values.minio.livenessProbe.successThreshold }}
  failureThreshold: {{ .root.Values.minio.livenessProbe.failureThreshold }}
readinessProbe:
  exec:
    command: ["curl", "--max-time", "{{ .root.Values.minio.readinessProbe.curlMaxTimeSeconds }}", "--connect-timeout", "{{ .root.Values.minio.readinessProbe.curlConnectTimeoutSeconds }}", "-s", http://localhost:8080{{ .root.Values.minio.readinessProbe.path }}]
  initialDelaySeconds: {{ .root.Values.minio.readinessProbe.initialDelaySeconds }}
  periodSeconds: {{ .root.Values.minio.readinessProbe.periodSeconds }}
  timeoutSeconds: {{ .root.Values.minio.readinessProbe.timeoutSeconds }}
  successThreshold: {{ .root.Values.minio.readinessProbe.successThreshold }}
  failureThreshold: {{ .root.Values.minio.readinessProbe.failureThreshold }}
{{- end }}
