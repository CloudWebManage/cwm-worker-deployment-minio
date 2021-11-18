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
- [Generating self-signed certificates and DH key](#generating-self-signed-certificates-and-dh-key)
- [Running Tests](#running-tests)
- [Contribute](#contribute)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Local Development

Most of the following operations require minio client binary available locally at `./mc`

See [Install Minio Client](https://github.com/minio/mc/blob/master/docs/minio-client-complete-guide.md#1--download-minio-client) for details.

### Using Docker Compose

Docker Compose is used for quick prototyping of the deployment without using
Kubernetes.

The docker-compose examples use the following pattern:

* First, start the environment in the foreground so you can see the logs
* Then, open a new terminal to interact with the environment (usually using the minio client `./mc`)
* When done, press CTRL+C in the docker compose environment to stop the environment and remove all containers

Start the default stack:

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

Set an alias, create a bucket and upload a file

```
./mc alias set minio http://localhost:8080 12345678 12345678
./mc mb minio/test
./mc cp README.md minio/test/
```

List the contents of the bucket

```
./mc ls minio/test
```

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
- Start port-forwards to the nginx service:
  - `kubectl port-forward service/minio-nginx 8080:8080`
  - `kubectl port-forward service/minio-nginx 8443:8443`

Add aliases

```shell
./mc alias set http http://localhost:8080 dummykey dummypass
./mc alias set https https://localhost:8443 dummykey dummypass --insecure
```

Create a bucket and upload a file

```shell
./mc mb http/test
./mc cp README.md http/test/
```

List the files from https endpoint

```shell
./mc ls https/test --insecure
```

Set download policy on the bucket

```shell
./mc policy set download http/test
```

Add to /etc/hosts file:

```shell
127.0.0.1 example003.com example002.com
```

Check virtual hosts serving

```shell
curl -k -v https://example003.com:8443/test/README.md -o/dev/null 2>&1 | grep CN=example003.com
curl -k -v https://example002.com:8443/test/README.md -o/dev/null 2>&1 | grep CN=example002.com
```

Start Redis CLI and check the recorded metrics:

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

Add aliases for the instances:

```shell
./mc alias set source http://localhost:8080 accesskey secretkey
./mc alias set gateway http://localhost:8082 12345678 12345678
```

Create a bucket and upload a file to source insance:

```shell
./mc mb source/test
echo hi | ./mc pipe source/test/hello.txt
```

Get the file from gateway instance

```shell
./mc cat gateway/test/hello.txt
```

See log data in Redis:

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

Add mc alias

```shell
./mc alias set minio http://localhost:8080 12345678 12345678
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

Add mc alias

```shell
./mc alias set minio http://localhost:8080 12345678 12345678
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

Add mc alias

```shell
./mc alias set minio http://localhost:8080 12345678 12345678
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
docker-compose up --build
```

Add mc alias

```shell
./mc alias set minio http://localhost:8080 12345678 12345678
```

Create a bucket named `test` and upload a file:

```shell
./mc mb minio/test
./mc cp ./README.md minio/test/README.md
```

Try to download the file (it should fail):

```shell
curl http://localhost:8080/test/README.md
```

Set the download bucket policy to allow unauthenticated download of files:

```shell
./mc policy set download minio/test
```

Try to download the file (it should succeed):

```shell
curl http://localhost:8080/test/README.md
```

Download again and check the headers:

```shell
curl -v http://localhost:8080/test/README.md > /dev/null
```

You should see `X-Cache-Status: HIT`

Delete the file:

```shell
./mc rm minio/test/README.md
```

File should still be available from cache

Wait 1 minute for cache to expire, then file will not be available.

## Testing virtual-style-host requests

Run the `docker-compose` environment:

```shell
docker-compose up --build
```

Add mc alias, create a bucket, upload a file and set download policy

```shell
./mc alias set minio http://localhost:8080 12345678 12345678
./mc mb minio/test
./mc cp README.md minio/test/
./mc policy set download minio/test
```

Add this in `/etc/hosts` file:

```text
127.0.0.1 example001.com test.example001.com
```

Download with `path-style` request i.e. `http://domain/bucket/object`:

```shell
curl 'http://example001.com:8080/test/README.md'
```

With `virtual-host-style` request i.e. `http://bucket.domain/object`:

```shell
curl 'http://test.example001.com:8080/README.md'
```

## Generating self-signed certificates and DH key

The generated files are committed to Git, so you don't need to re-run the
following steps, but they are documented here for reference.

Generate DH Key

```
openssl dhparam -out tests/hostnames/dhparam.pem 2048
```

Generate self-signed certificates

```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tests/hostnames/hostname2.privkey \
  -out tests/hostnames/hostname2.fullchain \
  -subj "/C=IL/ST=Center/L=Tel-Aviv/O=Acme/OU=DevOps/CN=example002.com" &&\
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tests/hostnames/hostname3.privkey \
  -out tests/hostnames/hostname3.fullchain \
  -subj "/C=IL/ST=Center/L=Tel-Aviv/O=Acme/OU=DevOps/CN=example003.com" &&\
cp tests/hostnames/hostname3.fullchain tests/hostnames/hostname3.chain
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
