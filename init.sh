#!/bin/sh
ulimit -n 1024000 &&\
if [ "${CERTIFICATE_PEM}" != "" ] && [ "${CERTIFICATE_KEY}" != "" ]; then
  mkdir -p /etc/minio/certs &&\
  echo "${CERTIFICATE_PEM}" > /etc/minio/certs/public.crt &&\
  echo "${CERTIFICATE_KEY}" > /etc/minio/certs/private.key &&\
  exec /usr/bin/minio gateway nas --certs-dir /etc/minio/certs --address :8443 /storage/
else
  exec /usr/bin/minio gateway nas --address :8080 /storage/
fi
