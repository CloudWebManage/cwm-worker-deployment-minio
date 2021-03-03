FROM minio/minio:RELEASE.2021-03-01T04-20-55Z@sha256:0dfaf9af4fdb5db629221381d0f1e20cb5a15b3c42f1e28e89c71bf46078542f
COPY init.sh /root/init.sh
ENTRYPOINT ["sh"]
CMD ["/root/init.sh"]
