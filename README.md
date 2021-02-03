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
- Create a file at `.values.yaml` with the following content:

```yaml
minio:
  image: minio
  tag: latest
  metricsLogger:
    image: metrics_logger
    tag: latest
    DEPLOYMENT_API_METRICS_FLUSH_INTERVAL_SECONDS: "5"
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
