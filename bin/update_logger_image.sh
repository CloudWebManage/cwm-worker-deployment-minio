#!/usr/bin/env bash

# ---
# IMPORTANT: The "cwm-worker-logger.image" is updated automatically via CI.
#            DO NOT update it manually unless you know what you're doing!
# ---

LOGGER_IMAGE_FILE="./helm/cwm-worker-logger.image"
VALUES_FILE="./helm/values.yaml"
if test -f "$LOGGER_IMAGE_FILE"; then
  sed -i "s#ghcr.io/cloudwebmanage/cwm-worker-logger/cwm-worker-logger#$(cat $LOGGER_IMAGE_FILE)#" $VALUES_FILE
  echo "INFO: Updated logger image! [$LOGGER_IMAGE_FILE] => [${VALUES_FILE}]"
else
  echo "WARN: Logger image file not found! [${LOGGER_IMAGE_FILE}]"
fi
