#!/usr/bin/env bash

[ "$HOSTNAMES_DIR" == "" ] && echo "missing HOSTNAMES_DIR env var" && exit 1

NGINX_SOURCES_DIR="/etc/nginx"
NGINX_CONFD_DIR="$NGINX_SOURCES_DIR/conf.d"

[ "$DISABLE_HTTP" == "true" ] && echo "HTTP is disabled!"
[ "$DISABLE_HTTPS" == "true" ] && rm -f "$NGINX_SOURCES_DIR/https.conf" && echo "HTTPS is disabled!"

/etc/nginx/init.sh "$HOSTNAMES_DIR" "$NGINX_SOURCES_DIR" "$NGINX_CONFD_DIR" &&\
exec nginx -g "daemon off;"
