# This base image should use a release date close to the main minio Dockerfile
FROM minio/mc:RELEASE.2021-11-05T10-05-06Z@sha256:d490755ededf4219f5d7abd313a3670813417635c60372cde441618c059b32ff
RUN mc || true
COPY entrypoint.sh .
ENTRYPOINT ["/entrypoint.sh"]
