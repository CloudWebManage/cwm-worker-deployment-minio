{{- define "logger.probes" }}
livenessProbe:
  httpGet:
    path: /health
    port: 8500
  initialDelaySeconds: {{ .root.Values.minio.metricsLogger.livenessProbe.initialDelaySeconds }}
  periodSeconds: {{ .root.Values.minio.metricsLogger.livenessProbe.periodSeconds }}
  timeoutSeconds: {{ .root.Values.minio.metricsLogger.livenessProbe.timeoutSeconds }}
  successThreshold: {{ .root.Values.minio.metricsLogger.livenessProbe.successThreshold }}
  failureThreshold: {{ .root.Values.minio.metricsLogger.livenessProbe.failureThreshold }}
readinessProbe:
  httpGet:
    path: /health
    port: 8500
  initialDelaySeconds: {{ .root.Values.minio.metricsLogger.readinessProbe.initialDelaySeconds }}
  periodSeconds: {{ .root.Values.minio.metricsLogger.readinessProbe.periodSeconds }}
  timeoutSeconds: {{ .root.Values.minio.metricsLogger.readinessProbe.timeoutSeconds }}
  successThreshold: {{ .root.Values.minio.metricsLogger.readinessProbe.successThreshold }}
  failureThreshold: {{ .root.Values.minio.metricsLogger.readinessProbe.failureThreshold }}
{{- end }}
