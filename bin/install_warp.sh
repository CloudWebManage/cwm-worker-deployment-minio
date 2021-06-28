#!/usr/bin/env bash

TEMPDIR=`mktemp -d` &&\
curl -Lso $TEMPDIR/warp.tar.gz https://github.com/minio/warp/releases/download/v0.3.40/warp_0.3.40_Linux_x86_64.tar.gz &&\
cd $TEMPDIR && tar -xzvf warp.tar.gz && mv warp /usr/local/bin/ &&\
warp --version