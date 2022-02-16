#!/bin/sh

echo init &&\
if [ "${CWM_METRICSLOGGER_HEALTH_URL}" != "" ] && [ "${SKIP_WAIT_FOR_AUDIT_WEBHOOK}" == "" ]; then
  echo "waiting for audit webhook ${CWM_METRICSLOGGER_HEALTH_URL}" &&\
  if [ "${CWM_INIT_DEBUG}" != "" ]; then
    while ! curl --fail --show-error --max-time "${CWM_INIT_CURL_MAX_TIME:-1.5}" "${CWM_METRICSLOGGER_HEALTH_URL}"; do sleep 1; done
  else
    while ! curl --fail --max-time "${CWM_INIT_CURL_MAX_TIME:-1.5}" -s "${CWM_METRICSLOGGER_HEALTH_URL}"; do sleep .01; done
  fi
fi &&\
echo setting ulimit &&\
ulimit -n 1024000 &&\
if [ "${INSTANCE_TYPE}" == "gateway_s3" ]; then
  echo "starting gateway s3 http" &&\
  exec /opt/bin/minio gateway s3 $MINIO_EXTRA_ARGS --address ":8080" $GATEWAY_ARGS
elif [ "${INSTANCE_TYPE}" == "gateway_gcs" ]; then
  echo "starting gateway gcs http" &&\
  export GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcs_credentials.json &&\
  echo "${GOOGLE_APPLICATION_CREDENTIALS_JSON}" > $GOOGLE_APPLICATION_CREDENTIALS &&\
  exec /opt/bin/minio gateway gcs $MINIO_EXTRA_ARGS --address ":8080" $GATEWAY_ARGS
elif [ "${INSTANCE_TYPE}" == "gateway_azure" ]; then
  echo "starting gateway azure http" &&\
  export AZURE_STORAGE_ACCOUNT="${AZURE_STORAGE_ACCOUNT_NAME}" &&\
  export AZURE_STORAGE_KEY="${AZURE_STORAGE_ACCOUNT_KEY}" &&\
  exec /opt/bin/minio gateway azure $MINIO_EXTRA_ARGS --address ":8080"
else
  echo "starting gateway nas http" &&\
  exec /opt/bin/minio gateway nas $MINIO_EXTRA_ARGS --address ":8080" /storage/
fi