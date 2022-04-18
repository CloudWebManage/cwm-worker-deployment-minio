#!/usr/bin/env bash

set -eE -o functrace

function failure() {
  local LINE=$1
  local CMD=$2
  echo "Failed at $LINE: $CMD"
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

echo "Running init script... [$(date)]"

CONFIG_FILE='server-config.yaml'
MINIO_KES_DIR='/minio-kes'

if [[ ! -f $CONFIG_FILE ]]; then
  echo "[ERROR] Configuration file not found! [$CONFIG_FILE]"
  exit 1
fi

if [[ ! -d $MINIO_KES_DIR ]]; then
  echo "[ERROR] '$MINIO_KES_DIR' directory not found!"
  exit 1
fi

echo 'Generating TLS private key and certificate for KES Server...'
export SERVER_KEY_FILE="$MINIO_KES_DIR/server.key"
export SERVER_CERT_FILE="$MINIO_KES_DIR/server.cert"
./kes tool identity new \
  --force \
  --server \
  --key $SERVER_KEY_FILE \
  --cert $SERVER_CERT_FILE \
  --ip '127.0.0.1' \
  --dns 'minio-kes' # DNS = service name in the docker-compose-sse.yaml

echo 'Generating TLS private key and certificate for MinIO...'
MINIO_KEY_FILE="$MINIO_KES_DIR/minio.key"
MINIO_CERT_FILE="$MINIO_KES_DIR/minio.cert"
./kes tool identity new --force --key $MINIO_KEY_FILE --cert $MINIO_CERT_FILE minio

export MINIO_IDENTITY=$(./kes tool identity of $MINIO_CERT_FILE)

echo "Configuration [$CONFIG_FILE]:"
echo '---'
cat "$CONFIG_FILE"
echo '---'

echo 'Starting kes server...'
./kes server --config "$CONFIG_FILE" --auth off
