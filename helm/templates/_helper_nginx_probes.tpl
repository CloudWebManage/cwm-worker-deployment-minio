{{- define "nginx.probes" }}
startupProbe:
  exec:
    command: ["curl", "--max-time", "{{ .root.Values.minio.nginx.startupProbe.curlMaxTimeSeconds }}", "--connect-timeout", "{{ .root.Values.minio.nginx.startupProbe.curlConnectTimeoutSeconds }}", "-s", http://localhost:8080{{ .root.Values.minio.nginx.startupProbe.path }}]
  initialDelaySeconds: {{ .root.Values.minio.nginx.startupProbe.initialDelaySeconds }}
  periodSeconds: {{ .root.Values.minio.nginx.startupProbe.periodSeconds }}
  timeoutSeconds: {{ .root.Values.minio.nginx.startupProbe.timeoutSeconds }}
  successThreshold: {{ .root.Values.minio.nginx.startupProbe.successThreshold }}
  failureThreshold: {{ .root.Values.minio.nginx.startupProbe.failureThreshold }}
livenessProbe:
  exec:
    command: ["curl", "--max-time", "{{ .root.Values.minio.nginx.livenessProbe.curlMaxTimeSeconds }}", "--connect-timeout", "{{ .root.Values.minio.nginx.livenessProbe.curlConnectTimeoutSeconds }}", "-s", http://localhost:8080{{ .root.Values.minio.nginx.livenessProbe.path }}]
  initialDelaySeconds: {{ .root.Values.minio.nginx.livenessProbe.initialDelaySeconds }}
  periodSeconds: {{ .root.Values.minio.nginx.livenessProbe.periodSeconds }}
  timeoutSeconds: {{ .root.Values.minio.nginx.livenessProbe.timeoutSeconds }}
  successThreshold: {{ .root.Values.minio.nginx.livenessProbe.successThreshold }}
  failureThreshold: {{ .root.Values.minio.nginx.livenessProbe.failureThreshold }}
readinessProbe:
  exec:
    command: ["curl", "--max-time", "{{ .root.Values.minio.nginx.readinessProbe.curlMaxTimeSeconds }}", "--connect-timeout", "{{ .root.Values.minio.nginx.readinessProbe.curlConnectTimeoutSeconds }}", "-s", http://localhost:8080{{ .root.Values.minio.nginx.readinessProbe.path }}]
  initialDelaySeconds: {{ .root.Values.minio.nginx.readinessProbe.initialDelaySeconds }}
  periodSeconds: {{ .root.Values.minio.nginx.readinessProbe.periodSeconds }}
  timeoutSeconds: {{ .root.Values.minio.nginx.readinessProbe.timeoutSeconds }}
  successThreshold: {{ .root.Values.minio.nginx.readinessProbe.successThreshold }}
  failureThreshold: {{ .root.Values.minio.nginx.readinessProbe.failureThreshold }}
{{- end }}
