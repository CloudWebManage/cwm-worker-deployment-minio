# pulled April 22, 2021
FROM nginx@sha256:75a55d33ecc73c2a242450a9f1cc858499d468f077ea942867e662c247b5e412
RUN rm /etc/nginx/conf.d/*.conf && mkdir /etc/nginx/certs && mkdir -p /var/cache/nginx/minio/cache /var/cache/nginx/minio/temp
COPY *.conf *.sh /etc/nginx/
ENTRYPOINT ["/etc/nginx/entrypoint.sh"]
