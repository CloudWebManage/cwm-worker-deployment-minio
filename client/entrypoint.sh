#!/usr/bin/env bash

URL="${1}"
ACCESSKEY="${2}"
SECRETKEY="${3}"
SCRIPT="${4}"

echo '{
  "version": "10",
  "aliases": {
    "minio": {
      "url": "'"${URL}"'",
      "accessKey": "'"${ACCESSKEY}"'",
      "secretKey": "'"${SECRETKEY}"'",
      "api": "s3v4",
      "path": "auto"
    }
  }
}' > /root/.mc/config.json &&\
eval "$SCRIPT"
