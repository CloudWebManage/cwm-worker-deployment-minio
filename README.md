# cwm-worker-deployment-minio

![CI](https://github.com/CloudWebManage/cwm-worker-deployment-minio/workflows/CI/badge.svg?branch=main&event=push)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/CloudWebManage/cwm-worker-deployment-minio)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/CloudWebManage/cwm-worker-deployment-minio/blob/main/LICENSE)

![Lines of code](https://img.shields.io/tokei/lines/github/CloudWebManage/cwm-worker-deployment-minio?label=LOC)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/CloudWebManage/cwm-worker-deployment-minio)
![GitHub repo size](https://img.shields.io/github/repo-size/CloudWebManage/cwm-worker-deployment-minio)

<!--
  To update the TOC:
  * install nodejs (https://nodejs.org/en/)
  * run the following command:
    * npx doctoc@2.0.1 --github --notitle README.md
-->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Local Development](#local-development)
  - [Using Docker Compose](#using-docker-compose)
  - [Using Helm](#using-helm)
  - [Manual testing of log providers](#manual-testing-of-log-providers)
    - [Elasticsearch](#elasticsearch)
    - [S3](#s3)
    - [Logger disabled](#logger-disabled)
    - [Logging to Minio](#logging-to-minio)
- [Scaling](#scaling)
- [Gateway Mode](#gateway-mode)
  - [Gateway to other Minio instance](#gateway-to-other-minio-instance)
  - [Gateway to Google Cloud Storage](#gateway-to-google-cloud-storage)
  - [Gateway to Azure Blob Storage](#gateway-to-azure-blob-storage)
  - [Gateway to AWS S3](#gateway-to-aws-s3)
- [Nginx Cache](#nginx-cache)
  - [Testing the cache layer locally using Docker Compose](#testing-the-cache-layer-locally-using-docker-compose)
- [Testing virtual-style-host requests](#testing-virtual-style-host-requests)
- [Certificate Challenge](#certificate-challenge)
  - [Testing the challenge response using Docker Compose](#testing-the-challenge-response-using-docker-compose)
- [Running Tests](#running-tests)
- [Contribute](#contribute)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

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
- Start a local cluster: `minikube start --driver=docker --kubernetes-version=v1.18.15 --network-plugin=cni --cni=calico`
- Switch to the minikube docker env: `eval $(minikube -p minikube docker-env)`.
- Build the Docker images: `docker-compose build`
- Build the cwm-worker-logger image: `docker build -t cwm-worker-logger ../cwm-worker-logger`
  - Change the directory according to where you cloned
    [cwm-worker-logger](https://github.com/cloudwebmanage/cwm-worker-logger).
  - Make sure you checked out the relevant version of `cwm-worker-logger` you want
    to test with (e.g. `git pull origin main` to get latest version).
- Build the cwm-keda-external-scaler image: `docker build -t cwm-keda-external-scaler ../cwm-keda-external-scaler`
  - Change the directory according to where you cloned
    [cwm-keda-external-scaler](https://github.com/cloudwebmanage/cwm-keda-external-scaler).
  - Make sure you checked out the relevant version of `cwm-keda-external-scaler` you want
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
    externalscaler:
      enabled: true
      image: cwm-keda-external-scaler
    scaledobject:
      enabled: false
    nginx:
      image: nginx
      tag: latest
  ```

- You can apply additional configurations to override the configuration at
  `helm/values.yaml`.
- Deploy: `helm upgrade -f .values.yaml --install cwm-worker-deployment-minio ./helm`
- Verify that the minio pod is running: `kubectl get pods`
- Start port-forward to the nginx service:
  - `kubectl port-forward service/minio-nginx 8080:8080`
  - `kubectl port-forward service/minio-nginx 8443:8443`
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
kubectl -n storage port-forward service/minio-server 8080
```

Make some actions (upload/download objects)

Start a port-forward to logs minio service:

```shell
kubectl -n logs port-forward service/minio-server 8080
```

Logs should appear in bucket `test123`.

## Scaling

Following types of scaling via ScaledObjects are supported:

- `external` (external scaler must be enabled and deployed)
- `cpu`
- `memmory`

For scaling with the external metrics, a custom [KEDA](https://keda.sh/)
external scaler
[cwm-keda-external-scaler](https://github.com/cloudwebmanage/cwm-keda-external-scaler)
is used.

Make sure that the KEDA has already been deployed before proceeding with the
`ScaledObject`. Use [install with YAML](https://keda.sh/docs/2.1/deploy/#yaml)
method.

By default, the external scaler is disabled i.e. no scaling.

To enable it, use a custom `.values.yaml` and deploy accordingly:

```yaml
minio:
  externalscaler:
    enabled: true
```

Deploy: `helm upgrade -f .values.yaml --install cwm-worker-deployment-minio ./helm`

The external scaler should be up and running.
Now, the `ScaledObject` can be configured and deployed:

```yaml
minio:
  scaledobject:
    enabled: true
    type: external
    pollingInterval: 10
    cooldownPeriod:  60
    minReplicaCount: 1
    maxReplicaCount: 10
    # advanced:
    #   restoreToOriginalReplicaCount: true
    #   horizontalPodAutoscalerConfig:
    #     behavior:
    #       scaleDown:
    #         stabilizationWindowSeconds: 30
    #         policies:
    #         - type: Percent
    #           value: 80
    #           periodSeconds: 15
    isActiveTtlSeconds: "60"
    scalePeriodSeconds: "60"
    scaleMetricName: "num_requests_misc"
    targetValue: "10"
```

For the detailed configuration under the `spec`, please refer to the
[Sample Configuration](https://github.com/cloudwebmanage/cwm-keda-external-scaler#sample-configuration)
section.

The `cpu` or `memory` scaler can be configured like this:

```yaml
minio:
  # ...
  scaledobject:
    enabled: true
    type: cpu                   # Supported types: [cpu, memory]
    metricType: Utilization     # Supported metric types: [Utilization, Value, AverageValue]
    metricValue: "80"
```

Deploy: `helm upgrade -f .values.yaml --install cwm-worker-deployment-minio ./helm`

## Gateway Mode

In this mode, the Minio instance acts as a gateway to the other S3-compatible service.

### Gateway to other Minio instance

You can start a docker-compose environment which includes 2 minio instances -
one acting as the gateway and one as the source instance:

```shell
docker-compose -f docker-compose-gateway.yaml up --build
```

Log in to http://127.0.0.1:8080 using the gateway credentials (`12345678` / `12345678`).

Create a bucket and execute a shell in the source container to see the bucket there:

```shell
docker-compose -f docker-compose-gateway.yaml exec minio-source ls /opt
```

Upload/download some files and see log data in Redis:

```shell
docker-compose -f docker-compose-gateway.yaml exec redis redis-cli keys '*'
```

### Gateway to Google Cloud Storage

See [GATEWAY.md](./GATEWAY.md) for how to get the required credentials and set
them in env vars:

```shell
export GOOGLE_PROJECT_ID=
export GOOGLE_APPLICATION_CREDENTIALS_JSON='{}'
```

Start the `docker-compose` environment:

```shell
docker-compose -f docker-compose-gateway-google.yaml up --build
```

### Gateway to Azure Blob Storage

See [GATEWAY.md](./GATEWAY.md) for how to get the required credentials and set
them in env vars:

```shell
export AZURE_STORAGE_ACCOUNT_NAME=
export AZURE_STORAGE_ACCOUNT_KEY=
```

Start the `docker-compose` environment:

```shell
docker-compose -f docker-compose-gateway-azure.yaml up --build
```

### Gateway to AWS S3

See [GATEWAY.md](./GATEWAY.md) for how to get the required credentials and set
them in env vars:

```shell
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
```

Start the `docker-compose` environment:

```shell
docker-compose -f docker-compose-gateway-aws.yaml up --build
```

## Nginx Cache

It is an optional caching layer that acts as a CDN and caches download requests
for a given TTL.

### Testing the cache layer locally using Docker Compose

Set the following in `.env` file:

```text
CDN_CACHE_ENABLE=yes
```

Run the `docker-compose` environment:

```shell
docker-compose up -d --build
```

Create a bucket named `test` and upload some files.

Set the download bucket policy to allow unauthenticated download of files:

```shell
docker-compose exec minio-client mc policy set download minio/test
```

- Using the MinIO web UI, click on the share link for a file in the `test`
  bucket to get the direct download link.
- Copy the direct download link, modify the hostname to `localhost:8080` and
  download the file.
- Delete the file from the MinIO web UI.
- Try to download again from the direct download link.
- The file should be downloaded from the cache using the direct link.
- Wait for 1 minute, try to download the file again. It should not download
  because the cache is expired (default TTL is 1 minute).

## Testing virtual-style-host requests

Run the `docker-compose` environment:

```shell
docker-compose up -d --build
```

Create a bucket named `test` and upload a file e.g. `file.txt`.

Add this in `/etc/hosts` file:

```text
127.0.0.0 example001.com test.example001.com
```

Set the download bucket policy to allow unauthenticated download of files:

```shell
docker-compose exec minio-client mc policy set download minio/test
```

Using the MinIO web UI, click on the share link for a file in the `test` bucket
to get the direct download link.

Copy the direct download link and download it with `curl`.

With `path-style` request i.e. `http://domain/bucket/object`:

```shell
curl 'http://example001.com:8080/test/file.txt'
```

With `virtual-host-style` request i.e. `http://bucket.domain/object`:

```shell
curl 'http://test.example001.com:8080/file.txt'
```

## Certificate Challenge

To enable Let's Encrypt SSL certificate registration and renewal, the Nginx
proxy supports an http challenge response.

### Testing the challenge response using Docker Compose

Run the `docker-compose` environment:

```shell
docker-compose up -d --build
```

Verify that the challenge response returns the correct payload:

```shell
echo "$(curl -s "http://localhost:8080/.well-known/acme-challenge/$(cat tests/hostnames/hostname1.cc_token)")"
echo "$(cat tests/hostnames/hostname1.cc_payload)"
```

Access hostname3 which doesn't have a payload/token and verify it returns an error:

```shell
curl -H "Host: example003.com" "http://localhost:8080/.well-known/acme-challenge/$(cat tests/hostnames/hostname1.cc_token)"
```

## Running Tests

See [CI workflow](.github/workflows/ci.yml).

## Contribute

- Fork the project.
- Check out the latest `main` branch.
- Create a feature or bugfix branch from `main`.
- Commit and push your changes.
- Make sure to add tests.
- Submit the PR.

## License

[MIT](./LICENSE)
