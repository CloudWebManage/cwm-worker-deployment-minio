FROM minio/minio:RELEASE.2020-11-25T22-36-25Z@sha256:3e6952ea1c5be5517c381fd725ab0cb8b36a00c877fbb4f654f9afe366040624
COPY init.sh /root/init.sh
ENTRYPOINT ["sh"]
CMD ["/root/init.sh"]
