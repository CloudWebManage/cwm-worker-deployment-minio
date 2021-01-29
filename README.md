# cwm-worker-deployment-minio

## Local development

### Using Docker Compose

Docker Compose is used for quick prototyping of the deployment without using Kubernetes

Start the stack

```
docker-compose up --build
```

### Using Helm

* Install [Minikube](https://minikube.sigs.k8s.io/docs/) (latest stable version)
* Install [Helm](https://helm.sh/) (latest stable version)
* Start a local cluster: `minikube start --driver=docker --kubernetes-version=v1.16.14`
* Switch to the minikube docker env: `eval $(minikube -p minikube docker-env)`
* Build the Docker images: `docker-compose build`
* Create a file at `.values.yaml` with the following content:
```
minio:
  image: minio
  tag: latest
  metricsLogger:
    image: metrics_logger
    tag: latest
    DEPLOYMENT_API_METRICS_FLUSH_INTERVAL_SECONDS: "5"
``` 
* You can apply additional configurations to override the configuration at `helm/values.yaml`
* Deploy: `helm upgrade -f .values.yaml --install cwm-worker-deployment-minio ./helm`
* Verify that the minio pod is running: `kubectl get pods`
* Start port-forward to the minio service:
    * `kubectl port-forward service/minio 8080`
    * `kubectl port-forward service/minio 8443`
* Access it at localhost:8080 or https://localhost:8443
* Default username / password is `dummykey` / `dummypass`
* Create a bucket, upload / download some objects
* Start redis CLI and check the recorded metrics (`keys *` / `get KEY`)

## Running tests

See `.github/workflows/ci.yml`
