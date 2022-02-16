{{- define "logger.probes" }}
livenessProbe:
  exec:
    command: ["ash", "-c", 'expr $(pgrep ruby | wc -l) ">=" 2']
  initialDelaySeconds: {{ .root.Values.minio.metricsLogger.livenessProbe.initialDelaySeconds }}
  periodSeconds: {{ .root.Values.minio.metricsLogger.livenessProbe.periodSeconds }}
  timeoutSeconds: {{ .root.Values.minio.metricsLogger.livenessProbe.timeoutSeconds }}
  successThreshold: {{ .root.Values.minio.metricsLogger.livenessProbe.successThreshold }}
  failureThreshold: {{ .root.Values.minio.metricsLogger.livenessProbe.failureThreshold }}
readinessProbe:
  exec:
    command: ["ash", "-c", 'expr $(pgrep ruby | wc -l) ">=" 2']
  initialDelaySeconds: {{ .root.Values.minio.metricsLogger.readinessProbe.initialDelaySeconds }}
  periodSeconds: {{ .root.Values.minio.metricsLogger.readinessProbe.periodSeconds }}
  timeoutSeconds: {{ .root.Values.minio.metricsLogger.readinessProbe.timeoutSeconds }}
  successThreshold: {{ .root.Values.minio.metricsLogger.readinessProbe.successThreshold }}
  failureThreshold: {{ .root.Values.minio.metricsLogger.readinessProbe.failureThreshold }}
{{- end }}
