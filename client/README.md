# MinIO Client

[MinIO client](https://docs.min.io/docs/minio-client-complete-guide.html) is a
CLI tool for accessing and managing MinIO instances.

## Usage

Pull and tag the image for quick access (alternatively, build it from this
directory):

```shell
docker pull docker.pkg.github.com/cloudwebmanage/cwm-worker-deployment-minio/client:latest &&\
docker tag docker.pkg.github.com/cloudwebmanage/cwm-worker-deployment-minio/client:latest mc
```

Run a command on a local MinIO instance:

```shell
docker run --network=host mc http://localhost:8080 12345678 12345678 "mc ls minio/"
```
