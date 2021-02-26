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

Start the stack

```shell
docker-compose up --build
```

### Using Helm

- Install [Minikube](https://minikube.sigs.k8s.io/docs/) (latest stable version)
- Install [Helm](https://helm.sh/) (latest stable version)
- Start a local cluster: `minikube start --driver=docker --kubernetes-version=v1.16.14`
- Switch to the minikube docker env: `eval $(minikube -p minikube docker-env)`
- Build the Docker images: `docker-compose build`
- Build the cwm-worker-logger image: `docker build -t cwm-worker-logger ../cwm-worker-logger`
  - change the directory according to where you cloned [cwm-worker-logger](https://github.com/cloudwebmanage/cwm-worker-logger)
  - make sure you checked out the relevant version of cwm-worker-logger you want to test with (e.g. `git pull origin main` to get latest version)
- Create a file at `.values.yaml` with the following content:

```yaml
minio:
  image: minio
  tag: latest
  initDebugEnable: true
  metricsLogger:
    image: cwm-worker-logger
    tag: latest
    DEPLOYMENT_API_METRICS_FLUSH_INTERVAL_SECONDS: "5"
    LOG_LEVEL: debug
```

- You can apply additional configurations to override the configuration at `helm/values.yaml`
- Deploy: `helm upgrade -f .values.yaml --install cwm-worker-deployment-minio ./helm`
- Verify that the minio pod is running: `kubectl get pods`
- Start port-forward to the minio service:
  - `kubectl port-forward service/minio 8080`
  - `kubectl port-forward service/minio 8443`
- Access it at localhost:8080 or https://localhost:8443
- Default username / password is `dummykey` / `dummypass`
- Create a bucket, upload / download some objects
- Start redis CLI and check the recorded metrics (`keys *` / `get KEY`)
  - `kubectl exec deployment/minio -c redis -it -- redis-cli`
  - `keys *`
  - `get deploymentid:minio-metrics:minio1:num_requests_in`

### Manual testing of single pod per deployment

Single pod per deployment mode of the minio deployment is a bit more complex - it creates a separate pod for each container

Add the following to .values.yaml under minio:

```
serveSingleProtocolPerPod: true
```

Deploy the helm chart according to instructions for using Helm

- Verify that all 3 pods are running: `kubectl get pods`
- Start port-forward to the minio services:
  - `kubectl port-forward service/minio-http 8080`
  - `kubectl port-forward service/minio-https 8443`
- Access it at localhost:8080 or https://localhost:8443
  - (For this type of deployment the storage is not shared between http/https, because each minio container is in a separate pod)
- Default username / password is `dummykey` / `dummypass`
- Create a bucket, upload / download some objects
- Start redis CLI and check the recorded metrics (`keys *` / `get KEY`)
  - `kubectl exec deployment/minio-logger -c redis -it -- redis-cli`
  - `keys *`
  - `get deploymentid:minio-metrics:minio1:num_requests_in`

### Manual testing of log providers

For these tests we will use AWS to provide all the required log backends

#### Elasticsearch

* Amazon Elasticsearch -> Create a new domain
  * Deployment type: Development and testing
  * Elasticsearch version: 7.9
  * Elasticsearch domain name: cwm-worker-logger-tests
  * Instance type: t2.small.elasticsearch
  * Network configuration: public access
  * Domain access policy: custom: ipv4 address: allow your IP

Add the following to .values.yaml under metricsLogger with the relevant values:

```
LOG_PROVIDER: elasticsearch
ES_HOST: 
ES_PORT:
```

Deploy the helm chart according to instructions for using Helm

#### S3

* Amazon S3 -> Create bucket

Add the following to .values.yaml under metricsLogger with the relevant values:

```
LOG_PROVIDER: s3
AWS_KEY_ID: 
AWS_SECRET_KEY:
S3_BUCKET_NAME:
S3_REGION:
```

Deploy the helm chart according to instructions for using Helm

#### Logger disabled

This disables the logger pod and runs without logging

Add the following to .values.yaml:

```
# under minio:
  auditWebhookEndpoint: ""

# under metricsLogger:
    enable: false
```

Deploy the helm chart according to instructions for using Helm 

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
