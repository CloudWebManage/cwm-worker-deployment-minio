#!/bin/sh
echo init &&\
if [ "${MINIO_AUDIT_WEBHOOK_ENDPOINT_target1}" != "" ] && [ "${SKIP_WAIT_FOR_AUDIT_WEBHOOK}" == "" ]; then
  echo waiting for audit webhook "${MINIO_AUDIT_WEBHOOK_ENDPOINT_target1}" &&\
  if [ "${CWM_INIT_DEBUG}" != "" ]; then
    while ! curl --fail --show-error --max-time "${CWM_INIT_CURL_MAX_TIME:-1.5}" -XPOST --data '{}' "${MINIO_AUDIT_WEBHOOK_ENDPOINT_target1}"; do sleep 1; done
  else
    while ! curl --fail --max-time "${CWM_INIT_CURL_MAX_TIME:-1.5}" -sXPOST --data '{}' "${MINIO_AUDIT_WEBHOOK_ENDPOINT_target1}"; do sleep .01; done
  fi
fi &&\
echo setting ulimit &&\
ulimit -n 1024000 &&\
echo starting gateway nas http &&\
exec /usr/bin/minio gateway nas $MINIO_EXTRA_ARGS --address :8080 /storage/
