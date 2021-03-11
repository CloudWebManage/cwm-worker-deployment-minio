# Logging

## Overview

The logging component
[cwm-worker-logger](https://github.com/cloudwebmanage/cwm-worker-logger) uses
fluentd's
[fluent-plugin-http-cwm](https://github.com/iamAzeem/fluent-plugin-http-cwm)
under the hood.

This component:

- receives the incoming JSON logs from MinIO using an HTTP endpoint,
- validates the required JSON fields,
- aggregates the logging metrics,
- flushes the aggregated metrics to the configured Redis instance; and,
- routes logs to the configured log targets e.g. S3, ElasticSearch, etc.

```text
  +------------------+
  |       MinIO      |
  +------------------+
            |
            | JSON
            | logs
            v
  +------------------+
  |     fluentd      |
  |                  |
  | +--------------+ |                   +-----------------+
  | |   http_cwm   | |     [metrics]     |      Redis      |
  | |   (input)    |-------------------->|      Server     |
  | +--------------+ |                   +-----------------+
  |                  |
  | +--------------+ |                   +-----------------+
  | |      s3      | |     [raw logs]    |       S3        |
  | |   (output)   |-------------------->|   (log target)  |
  | +--------------+ |                   +-----------------+
  |                  |
  | +--------------+ |                   +-----------------+
  | |elasticsearch | |     [raw logs]    |  ElasticSearch  |
  | |   (output)   |-------------------->|  (log target)   |
  | +--------------+ |                   +-----------------+
  |                  |
  +------------------+
```

## Helm Values

For logging, the helm values (`values.yaml`) provide a list of default
configurations and the supported ones as comments under `metricsLogger`. These
default values may be overridden/reconfigured with a custom values file (e.g.
`.values.yaml`) and used for deployment.

For simplicity, the configuration can be divided like this:

- helm/k8s/docker configurations e.g. `enable`, `image`, `resrouces`, etc.
- **logger**
  - common configuration: `LOG_LEVEL`, redis-server configuration for flushing metrics
  - log targets' configuration i.e. `LOG_TARGET <target-name>`:
    - **default**: no log target, only metrics flushing to redis-server
    - **stdout**: logs flushing to STDOUT with metrics flushing
    - **elasticsearch**: logs flushing to AWS ElasticSearch service or to an
      on-prem hosted instance
      - configuration: `ES_HOST`, `ES_PORT`, `ES_SCHEME`. `ES_INDEX_NAME`, etc.
    - **s3**: logs flushing to AWS S3 or to an on-prem hosted instance
      - configuration: `AWS_KEY_ID`, `AWS_SECRET_KEY`, `S3_BUCKET_NAME`,
        `S3_REGION`, etc.
  - buffer configuration for retaining/flushing logs to log targets (only
    available for non-default log targets)
    - `LOGS_FLUSH_AT_SHUTDOWN` (true/false): enable/disable flushing of buffered
      logs on shutdown
    - `LOGS_FLUSH_INTERVAL` (time: 10s, 2m, ...): flush interval for buffered logs
    - `LOGS_FLUSH_RETRY_WAIT` (time: 20s, 5m, ...): retry wait before attempting
      next flush in case of a failure

For a complete list of all the available values, use:

```shell
helm inspect values ./helm
```

For example, for a custom values file (`.values.yaml`):

```yaml
minio:
  image: minio
  tag: latest
  initDebugEnable: true
  metricsLogger:
    image: cwm-worker-logger
    tag: latest
    LOG_PROVIDER: elasticsearch
    ES_HOST: <HOST-ENDPOINT-HERE>
    ES_PORT: 443
    ES_SCHEME: https
    ES_INDEX_NAME: test
    LOG_LEVEL: debug
    DEPLOYMENT_API_METRICS_FLUSH_INTERVAL_SECONDS: 25s
    LOGS_FLUSH_AT_SHUTDOWN: false
    LOGS_FLUSH_INTERVAL: 5s
    LOGS_FLUSH_RETRY_WAIT: 10s
```

The `helm` command can be run with `--dry-run` and `--debug` flags to validate
it and verify the values that will affect the deployment:

```shell
helm upgrade -f .values.yaml --install cwm-worker-deployment-minio ./helm --dry-run --debug
```

And, can be deployed without `--dry-run`:

```shell
helm upgrade -f .values.yaml --install cwm-worker-deployment-minio ./helm
```

## Helm ConfigMap

An alternative, more flexible, and rather preferable way to configure the logger
is via its Helm's ConfigMap. The
[logger-configmap.yaml](./helm/templates/logger-configmap.yaml) can easily be
configured/reconfigured even for the settings not already exposed via the
environment variables.

**NOTE**: Only a small subset of the required configurations has been exposed
via the environment variables.

The logger's ConfigMap provides direct access to the fluentd configuration. The
log targets can easily be configured for a more complex setup. For more details,
please visit their respective pages:

- ElasticSearch: https://docs.fluentd.org/output/elasticsearch
- S3: https://docs.fluentd.org/output/s3

The ConfigMap contains configuration divided into multiple files to be mounted
on `/fluentd/etc/` directory inside the logger's container.

The only external configuration that affects the selection of the right log
target will be `LOG_PROVIDER` in `values.yaml` which can be overridden by any
other values file or from the command-line.

## Important Points

1. The `LOG_LEVEL` affects all the configurations.
2. The redis-server configurations are configured once and are always enabled if
   `metricsLogger` is enabled.
3. The flushing configurations only work for non-default log targets i.e.
   `stdout`, `elasticsearch`, and `s3`.
4. For buffering, files are used for persistence. The logs are buffered and
   flushed as configured.
