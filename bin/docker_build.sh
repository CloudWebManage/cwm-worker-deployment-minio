#!/usr/bin/env bash

docker pull docker.pkg.github.com/cloudwebmanage/cwm-worker-deployment-minio/minio:latest &&\
docker build --cache-from docker.pkg.github.com/cloudwebmanage/cwm-worker-deployment-minio/minio:latest -t minio .
