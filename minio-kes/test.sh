#!/bin/bash

set -eE -o functrace

function failure() {
  local LINE=$1
  local CMD=$2
  echo "Failed at $LINE: $CMD"
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

# --- script ---

ALIAS='minio'
BUCKET='bucket'
TEST_FILE='test.file'
TEST_DATA='test data'

mc alias set $ALIAS http://localhost:8080 12345678 12345678
mc mb $ALIAS/$BUCKET

echo "$TEST_DATA" > $TEST_FILE
mc mv -q $TEST_FILE $ALIAS/$BUCKET

echo 'Checking data with mc cat command via minio server...'
echo '---'
mc cat $ALIAS/$BUCKET/$TEST_FILE
echo '---'

echo 'Checking data with cat command from storage directly...'

MINIO_STORAGE_MOUNTPOINT=$(docker volume inspect -f '{{ .Mountpoint }}' cwm-worker-deployment-minio_storage)
echo "MINIO_STORAGE_MOUNTPOINT: $MINIO_STORAGE_MOUNTPOINT"

echo '---'
sudo cat "$MINIO_STORAGE_MOUNTPOINT/$BUCKET/$TEST_FILE"
echo
echo '---'

mc rb --force $ALIAS/$BUCKET

echo '--- [DONE] ---'
exit 0
