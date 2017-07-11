FROM alpine:3.5

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
        zlib-dev \
    && \

    # Download LibreSSL
    mkdir -p /tmp/src/ssl && \
    cd /tmp/src/ssl && \
    wget \
        https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz \
        https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz.asc \
    && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys ${LIBRESSL_SIGNING} && \
    gpg --verify libressl-${LIBRESSL_VERSION}.tar.gz.asc && \
    tar -zxvf libressl-${LIBRESSL_VERSION}.tar.gz && \

    # Download NginX
    mkdir -p /tmp/src/nginx && \
    cd /tmp/src/nginx && \
    wget \
        https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
        https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc \
    && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys ${NGINX_SIGNING} && \
    gpg --verify nginx-${NGINX_VERSION}.tar.gz.asc && \
    tar -zxvf nginx-${NGINX_VERSION}.tar.gz && \
    cd /tmp/src/nginx/nginx-${NGINX_VERSION} && \

    # Configure and install
    ./configure \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-http_v2_module \
        --with-openssl=/tmp/src/ssl/libressl-${LIBRESSL_VERSION} \
        --prefix=/nginx \
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=/var/log/nginx/error.log && \
    make && \
    make install && \

    # Remove build dependencies
    apk del \
        build-base \
        ca-certificates \
        gnupg \
        linux-headers \
        wget \
        zlib-dev \
    && \
    rm -rf /tmp/src && \
    rm -rf /var/cache/apk/* && \

    # Link logs to stdout & stderr for Docker
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

VOLUME ["/var/log/nginx"]

EXPOSE 80 443

CMD ["/nginx/sbin/nginx", "-g", "daemon off;"]
