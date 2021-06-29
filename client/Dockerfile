# This base image should use a release date close to the main minio Dockerfile
FROM minio/mc:RELEASE.2021-06-13T17-48-22Z@sha256:bfd7b4c7751014233570e3fae765ccb7c65ac9e6346bd6effe6cfb1aa9ee6fc0
RUN mc || true
COPY entrypoint.sh .
ENTRYPOINT ["/entrypoint.sh"]
