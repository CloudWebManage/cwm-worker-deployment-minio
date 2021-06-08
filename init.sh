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
if [ "${INSTANCE_TYPE}" == "gateway_s3" ]; then
  echo starting gateway s3 http &&\
  exec /usr/bin/minio gateway s3 $MINIO_EXTRA_ARGS --address :8080 $GATEWAY_ARGS
elif [ "${INSTANCE_TYPE}" == "gateway_gcs" ]; then
  echo starting gateway gcs http &&\
  export GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcs_credentials.json &&\
  echo "${GOOGLE_APPLICATION_CREDENTIALS_JSON}" > $GOOGLE_APPLICATION_CREDENTIALS &&\
  exec /usr/bin/minio gateway gcs $MINIO_EXTRA_ARGS --address :8080 $GATEWAY_ARGS
elif [ "${INSTANCE_TYPE}" == "gateway_azure" ]; then
  echo starting gateway gcs http &&\
  export MINIO_ROOT_USER="${AZURE_STORAGE_ACCOUNT_NAME}" &&\
  export MINIO_ROOT_PASSWORD="${AZURE_STORAGE_ACCOUNT_KEY}" &&\
  exec /usr/bin/minio gateway azure $MINIO_EXTRA_ARGS --address :8080
else
  echo starting gateway nas http &&\
  exec /usr/bin/minio gateway nas $MINIO_EXTRA_ARGS --address :8080 /storage/
fi
