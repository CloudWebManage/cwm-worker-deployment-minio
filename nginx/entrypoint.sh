#!/usr/bin/env bash

[ "${HOSTNAMES_DIR}" == "" ] && echo missing HOSTNAMES_DIR env var && exit 1

/etc/nginx/init.sh "${HOSTNAMES_DIR}" "/etc/nginx" "/etc/nginx/conf.d" &&\
exec nginx -g "daemon off;"
