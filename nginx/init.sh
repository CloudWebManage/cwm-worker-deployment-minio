#!/usr/bin/env bash

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

if [ "${CDN_CACHE_ENABLE}" == "yes" ]; then
  echo "CDN cache enabled"
  sed -i "s;proxy_cache_path /var/cache/nginx/minio/cache levels=1:2 keys_zone=minio:10m max_size=1g inactive=1m use_temp_path=on;proxy_cache_path ${CDN_CACHE_PROXY_PATH:-/var/cache/nginx/minio/cache} levels=1:2 keys_zone=minio:${CDN_CACHE_PROXY_KEYS_MAX_SIZE:-10m} max_size=${CDN_CACHE_PROXY_MAX_SIZE:-1g} inactive=${CDN_CACHE_PROXY_INACTIVE:-1m} use_temp_path=on;g" "${NGINX_SOURCES_DIR}/cache_server.conf"
  sed -i "s;proxy_temp_path /var/cache/nginx/minio/temp;proxy_temp_path ${CDN_CACHE_PROXY_TEMP_PATH:-/var/cache/nginx/minio/temp};g" "${NGINX_SOURCES_DIR}/cache_server.conf"

  function set_cache_location_config() {
    [ "${1}" != "" ] && sed -i "s;${2} ${3};${2} ${1};g" "${NGINX_SOURCES_DIR}/cache_location.conf"
  }

  set_cache_location_config "${CDN_CACHE_PROXY_BUFFERS}" proxy_buffers "8 16k"
  set_cache_location_config "${CDN_CACHE_PROXY_BUFFER_SIZE}" proxy_buffer_size "16k"
  set_cache_location_config "${CDN_CACHE_PROXY_BUSY_BUFFERS_SIZE}" proxy_busy_buffers_size "32k"
  set_cache_location_config "${CDN_CACHE_PROXY_CACHE_VALID_200}" "proxy_cache_valid 200" "1m"

  if [ "${CDN_CACHE_NOCACHE_REGEX}" == "" ]; then
    echo "" > "${NGINX_SOURCES_DIR}/cache_server_map_ext_nocache.conf"
  else
    echo 'map $basename $ext_nocache {' > "${NGINX_SOURCES_DIR}/cache_server_map_ext_nocache.conf"
    echo '    "~*'"${CDN_CACHE_NOCACHE_REGEX}"'" 1;' >> "${NGINX_SOURCES_DIR}/cache_server_map_ext_nocache.conf"
    echo '    default 0;' >> "${NGINX_SOURCES_DIR}/cache_server_map_ext_nocache.conf"
    echo '}' >> "${NGINX_SOURCES_DIR}/cache_server_map_ext_nocache.conf"
  fi
else
  echo "CDN cache disabled"
  echo "" > "${NGINX_SOURCES_DIR}/cache_server.conf"
  echo "" > "${NGINX_SOURCES_DIR}/cache_location.conf"
fi

echo "init OK"
exit 0
