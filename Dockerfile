# this base image should use a release date close to the base image in client/Dockerfile
FROM minio/minio:RELEASE.2021-11-09T03-21-45Z@sha256:8280c3910b43aeafc0ceabde28aaf2346575d4003cf2dec955a22d7cd5e94c55
COPY init.sh /root/init.sh
ENV MINIO_BROWSER "off"
ENV MINIO_UPDATE "off"
ENTRYPOINT ["sh"]
CMD ["/root/init.sh"]
