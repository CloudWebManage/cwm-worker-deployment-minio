#!/usr/bin/env bash

docker pull docker.pkg.github.com/cloudwebmanage/cwm-worker-deployment-minio/minio:latest &&\
docker build --cache-from docker.pkg.github.com/cloudwebmanage/cwm-worker-deployment-minio/minio:latest -t minio . &&\
if docker pull docker.pkg.github.com/cloudwebmanage/cwm-worker-deployment-minio/metrics-logger:latest; then
  docker build --cache-from docker.pkg.github.com/cloudwebmanage/cwm-worker-deployment-minio/metrics-logger:latest -t metrics_logger metrics-logger
else
  docker build -t metrics_logger metrics-logger
fi
