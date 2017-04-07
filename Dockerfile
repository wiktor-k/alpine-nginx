FROM alpine:3.5

LABEL maintainer "Metacode <contact@metacode.biz>"

ENV NGINX_VERSION 1.11.12
ENV LIBRESSL_VERSION 2.5.1

RUN apk --update add \
        build-base \
        ca-certificates \
        linux-headers \
        pcre-dev \
        wget \
        zlib-dev \
    && \

    # Download LibreSSL
    mkdir -p /tmp/src/ssl && \
    cd /tmp/src/ssl && \
    wget https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz && \
    tar -zxvf libressl-${LIBRESSL_VERSION}.tar.gz && \

    # Download NginX
    mkdir -p /tmp/src/nginx && \
    cd /tmp/src/nginx && \
    wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
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
        linux-headers \
        pcre-dev \
        wget \
        zlib-dev \
    && \
    rm -rf /tmp/src && \
    rm -rf /var/cache/apk/* && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

VOLUME ["/var/log/nginx"]

EXPOSE 80 443

CMD ["/nginx/sbin/nginx", "-g", "daemon off;"]
