#!/usr/bin/env bash

set -e

HOSTNAMES_DIR="${1}"
NGINX_SOURCES_DIR="${2}"
NGINX_CONFD_DIR="${3}"

DEFAULT_HTTP_CONF="$NGINX_SOURCES_DIR/http.conf"
DEFAULT_HTTPS_CONF="$NGINX_SOURCES_DIR/https.conf"

for filename in $(ls "${HOSTNAMES_DIR}"/*.name); do
  filename="$(basename "${filename}")" &&\
  host_id="$(echo "${filename%.*}")" &&\
  host_name="$(cat "${HOSTNAMES_DIR}/${host_id}.name")" &&\
  echo "${host_id} ${host_name}"

  if [ -f "$DEFAULT_HTTP_CONF" ]; then
    http_conf="$NGINX_CONFD_DIR/$host_id-http.conf"
    echo "setting up $http_conf"
    sed "s/__SERVER_NAME__/server_name ${host_name};/" "$DEFAULT_HTTP_CONF" > "$http_conf"
  fi

  if [ -f "$DEFAULT_HTTPS_CONF" ]; then
    key_filename="${HOSTNAMES_DIR}/${host_id}.key" &&\
    pem_filename="${HOSTNAMES_DIR}/${host_id}.pem"
    [ "$?" != "0" ] && echo "failed to setup hostname" && exit 1
    if [ -f "${key_filename}" ] && [ -f "${pem_filename}" ]; then
      https_conf="$NGINX_CONFD_DIR/$host_id-https.conf"
      echo "setting up $https_conf"
      sed "s/__SERVER_NAME__/server_name ${host_name};/" "$DEFAULT_HTTPS_CONF" > "$https_conf" &&\
      sed -i "s;__PEM__;${pem_filename};g" "$https_conf" &&\
      sed -i "s;__KEY__;${key_filename};g" "$https_conf"
      [ "$?" != "0" ] && echo "failed to setup https" && exit 1
    fi
  fi
done

echo "init OK"
exit 0
