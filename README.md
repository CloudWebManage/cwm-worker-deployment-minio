# cwm-worker-deployment-minio

## Local development

### Prototyping

Docker Compose is used for quick prototyping of the deployment without using Kubernetes

Start the stack

```
docker-compose up --build
```

### Install

Install Kubectl

```
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" &&\
chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl
```

Install Minikube

```
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube &&\
sudo mv minikube /usr/local/bin/minikube
```

Install Helm

```
curl -Ls https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz -ohelm.tar.gz &&\
tar -xzvf helm.tar.gz && sudo mv linux-amd64/helm /usr/local/bin/helm &&\
sudo chmod +x /usr/local/bin/helm &&\
rm -rf linux-amd64 && rm helm.tar.gz &&\
helm version
```

### Deployment

Create a cluster

```
minikube start --driver=docker --kubernetes-version=v1.16.14
```

Verify connection to the cluster

```
kubectl get nodes
```

Deploy using one of the following options:

* Use the published Docker images:
  * Set your GitHub username and token in env vars:
    * `GITHUB_USER=`
    * `GITHUB_TOKEN=`
  * Create a docker pull secret
    * `echo '{"auths":{"docker.pkg.github.com":{"auth":"'"$(echo -n "${GITHUB_USER}:${GITHUB_TOKEN}" | base64)"'"}}}' | kubectl create secret generic github --type=kubernetes.io/dockerconfigjson --from-file=.dockerconfigjson=/dev/stdin`
  * Deploy
    * `helm upgrade --install cwm-worker-deployment-minio ./helm`

* Build your own Docker images:
  * Switch Docker daemon to use the minikube Docker daemon: `eval $(minikube -p minikube docker-env)`
  * Build the images:
    * `docker build -t docker.pkg.github.com/cloudwebmanage/cwm-worker-deployment-minio/minio .`
    * `docker build -t docker.pkg.github.com/cloudwebmanage/cwm-worker-deployment-minio/last_action_logger last_action_logger`
  * Deploy
    * `helm upgrade --install cwm-worker-deployment-minio ./helm`

Access Minio using port-forwards

```
kubectl port-forward service/minio 8080 8443
```

* http://localhost:8080
* https://localhost:8443

default username / password: `dummykey` / `dummypass`

Upload some files

Check the last action logger data in Redis

```
kubectl exec deployment/minio -c redis -- redis-cli get deploymentid:last_action:minio1
```

### Load test

Install warp

```
mkdir warp &&\
curl -Lso warp/warp.tar.gz https://github.com/minio/warp/releases/download/v0.3.17/warp_0.3.17_Linux_x86_64.tar.gz &&\
cd warp && tar -xzvf warp.tar.gz && sudo mv warp /usr/local/bin/ && rm -rf warp &&\
warp --version
```

Start the port forwards

```
kubectl port-forward service/minio 8080 8443
```

Run some benchmarks

```
warp mixed --host localhost:8080 --access-key dummykey --secret-key dummypass --objects 50 --duration 0m10s &&\
warp mixed --tls --insecure --host localhost:8443 --access-key dummykey --secret-key dummypass --objects 50 --duration 0m10s
```

