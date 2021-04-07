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
configurations and the supported ones under `metricsLogger`. These default
values may be overridden/reconfigured with a custom values file (e.g.
`.values.yaml`) or from the command-line for deployment.

The following sections list the availalbe supported helm values and will work if
and only if `metricsLogger` is enabled i.e.:

```yaml
minio:
  metricsLogger:
    enable: true
```

The defaults are in **bold** under the **supported values** column.

Available time suffixes:

- s: seconds
- m: minutes
- h: hours

### Common Configuration

| key                         | supported values                            |
|:----------------------------|:--------------------------------------------|
| LOG_LEVEL                   | trace, debug, **info**, warn, error, fatal  |

### Redis Server Configuration

| key                         | supported values                            |
|:----------------------------|:--------------------------------------------|
| REDIS_HOST                  | **localhost**                               |
| REDIS_PORT                  | **6379**                                    |
| REDIS_DB                    | **0**                                       |
| UPDATE_GRACE_PERIOD_SECONDS | **300s**                                    |
| DEPLOYMENT_API_METRICS_FLUSH_INTERVAL_SECONDS | **300s**                  |
| REDIS_KEY_PREFIX_DEPLOYMENT_LAST_ACTION | **deploymentid:last_action**    |
| REDIS_KEY_PREFIX_DEPLOYMENT_API_METRIC  | **deploymentid:minio-metrics**  |

### Logs Flushing Configuration (Buffering)

| key                         | supported values                            |
|:----------------------------|:--------------------------------------------|
| LOGS_FLUSH_COMPRESSION      | **gzip**, text                              |
| LOGS_FLUSH_AT_SHUTDOWN      | **true**, false                             |
| LOGS_FLUSH_INTERVAL         | **60s**                                     |
| LOGS_FLUSH_RETRY_WAIT       | **20s**                                     |

**NOTE**: For buffering, the files are used and it only works for
`elasticsearch` and `s3` log targets.

### Log Targets Confiugration

| key                         | supported values                            |
|:----------------------------|:--------------------------------------------|
| LOG_PROVIDER                | **default**, stdout, elasticsearch, s3      |

#### ElasticSearch Log Target Confiugration (`LOG_PROVIDER: elasticsearch`)

| key                         | supported values                            |
|:----------------------------|:--------------------------------------------|
| ES_HOST                     | **0.0.0.0**                                 |
| ES_PORT                     | **9200**                                    |
| ES_SCHEME                   | **http**, https                             |
| ES_MULTIPLE_HOSTS_ENABLED   | **false**, true                             |
| ES_HOSTS                    | **'0.0.0.0:9200'**                          |
| ES_SSL_VERIFY               | **true**, false                             |
| ES_AUTH_ENABLED             | **false**, true                             |
| ES_USERNAME                 | **dummykey**                                |
| ES_PASSWORD                 | **dummypass**                               |
| ES_INDEX_NAME               | **test**                                    |
| ES_TYPE_NAME                | **_doc**                                    |
| ES_PATH                     | **/logs** (no trailing slash)               |

Multiple hosts can be configured with `ES_HOSTS` in a comma-separated list.
You can configure multiple hosts like this:

```yaml
    ES_MULTIPLE_HOSTS_ENABLED: true
    ES_HOSTS: '0.0.0.0:9200','xxx.xxx.xxx.xxx:9200'
```

NOTE: If `ES_MULTIPLE_HOSTS_ENABLED: true`, `ES_HOSTS` is used. The `ES_HOST`
and `ES_PORT` are ignored in this case.

If `ES_AUTH_ENABLED: false`, `ES_USERNAME` and `ES_PASSWORD` are ignored.

#### S3 Log Target Confiugration (`LOG_PROVIDER: s3`)

| key                         | supported values                            |
|:----------------------------|:--------------------------------------------|
| AWS_KEY_ID                  | **dummykey**                                |
| AWS_SECRET_KEY              | **dummypass**                               |
| S3_BUCKET                   | **test123**                                 |
| S3_REGION                   | **us-east-1**                               |
| S3_PATH                     | **logs/**                                   |
| S3_NON_AWS_TARGET           | **false**, true                             |
| S3_ENDPOINT                 | **http://localhost:8080**                   |
| S3_SSL_VERIFY               | **true**, false                             |
| S3_STORE_AS                 | **gzip**, lzo, json, txt                    |

You can configure for non-AWS S3 compatible services like this:

```yaml
    S3_NON_AWS_TARGET: true
    S3_ENDPOINT: http://localhost:8080
```

### Deployment with Helm Values

For the complete list of all the available values, use:

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

For debugging purposes, you can add `--dry-run` and `--debug` flags to validate
and verify the values affecting the deployment:

```shell
helm upgrade -f .values.yaml --install cwm-worker-deployment-minio ./helm --dry-run --debug
```

And, can be deployed like this:

```shell
helm upgrade -f .values.yaml --install cwm-worker-deployment-minio ./helm
```
