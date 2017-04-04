FROM alpine:3.4

LABEL maintainer "Metacode <contact@metacode.biz>"

ENV NGINX_VERSION nginx-1.11.12

RUN apk --update add openssl-dev pcre-dev zlib-dev wget build-base ca-certificates && \
    mkdir -p /tmp/src && \
    cd /tmp/src && \
    wget https://nginx.org/download/${NGINX_VERSION}.tar.gz && \
    tar -zxvf ${NGINX_VERSION}.tar.gz && \
    cd /tmp/src/${NGINX_VERSION} && \
    ./configure \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-http_v2_module \
        --with-ipv6 \
        --prefix=/etc/nginx \
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=/var/log/nginx/error.log && \
    make && \
    make install && \
    apk del build-base openssl-dev zlib-dev && \
    rm -rf /tmp/src && \
    rm -rf /var/cache/apk/* && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

VOLUME ["/var/log/nginx"]

EXPOSE 80 443

CMD ["/etc/nginx/sbin/nginx", "-g", "daemon off;"]
