FROM alpine:3.8 AS builder

LABEL maintainer "Metacode <contact@metacode.biz>"

# https://www.openssl.org/source/
ENV OPENSSL_VERSION 1.1.1

# https://www.openssl.org/community/omc.html
ENV OPENSSL_SIGNING \
    8657ABB260F056B1E5190839D9C4D26D0E604491 \
    5B2545DAB21995F4088CEFAA36CEE4DEB00CFE33 \
    ED230BEC4D4F2518B9D7DF41F0DB4D21C1D35231 \
    C1F33DD8CE1D4CC613AF14DA9195C48241FBF7DD \
    7953AC1FBC3DC8B3B292393ED5E9E43F7DF9EE8C \
    E5E52560DD91C556DDBDA5D02064C53641C25E5D

# https://nginx.org/en/download.html
ENV NGINX_VERSION 1.15.3

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
        perl \
        pcre-dev \
        zlib-dev

# Download OpenSSL
RUN \
    mkdir -p /src/ssl && \
    cd /src/ssl && \
    wget \
        https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
        https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz.asc \
    && \
    gpg \
        --homedir /src/ssl --keyserver hkps://keyserver.ubuntu.com --no-default-keyring --keyring /src/openssl.gpg \
        --recv-keys ${OPENSSL_SIGNING} && \
    gpg \
        --homedir /src/ssl --keyserver hkps://keyserver.ubuntu.com --no-default-keyring --keyring /src/openssl.gpg \
        --no-auto-key-locate --verify openssl-${OPENSSL_VERSION}.tar.gz.asc

RUN cd /src/ssl && \
    tar -zxvf openssl-${OPENSSL_VERSION}.tar.gz

# Download NginX
RUN \
    mkdir -p /src/nginx && \
    cd /src/nginx && \
    wget \
        https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
        https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc \
    && \
    gpg \
        --homedir /src/nginx --keyserver hkps://keyserver.ubuntu.com --no-default-keyring --keyring /src/nginx.gpg \
        --recv-keys ${NGINX_SIGNING} && \
    gpg \
        --homedir /src/nginx --keyserver hkps://keyserver.ubuntu.com --no-default-keyring --keyring /src/nginx.gpg \
        --no-auto-key-locate --verify nginx-${NGINX_VERSION}.tar.gz.asc

RUN cd /src/nginx && \
    tar -zxvf nginx-${NGINX_VERSION}.tar.gz

# Configure and install
RUN \
    cd /src/nginx/nginx-${NGINX_VERSION} && \
    ./configure \
        --with-cc-opt="-static -static-libgcc" \
        --with-ld-opt="-static" \
        --with-http_auth_request_module \
        --with-http_gzip_static_module \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-openssl=/src/ssl/openssl-${OPENSSL_VERSION} \
        # Alpine uses musl that doesn't have `getcontext` so disable async
        # see: https://github.com/openssl/openssl/commit/52739e40ccc1b16cd966ea204bcfea3cc874fec8
        --with-openssl-opt=no-async \
        --prefix=/nginx \
        --http-log-path=/dev/stdout \
        --error-log-path=/dev/stderr && \
    # with -j > 1 nginx's tries to link openssl before it gets built
    make -j1 && \
    make install

FROM alpine:3.8

COPY --from=builder /nginx /nginx

VOLUME ["/var/log/nginx"]

EXPOSE 80 443

CMD ["/nginx/sbin/nginx", "-g", "daemon off;"]
