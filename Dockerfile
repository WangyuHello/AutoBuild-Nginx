FROM debian:bookworm-slim
# FROM arm64v8/debian:bookworm-slim

ARG NGINX_VERSION
ARG LIBRESSL_VERSION
ARG NGINX_SRC_DIR=/usr/local/src
ARG NGINX_HOME=/usr/local/nginx

ADD nginx.tar.gz ${NGINX_SRC_DIR}
ADD libressl.tar.gz ${NGINX_SRC_DIR}
ADD ./nginx-dav-ext-module/ ${NGINX_SRC_DIR}/nginx-dav-ext-module/
ADD ./ngx_brotli/ ${NGINX_SRC_DIR}/ngx_brotli/

RUN \
    apt-get update --no-install-recommends -y \
    && apt-get install -y gcc libpcre3 libpcre3-dev zlib1g zlib1g-dev libxml2 libxml2-dev libxslt-dev make gettext --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && ls -la ${NGINX_SRC_DIR} \
    && cd ${NGINX_SRC_DIR}/nginx-${NGINX_VERSION} && ./configure \
        --prefix=${NGINX_HOME} \
        --with-compat \
        --with-http_ssl_module \
        --with-stream \
        --with-stream_realip_module \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-threads \
        --with-file-aio \
        --with-http_addition_module \
        --with-http_stub_status_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-http_v3_module \
        --with-openssl=${NGINX_SRC_DIR}/libressl-{LIBRESSL_VERSION} \
        --add-module=${NGINX_SRC_DIR}/nginx-dav-ext-module \
        --add-module=${NGINX_SRC_DIR}/ngx_brotli \
    && cd ${NGINX_SRC_DIR}/nginx && make -j$(getconf _NPROCESSORS_ONLN) && make install

ENV PATH=$PATH:${NGINX_HOME}/sbin
EXPOSE 80 443
ENTRYPOINT [ "nginx", "-g", "daemon off;" ]
CMD ["-c", "/config/nginx.conf"]