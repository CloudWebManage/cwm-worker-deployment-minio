# this base image should use a release date close to the base image in client/Dockerfile
FROM minio/minio:latest
COPY init.sh /root/init.sh
ENTRYPOINT ["sh"]
CMD ["/root/init.sh"]
