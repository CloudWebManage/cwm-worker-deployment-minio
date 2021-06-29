# this base image should use a release date close to the base image in client/Dockerfile
FROM minio/minio:RELEASE.2021-06-09T18-51-39Z@sha256:88931f679647720b738849402abc841b2288513dc4d2821b1891c0f27e1d644d
COPY init.sh /root/init.sh
ENTRYPOINT ["sh"]
CMD ["/root/init.sh"]
