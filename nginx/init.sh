#!/usr/bin/env bash

HOSTNAMES_DIR="${1}"
NGINX_SOURCES_DIR="${2}"
NGINX_CONFD_DIR="${3}"

for filename in `ls "${HOSTNAMES_DIR}"/*.name`; do
  filename="$(basename "${filename}")" &&\
  host_id="$(echo "${filename%.*}")" &&\
  host_name="$(cat "${HOSTNAMES_DIR}/${host_id}.name")" &&\
  echo ${host_id} ${host_name} &&\
  sed "s/__SERVER_NAME__/server_name ${host_name};/" "${NGINX_SOURCES_DIR}/http.conf" > "${NGINX_CONFD_DIR}/${host_id}-http.conf" &&\
  key_filename="${HOSTNAMES_DIR}/${host_id}.key" &&\
  pem_filename="${HOSTNAMES_DIR}/${host_id}.pem"
  [ "$?" != "0" ] && echo failed to setup hostname && exit 1
  if [ -e "${key_filename}" ] && [ -e "${pem_filename}" ]; then
    sed "s/__SERVER_NAME__/server_name ${host_name};/" "${NGINX_SOURCES_DIR}/https.conf" > "${NGINX_CONFD_DIR}/${host_id}-https.conf" &&\
    sed -i "s;__PEM__;${pem_filename};g" "${NGINX_CONFD_DIR}/${host_id}-https.conf" &&\
    sed -i "s;__KEY__;${key_filename};g" "${NGINX_CONFD_DIR}/${host_id}-https.conf"
    [ "$?" != "0" ] && echo failed to setup https && exit 1
  fi
done

echo init OK
exit 0
