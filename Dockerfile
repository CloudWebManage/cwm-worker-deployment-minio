FROM minio/minio@sha256:a8213a7c2d7a05813bdee6306886fd09378b516f11ef47022c95073add80d4ef
COPY init.sh /root/init.sh
ENTRYPOINT ["sh"]
CMD ["/root/init.sh"]
