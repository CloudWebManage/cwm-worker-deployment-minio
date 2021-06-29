# Minio Client

Minio client is a CLI tool for accessing and managing Minio instances

## Usage

Pull and tag the image for quick access (alternatively - build it from this directory)

```
docker pull docker.pkg.github.com/cloudwebmanage/cwm-worker-deployment-minio/client:latest &&\
docker tag docker.pkg.github.com/cloudwebmanage/cwm-worker-deployment-minio/client:latest mc
```

Run a command on a local minio instance:

```
docker run --network=host mc http://localhost:8080 12345678 12345678 "mc ls minio/"
```