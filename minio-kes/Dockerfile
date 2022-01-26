FROM alpine:latest
RUN apk add --no-cache bash

WORKDIR /kes

RUN wget https://github.com/minio/kes/releases/download/v0.17.6/kes-linux-amd64 && \
    mv kes-linux-amd64 kes && \
    chmod +x kes && \
    ./kes --version

EXPOSE 7373

COPY kes-server-config.yaml init.sh ./

ENTRYPOINT ["./init.sh"]
