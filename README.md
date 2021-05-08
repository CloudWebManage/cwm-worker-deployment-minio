# cwm-worker-deployment-minio

![CI](https://github.com/CloudWebManage/cwm-worker-deployment-minio/workflows/CI/badge.svg?branch=main&event=push)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/CloudWebManage/cwm-worker-deployment-minio)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/CloudWebManage/cwm-worker-deployment-minio/blob/main/LICENSE)

![Lines of code](https://img.shields.io/tokei/lines/github/CloudWebManage/cwm-worker-deployment-minio?label=LOC)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/CloudWebManage/cwm-worker-deployment-minio)
![GitHub repo size](https://img.shields.io/github/repo-size/CloudWebManage/cwm-worker-deployment-minio)

## Local Development

### Using Docker Compose

Docker Compose is used for quick prototyping of the deployment without using
Kubernetes.

Start the stack:

```shell
docker-compose up --build
```

If you encounter this SSL version error:

```text
ERROR: SSL error: HTTPSConnectionPool(host='<ip-address>', port=2376): Max retries exceeded with url: /v1.30/build?q=False&pull=False&t=minio&nocache=False&forcerm=False&rm=True (Caused by SSLError(SSLError(1, u'[SSL: TLSV1_ALERT_PROTOCOL_VERSION] tlsv1 alert protocol version (_ssl.c:727)'),))
```

You can resolve it like this:

```shell
export COMPOSE_TLS_VERSION=TLSv1_2
```

Login to Minio at http://localhost:8080 or https://localhost:8443

user: 12345678 / password: 12345678

### Using Helm

- Install [Minikube](https://minikube.sigs.k8s.io/docs/) (latest stable version).
- Install [Helm](https://helm.sh/) (latest stable version).
- Start a local cluster: `minikube start --driver=docker --kubernetes-version=v1.16.14`
- Switch to the minikube docker env: `eval $(minikube -p minikube docker-env)`.
- Build the Docker images: `docker-compose build`
- Build the cwm-worker-logger image: `docker build -t cwm-worker-logger ../cwm-worker-logger`
  - Change the directory according to where you cloned
    [cwm-worker-logger](https://github.com/cloudwebmanage/cwm-worker-logger).
  - Make sure you checked out the relevant version of `cwm-worker-logger` you want
    to test with (e.g. `git pull origin main` to get latest version).
- Create a file at `.values.yaml` with the following content:

  ```yaml
  minio:
    image: minio
    tag: latest
    initDebugEnable: true
    enableServiceMonitors: false
    metricsLogger:
      image: cwm-worker-logger
      tag: latest
      DEPLOYMENT_API_METRICS_FLUSH_INTERVAL_SECONDS: "5"
      LOG_LEVEL: debug
    nginx:
      image: nginx
      tag: latest
  ```

- You can apply additional configurations to override the configuration at
  `helm/values.yaml`.
- Deploy: `helm upgrade -f .values.yaml --install cwm-worker-deployment-minio ./helm`
- Verify that the minio pod is running: `kubectl get pods`
- Start port-forward to the nginx service:
  - `kubectl port-forward service/nginx 8080:80`
  - `kubectl port-forward service/minio 8443:443`
- Access it at http://localhost:8080 or https://localhost:8443
- Also, try https://example003.com:8443 vs. https://example002.com:8443 - each
  one should serve the relevant certificate for this domain
- Default username/password: `dummykey` / `dummypass`
- Create a bucket and upload/download some objects.
- Start Redis CLI and check the recorded metrics:

  ```shell
  kubectl exec deployment/minio-logger -c redis -it -- redis-cli
  keys *
  get deploymentid:minio-metrics:minio1:num_requests_in
  ```

### Manual testing of log providers

For these tests, we will use AWS to provide all the required log backends.

#### Elasticsearch

- Amazon Elasticsearch -> Create a new domain
  - Deployment type: Development and testing
  - Elasticsearch version: 7.9
  - Elasticsearch domain name: cwm-worker-logger-tests
  - Instance type: t2.small.elasticsearch
  - Network configuration: public access
  - Domain access policy: custom: ipv4 address: allow your IP

Add the following to the default `.values.yaml` file (as described in using helm
section above):

```yaml
# under metricsLogger:
  LOG_PROVIDER: elasticsearch
  ES_HOST: 
  ES_PORT:
```

Deploy the helm chart according to instructions for using Helm.

#### S3

- Amazon S3 -> Create bucket

Add the following to the default `.values.yaml` file (as described in using helm
section above):

```yaml
# under metricsLogger:
  LOG_PROVIDER: s3
  AWS_KEY_ID: 
  AWS_SECRET_KEY:
  S3_BUCKET_NAME:
  S3_REGION:
```

Deploy the helm chart according to instructions for using Helm.

#### Logger disabled

It disables the logger pod and runs without logging.

Add the following to the default `.values.yaml` file (as described in using helm
section above):

```yaml
# under minio:
  auditWebhookEndpoint: ""

# under metricsLogger:
    enable: false
```

Deploy the helm chart according to instructions for using Helm.

#### Logging to Minio

Deploy a Minio instance which will be used to store the logs:

```shell
helm upgrade --install cwm-worker-deployment-minio ./helm -n logs --create-namespace \
    --set minio.auditWebhookEndpoint="" \
    --set minio.metricsLogger.enable=false \
    --set minio.image=minio
```

Verify from the logs that the Minio pod is ready.

Add the following to the default `.values.yaml` file (as described in using helm
section above):

```yaml
# under metricsLogger:
  LOGS_FLUSH_INTERVAL: 5s
  LOGS_FLUSH_RETRY_WAIT: 10s
  LOG_PROVIDER: s3
  S3_NON_AWS_TARGET: true
  S3_ENDPOINT: http://minio.logs:8080
```

Deploy to storage namespace:

```shell
helm upgrade -f .values.yaml -n storage --create-namespace --install cwm-worker-deployment-minio ./helm
```

Start a port-forward to storage minio service:

```shell
kubectl -n storage port-forward service/minio 8080
```

Make some actions (upload/download objects)

Start a port-forward to logs minio service:

```shell
kubectl -n logs port-forward service/minio 8080
```

Logs should appear in bucket `test123`.

## Scaling

A custom [KEDA](https://keda.sh/) external scaler
[cwm-keda-external-scaler](https://github.com/iamazeem/cwm-keda-external-scaler)
is being used to perform scaling.

Make sure that the KEDA has already been deployed before proceeding with a
`ScaledObject`. Use [install with YAML](https://keda.sh/docs/2.1/deploy/#yaml)
method.

By default, the external scaler is disabled i.e. no scaling.

To enable it, use a custom `.values.yaml` and deploy accordingly:

```yaml
minio:
  # ...
  externalscaler:
    enabled: true
```

Deploy: `helm upgrade -f .values.yaml --install cwm-worker-deployment-minio ./helm`

The external scaler should be up and running.
Now, the `ScaledObject` can be configured and deployed.

```yaml
minio:
  # ...
  scaledobject:
    enabled: true
```

A custom `ScaledObject` has been provided for the minio deployment. It can be
modified and deployed as required. It can be found under `./helm/templates/`
directory.
See: [minio-external-scaler-scaledobject.yaml](helm/templates/minio-external-scaler-scaledobject.yaml)

Deploy: `helm upgrade -f .values.yaml --install cwm-worker-deployment-minio ./helm`

## Running Tests

See [CI workflow](.github/workflows/ci.yml).

## Contribute

- Fork the project.
- Check out the latest `main` branch.
- Create a feature or bugfix branch from `main`.
- Commit and push your changes.
- Make sure to add tests.
- Run Rubocop locally and fix all the lint warnings.
- Submit the PR.

## License

[MIT](./LICENSE)
