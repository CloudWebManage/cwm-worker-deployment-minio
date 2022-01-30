FROM minio/kes:v0.17.6

EXPOSE 7373
COPY server-config.yaml init.sh ./
ENTRYPOINT ["./init.sh"]
