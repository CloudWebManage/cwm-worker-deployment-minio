#!/bin/sh
echo init &&\
if [ "${MINIO_AUDIT_WEBHOOK_ENDPOINT_target1}" != "" ]; then
  echo waiting for audit webhook "${MINIO_AUDIT_WEBHOOK_ENDPOINT_target1}" &&\
  while ! curl -sXPOST "${MINIO_AUDIT_WEBHOOK_ENDPOINT_target1}"; do sleep 1; done
fi &&\
echo setting ulimit &&\
ulimit -n 1024000 &&\
if [ "${CERTIFICATE_PEM}" != "" ] && [ "${CERTIFICATE_KEY}" != "" ]; then
  echo creating certificates &&\
  mkdir -p /etc/minio/certs &&\
  echo "${CERTIFICATE_PEM}" > /etc/minio/certs/public.crt &&\
  echo "${CERTIFICATE_KEY}" > /etc/minio/certs/private.key &&\
  echo starting gateway nas https &&\
  exec /usr/bin/minio gateway nas --certs-dir /etc/minio/certs --address :8443 /storage/
else
  echo starting gateway nas http &&\
  exec /usr/bin/minio gateway nas --address :8080 /storage/
fi
