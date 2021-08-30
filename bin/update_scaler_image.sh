#!/usr/bin/env bash

# ---
# IMPORTANT: The ".image" file is updated automatically via the CI workflow.
#            DO NOT update it manually unless you really know what you're doing!
# ---

set -e

IMAGE_NAME="ghcr.io/cloudwebmanage/cwm-keda-external-scaler"
IMAGE_FILE="./helm/cwm-keda-external-scaler.image"
VALUES_FILE="./helm/values.yaml"

if test -f "$IMAGE_FILE"; then
  sed -i "s#$IMAGE_NAME#$(cat $IMAGE_FILE)#" $VALUES_FILE
  echo "INFO: Updated image! [$IMAGE_FILE] => [${VALUES_FILE}]"
else
  echo "WARN: Image file not found! [${IMAGE_FILE}]"
fi
