#!/usr/bin/env bash

set -eE -o functrace

function failure() {
  local LINE=$1
  local CMD=$2
  echo "Failed at $LINE: $CMD"
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

echo "Running init script... [$(date)]"

MINIO_KMS_KES_KEY_NAME=${MINIO_KMS_KES_KEY_NAME:-'minio'}
CONFIG_FILE='kes-server-config.yaml'
CERTS_DIR="$PWD/certs"

export MINIO_KMS_KES_KEYS_DIR=${MINIO_KMS_KES_KEYS_DIR:-'./keys'}

# mTLS kes server
export SERVER_KEY_FILE="$CERTS_DIR/server.key"
export SERVER_CERT_FILE="$CERTS_DIR/server.cert"
./kes tool identity new \
  --server \
  --key $SERVER_KEY_FILE \
  --cert $SERVER_CERT_FILE \
  --ip '127.0.0.1' \
  --dns 'minio-kes' \
  --force

# mTLS minio server
MINIO_KEY_FILE="$CERTS_DIR/minio.key"
MINIO_CERT_FILE="$CERTS_DIR/minio.cert"
./kes tool identity new --force --key $MINIO_KEY_FILE --cert $MINIO_CERT_FILE minio

export MINIO_IDENTITY=$(./kes tool identity of $MINIO_CERT_FILE)

sed -i "s/__MINIO_KMS_KES_KEY_NAME__/$MINIO_KMS_KES_KEY_NAME/g" "$CONFIG_FILE"

echo "Configuration [$CONFIG_FILE]:"
echo '---'
cat "$CONFIG_FILE"
echo '---'

echo "Creating encryption key... [$MINIO_KMS_KES_KEY_NAME]"

# generate key locally for testing
# start server in background, generate key, and kill it
./kes server --config="$CONFIG_FILE" --auth=off >/dev/null &
sleep 0.1

export KES_CLIENT_KEY=$MINIO_KEY_FILE
export KES_CLIENT_CERT=$MINIO_CERT_FILE
./kes key delete -k "$MINIO_KMS_KES_KEY_NAME"
./kes key create -k "$MINIO_KMS_KES_KEY_NAME"

ls -hl "keys/$MINIO_KMS_KES_KEY_NAME"

# kill the kes server running in background
kill $(pidof kes)

echo 'Starting kes server...'
./kes server --config="$CONFIG_FILE" --auth=off
