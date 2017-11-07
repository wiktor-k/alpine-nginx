FROM alpine:3.5 AS builder

LABEL maintainer "Metacode <contact@metacode.biz>"

# https://www.libressl.org/releases.html
ENV LIBRESSL_VERSION 2.5.4

# https://www.libressl.org/signing.html
ENV LIBRESSL_SIGNING A1EB079B8D3EB92B4EBD3139663AF51BD5E4D8D5

# https://nginx.org/en/download.html
ENV NGINX_VERSION 1.13.2

# https://nginx.org/en/pgp_keys.html
ENV NGINX_SIGNING \
    A09CD539B8BB8CBE96E82BDFABD4D3B3F5806B4D \
    4C2C85E705DC730833990C38A9376139A524C53E \
    B0F4253373F8F6F510D42178520A9993A1C052F8 \
    65506C02EFC250F1B7A3D694ECF0E90B2C172083

RUN apk --update add \
        build-base \
        ca-certificates \
        gnupg \
        linux-headers \
        pcre-dev \
        wget \
        zlib-dev

# Download LibreSSL
RUN \
    mkdir -p /tmp/src/ssl && \
    cd /tmp/src/ssl && \
    wget \
        https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz \
        https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz.asc \
    && \
    gpg \
        --homedir /tmp/src/ssl --keyserver hkp://keyserver.ubuntu.com:80 --no-default-keyring --keyring /tmp/libressl.gpg \
        --recv-keys ${LIBRESSL_SIGNING} && \
    gpg \
        --homedir /tmp/src/ssl --keyserver hkp://keyserver.ubuntu.com:80 --no-default-keyring --keyring /tmp/libressl.gpg \
        --verify libressl-${LIBRESSL_VERSION}.tar.gz.asc && \
    tar -zxvf libressl-${LIBRESSL_VERSION}.tar.gz

# Download NginX
RUN \
    mkdir -p /tmp/src/nginx && \
    cd /tmp/src/nginx && \
    wget \
        https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
        https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc \
    && \
    gpg \
        --homedir /tmp/src/nginx --keyserver hkp://keyserver.ubuntu.com:80 --no-default-keyring --keyring /tmp/nginx.gpg \
        --recv-keys ${NGINX_SIGNING} && \
    gpg \
        --homedir /tmp/src/nginx --keyserver hkp://keyserver.ubuntu.com:80 --no-default-keyring --keyring /tmp/nginx.gpg \
        --verify nginx-${NGINX_VERSION}.tar.gz.asc && \
    tar -zxvf nginx-${NGINX_VERSION}.tar.gz

# Configure and install
RUN \
    cd /tmp/src/nginx/nginx-${NGINX_VERSION} && \
    ./configure \
        --with-cc-opt="-static -static-libgcc" \
        --with-ld-opt="-static" \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-http_v2_module \
        --with-openssl=/tmp/src/ssl/libressl-${LIBRESSL_VERSION} \
        --prefix=/nginx \
        --http-log-path=/dev/stdout \
        --error-log-path=/dev/stderr && \

    # with -j > 1 nginx's tries to link openssl before it gets built
    make -j1 && \
    make install

FROM alpine:3.5

COPY --from=builder /nginx /nginx

VOLUME ["/var/log/nginx"]

EXPOSE 80 443

CMD ["/nginx/sbin/nginx", "-g", "daemon off;"]
