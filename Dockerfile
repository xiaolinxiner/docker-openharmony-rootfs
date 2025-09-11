# syntax=docker/dockerfile:1
FROM alpine:3.22 AS curlbuilder
RUN apk update && \
    apk add build-base openssl-dev perl && \
    wget https://curl.se/download/curl-8.8.0.tar.gz && \
    tar -zxf curl-8.8.0.tar.gz && \
    cd curl-8.8.0/ && \
    ./configure --with-openssl --prefix=/opt/curl-musl && \
    make -j$(nproc) && \
    make install

FROM ubuntu:latest AS rootfsbuilder
WORKDIR /src
RUN apt update && apt install -y curl jq p7zip-full cpio xz-utils
COPY build-rootfs.sh build-rootfs.sh
COPY NOTICE.txt NOTICE.txt
COPY --from=curlbuilder /opt/curl-musl /opt/curl-musl
RUN sh build-rootfs.sh

FROM scratch AS final
COPY --from=rootfsbuilder /opt/ramdisk /
CMD ["/bin/sh"]
