# https://github.com/fabiocicerchia/nginx-lua/blob/main/nginx/1.25.4/debian/12.5/Dockerfile
#               __                     __
# .-----.-----.|__|.-----.--.--.______|  |.--.--.---.-.
# |     |  _  ||  ||     |_   _|______|  ||  |  |  _  |
# |__|__|___  ||__||__|__|__.__|      |__||_____|___._|
#       |_____|
#
# Copyright (c) 2023 Fabio Cicerchia. https://fabiocicerchia.it. MIT License
# Repo: https://github.com/fabiocicerchia/nginx-lua

ARG ARCH=
ARG DISTRO=ubuntu
ARG DISTRO_VER=25.04
ARG IMAGE_NAME=

#############################
# Settings Common Variables #
#############################
FROM ${ARCH}/$DISTRO:$DISTRO_VER AS base

ARG ARCH=
ENV ARCH=$ARCH

ENV DOCKER_IMAGE=${IMAGE_NAME}
ENV DOCKER_IMAGE_OS=${DISTRO}
ENV DOCKER_IMAGE_TAG=${DISTRO_VER}

ARG BUILD_DATE
ENV BUILD_DATE=$BUILD_DATE
ARG VCS_REF
ENV VCS_REF=$VCS_REF

# NGINX
################################################################################

# nginx
# https://nginx.org/en/download.html
ARG VER_NGINX=1.29.0
ENV VER_NGINX=$VER_NGINX

# NGINX MODULES
################################################################################

# ngx_devel_kit
# https://github.com/vision5/ngx_devel_kit
# The NDK is now considered to be stable.
ARG VER_NGX_DEVEL_KIT=0.3.4
ENV VER_NGX_DEVEL_KIT=$VER_NGX_DEVEL_KIT

# njs
# https://github.com/nginx/njs
ARG VER_NJS=0.9.1
ENV VER_NJS=$VER_NJS

# geoip2
# https://github.com/leev/ngx_http_geoip2_module
ARG VER_GEOIP=3.4
ENV VER_GEOIP=$VER_GEOIP

ARG LD_LIBRARY_PATH=/usr/local/lib/
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH

# libressl
# http://www.libressl.org/releases.html
ARG VER_LIBRESSL=4.0.0
ENV VER_LIBRESSL=$VER_LIBRESSL

# BoringSSL
# https://boringssl.googlesource.com/boringssl
ARG VER_BORINGSSL=d55aba9db303cf2b445b29645c941671bc7ffdf8
ENV VER_BORINGSSL=$VER_BORINGSSL

# nginx brotli
# https://github.com/google/ngx_brotli
ARG VER_NGINX_BROTLI=a71f9312c2deb28875acc7bacfdd5695a111aa53
ENV VER_NGINX_BROTLI=$VER_NGINX_BROTLI

# nginx zstd
# https://github.com/HanadaLee/ngx_http_zstd_module
ARG VER_NGINX_ZSTD=87f3302e72e0faf721db0cc9462d0a9b960e4061
ENV VER_NGINX_ZSTD=$VER_NGINX_ZSTD

# nginx-dav-ext-module
# https://github.com/arut/nginx-dav-ext-module
ARG VER_NGINX_DAV_EXT_MODULE=3.0.0
ENV VER_NGINX_DAV_EXT_MODULE=$VER_NGINX_DAV_EXT_MODULE

# headers-more-nginx-module
# https://github.com/openresty/headers-more-nginx-module
ARG VER_OPENRESTY_HEADERS=0.39
ENV VER_OPENRESTY_HEADERS=$VER_OPENRESTY_HEADERS

################################################################################

# Replicate same official env variable
ENV NGINX_VERSION=$VER_NGINX
ENV NJS_VERSION=$VER_NJS
ENV PKG_RELEASE=1~$DISTRO_VER

# References:
#  - https://developers.redhat.com/blog/2018/03/21/compiler-and-linker-flags-gcc
#  - https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html
# -g                        Generate debugging information
# -O2                       Recommended optimizations
# -fstack-protector-strong  Stack smashing protector
# -Wformat                  Check calls to make sure that the arguments supplied have types appropriate to the format string specified
# -Werror=format-security   Reject potentially unsafe format string arguents
# -Wp,-D_FORTIFY_SOURCE=2   Run-time buffer overflow detection
# -fPIC                     No text relocations
# ORIGINAL VALUE: -g -O2 -ffile-prefix-map=/data/builder/debuild/nginx-1.23.3/debian/debuild-base/nginx-1.23.3=. -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC
ARG NGX_CFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -flto -funroll-loops -ffunction-sections -fdata-sections -U_FORTIFY_SOURCE -Wp,-D_FORTIFY_SOURCE=2 -fPIC -I /boringssl-$VER_BORINGSSL/include"
ENV NGX_CFLAGS=$NGX_CFLAGS
# References
#  - https://developers.redhat.com/blog/2018/03/21/compiler-and-linker-flags-gcc
#  - https://wiki.debian.org/ToolChain/DSOLinking#Unresolved_symbols_in_shared_libraries
#  - https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_node/ld_3.html
#  - https://linux.die.net/man/1/ld
# -Wl,-rpath,/usr/local/lib   Add a directory to the runtime library search path
# -Wl,-z,relro                Read-only segments after relocation
# -Wl,-z,now                  Disable lazy binding
# -Wl,--as-needed             Only link with needed libraries
# -pie                        Full ASLR for executables
# ORIGINAL VALUE: -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie
ARG NGX_LDOPT="-Wl,-rpath,/usr/local/lib -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie -Wl,-Bsymbolic-functions -lstdc++ -L/boringssl-$VER_BORINGSSL/build/ssl -L/boringssl-$VER_BORINGSSL/build/crypto"
ENV NGX_LDOPT=$NGX_LDOPT
# Reference: http://nginx.org/en/docs/configure.html
ARG NGINX_BUILD_CONFIG="\
            --prefix=/etc/nginx \
            --sbin-path=/usr/sbin/nginx \
            --modules-path=/usr/lib/nginx/modules \
            --conf-path=/etc/nginx/nginx.conf \
            --error-log-path=/var/log/nginx/error.log \
            --http-log-path=/var/log/nginx/access.log \
            --pid-path=/var/run/nginx.pid \
            --lock-path=/var/run/nginx.lock \
            --http-client-body-temp-path=/var/cache/nginx/client_temp \
            --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
            --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
            --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
            --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
            --with-perl_modules_path=/usr/lib/perl5/vendor_perl \
            --user=nginx \
            --group=nginx \
            `# OFFICIAL MODULES` \
            --with-compat \
            --with-file-aio \
            --with-threads \
            --with-http_addition_module \
            --with-http_auth_request_module \
            --with-http_dav_module \
            --with-http_flv_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_mp4_module \
            --with-http_random_index_module \
            --with-http_realip_module \
            --with-http_secure_link_module \
            --with-http_slice_module \
            --with-http_ssl_module \
            --with-http_stub_status_module \
            --with-http_sub_module \
            --with-http_v2_module \
            --with-http_v3_module \
            --with-ipv6 \
            --with-mail \
            --with-mail_ssl_module \
            --with-stream \
            --with-stream_realip_module \
            --with-stream_ssl_module \
            --with-stream_ssl_preread_module \
            `# CUSTOM MODULES` \
            `#--with-openssl=/libressl-${VER_LIBRESSL}` \
            --with-openssl=/boringssl-${VER_BORINGSSL} \
            --add-module=/headers-more-nginx-module-${VER_OPENRESTY_HEADERS} \
            --add-module=/ngx_devel_kit-${VER_NGX_DEVEL_KIT} \
            --add-module=/ngx_http_geoip2_module-${VER_GEOIP} \
            `--add-module=/njs-${VER_NJS}/nginx` \
            --add-module=/nginx-dav-ext-module-${VER_NGINX_DAV_EXT_MODULE} \
            --add-module=/ngx-brotli-${VER_NGINX_BROTLI} \
            --add-module=/ngx-zstd-${VER_NGINX_ZSTD} \
"
ENV NGINX_BUILD_CONFIG=$NGINX_BUILD_CONFIG

ARG BUILD_DEPS_BASE="\
        ca-certificates \
        curl \
        g++ \
        libmaxminddb-dev \
        libpcre3-dev \
        libssl-dev \
        libxml2-dev \
        libxslt1-dev \
        make \
        patch \
        unzip \
        zlib1g-dev \
        cmake \
        ninja-build \
"
ENV BUILD_DEPS_BASE=$BUILD_DEPS_BASE
ARG BUILD_DEPS_AMD64="\
        ${BUILD_DEPS_BASE} \
"
ENV BUILD_DEPS_AMD64=$BUILD_DEPS_AMD64
ARG BUILD_DEPS_ARM64V8="\
        ${BUILD_DEPS_BASE} \
"
ENV BUILD_DEPS_ARM64V8=$BUILD_DEPS_ARM64V8
ENV BUILD_DEPS=

ARG NGINX_BUILD_DEPS="\
# OPENRESTY PATCHES
        git \
"
ENV NGINX_BUILD_DEPS=$NGINX_BUILD_DEPS

ENV DEBIAN_FRONTEND=noninteractive

####################################
# Build Nginx                      #
####################################
FROM base AS builder

# hadolint ignore=SC2086
RUN set -eux \
    && eval BUILD_DEPS="\$$(echo BUILD_DEPS_${ARCH} | tr '[:lower:]' '[:upper:]')" \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        apt-utils \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        $BUILD_DEPS \
        $NGINX_BUILD_DEPS \
    && rm -rf /var/lib/apt/lists/*

COPY tpl/Makefile Makefile
COPY tpl/patches patches
COPY nginx-${VER_NGINX} /nginx-${VER_NGINX}
COPY boringssl-${VER_BORINGSSL} /boringssl-${VER_BORINGSSL}
COPY zstd /zstd
COPY ngx-zstd-${VER_NGINX_ZSTD} /ngx-zstd-${VER_NGINX_ZSTD}
COPY ngx-brotli-${VER_NGINX_BROTLI} /ngx-brotli-${VER_NGINX_BROTLI}

RUN make -j4 deps \
    && make -j4 core

##########################################
# Combine everything with minimal layers #
##########################################
FROM base

# http://label-schema.org/rc1/
ARG PKG_DEPS="\
        ca-certificates \
        libmaxminddb-dev \
        libpcre3-dev \
        libssl-dev \
        libxml2-dev \
        unzip \
        zlib1g-dev \
"
ENV PKG_DEPS=$PKG_DEPS

COPY --from=builder --chown=1000:1000 /etc/nginx /etc/nginx
COPY --from=builder --chown=1000:1000 /usr/local/lib /usr/local/lib
COPY --from=builder --chown=1000:1000 /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder --chown=1000:1000 /usr/sbin/nginx-debug /usr/sbin/nginx-debug
COPY --from=builder --chown=1000:1000 /var/cache/nginx /var/cache/nginx

COPY --chown=1000:1000 --chmod=755 tpl/??-*.sh /docker-entrypoint.d/
COPY --chown=1000:1000 --chmod=755 tpl/default.conf /etc/nginx/conf.d/default.conf
COPY --chown=1000:1000 --chmod=755 tpl/docker-entrypoint.sh /
COPY --chown=1000:1000 --chmod=755 tpl/nginx.conf /etc/nginx/nginx.conf
COPY --chown=1000:1000 --chmod=755 tpl/support.sh /

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=SC2086
RUN set -eux \
    && sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/' /etc/apt/sources.list.d/ubuntu.sources \
    && sed -i 's/security.ubuntu.com/mirrors.ustc.edu.cn/' /etc/apt/sources.list.d/ubuntu.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        $PKG_DEPS \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/log/nginx

RUN set -x \
# create nginx user/group first, to be consistent throughout docker variants
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y gnupg1 ca-certificates \
    && apt-get install --no-install-recommends --no-install-suggests -y \
                        gettext-base \
                        curl \
    && apt-get remove --purge --auto-remove -y && rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/nginx.list \
    \
# if we have leftovers from building, let's purge them (including extra, unnecessary build deps)
#    && if [ -n "$tempDir" ]; then \
#        apt-get purge -y --auto-remove \
#        && rm -rf "$tempDir" /etc/apt/sources.list.d/temp.list; \
#    fi \
# forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Upgrade software to latest version
# ##############################################################################
RUN apt-get upgrade -y \
# Cleanup
# ##############################################################################
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# smoke test
# ##############################################################################
RUN envsubst -V \
    && nginx -V \
    && nginx -t

EXPOSE 80 443

# HEALTHCHECK --interval=30s --timeout=3s CMD curl --fail http://localhost/ || exit 1

# Override stop signal to stop process gracefully
STOPSIGNAL SIGQUIT

ENTRYPOINT ["/docker-entrypoint.sh"]

# USER ubuntu

CMD ["nginx", "-g", "daemon off;", "-c", "/etc/nginx/nginx.conf"]
