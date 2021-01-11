FROM minio/minio:RELEASE.2021-01-08T21-18-21Z@sha256:da9f5f03fceda58aa426de533d6f965377a42a8af163f17efaf78811e0a69931
COPY init.sh /root/init.sh
ENTRYPOINT ["sh"]
CMD ["/root/init.sh"]
