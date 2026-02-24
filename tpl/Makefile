#               __                     __
# .-----.-----.|__|.-----.--.--.______|  |.--.--.---.-.
# |     |  _  ||  ||     |_   _|______|  ||  |  |  _  |
# |__|__|___  ||__||__|__|__.__|      |__||_____|___._|
#       |_____|
#
# Copyright (c) 2023 Fabio Cicerchia. https://fabiocicerchia.it. MIT License
# Repo: https://github.com/fabiocicerchia/nginx-lua

EXTENDED_IMAGE=YES
NPROC := $(shell nproc)

# TODO: Find a better way to fallback when openresty is behind the nginx latest
# version and no patch is available.
FALLBACK_VER_NGINX=1.23.0

# ##############################################################################
# CORE
# ##############################################################################

openresty-patches:
	mkdir -p /nginx-${VER_NGINX}/patches
	git clone https://github.com/openresty/openresty.git; \
	PATCH_VER=${VER_NGINX}; \
	if [ "$(ls -1 openresty/patches/nginx-${VER_NGINX}-*.patch 2>/dev/null)" = "" ]; then \
		PATCH_VER=${FALLBACK_VER_NGINX}; \
	fi; \
	for patch_file in openresty/patches/nginx-$${PATCH_VER}-*.patch; do \
		echo "copying openresty patch $${patch_file}"; \
		cp "$${patch_file}" /nginx-${VER_NGINX}/patches/; \
	done; \
	for patch_file in /patches/*.patch; do \
		echo "overriding openresty patch $${patch_file}"; \
		cp "$${patch_file}" /nginx-${VER_NGINX}/patches/; \
	done; \
	cd /nginx-${VER_NGINX}; \
	for patch_file in patches/*.patch; do \
		echo "applying openresty patch $${patch_file}"; \
		patch -p1 < "$${patch_file}"; \
	done; \

core:
# NGINX
# ##############################################################################
# we're on an architecture upstream doesn't officially build for
# let's build binaries from the published packaging sources
	mkdir -p /var/cache/nginx/client_temp \
		/var/cache/nginx/proxy_temp \
		/var/cache/nginx/fastcgi_temp \
		/var/cache/nginx/uwsgi_temp \
		/var/cache/nginx/scgi_temp
	make openresty-patches
	cd /nginx-${VER_NGINX}; \
	sed -i '9i\#define LIBRESSL_VERSION_NUMBER' src/event/quic/ngx_event_quic_openssl_compat.h; \
	./configure ${NGINX_BUILD_CONFIG} --with-cc-opt="$(NGX_CFLAGS)" --with-ld-opt="$(NGX_LDOPT)" --with-debug \
	&& touch "/boringssl-${VER_BORINGSSL}/.openssl/include/openssl/ssl.h" \
	&& $(MAKE) build \
	&& mv objs/nginx objs/nginx-debug \
	&& ./configure ${NGINX_BUILD_CONFIG} --with-cc-opt="$(NGX_CFLAGS)" --with-ld-opt="$(NGX_LDOPT)" \
	&& touch "/boringssl-${VER_BORINGSSL}/.openssl/include/openssl/ssl.h" \
	&& $(MAKE) build \
	&& $(MAKE) modules \
	&& install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
	&& $(MAKE) install

# ##############################################################################
# DEPENDENCIES
# ##############################################################################

deps: dep-ngx_devel_kit dep-njs dep-geoip2 dep-boringssl
ifeq ($(EXTENDED_IMAGE), YES)
	$(MAKE) dep-headers-more-nginx-module \
		dep-nginx-dav-ext-module dep-nginx-brotli dep-nginx-zstd
endif

# NGX Devel Kit
# ##############################################################################
dep-ngx_devel_kit:
	curl -sLo /ngx_devel_kit.tar.gz https://github.com/vision5/ngx_devel_kit/archive/v${VER_NGX_DEVEL_KIT}.tar.gz
	tar -C / -xvzf /ngx_devel_kit.tar.gz

# njs
# ##############################################################################
dep-njs:
	curl -sLo /njs.tar.gz https://github.com/nginx/njs/archive/refs/tags/${VER_NJS}.tar.gz
	tar -C / -xvzf /njs.tar.gz

# geoip2
# ##############################################################################
dep-geoip2:
	mkdir -p /usr/lib64
	curl -sLo /geoip2.tar.gz https://github.com/leev/ngx_http_geoip2_module/archive/refs/tags/${VER_GEOIP}.tar.gz
	tar -C / -xvzf /geoip2.tar.gz

# LibreSSL
# ##############################################################################
dep-libressl:
	curl -sLo /libressl.tar.gz https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${VER_LIBRESSL}.tar.gz
	tar -C / -xvzf /libressl.tar.gz

# BoringSSL
# ##############################################################################
dep-boringssl:
	cd /boringssl-${VER_BORINGSSL} \
	&& mkdir build \
	&& cd /boringssl-${VER_BORINGSSL}/build \
	&& cmake -GNinja -DCMAKE_BUILD_TYPE=Release .. \
	&& ninja \
	&& mkdir -p /boringssl-${VER_BORINGSSL}/.openssl/lib \
	&& cd /boringssl-${VER_BORINGSSL}/.openssl \
	&& ln -s ../include include \
	&& cp /boringssl-${VER_BORINGSSL}/build/libcrypto.a /boringssl-${VER_BORINGSSL}/.openssl/lib \
	&& cp /boringssl-${VER_BORINGSSL}/build/libssl.a /boringssl-${VER_BORINGSSL}/.openssl/lib

# Dav Ext
# ##############################################################################
dep-nginx-dav-ext-module:
	curl -sLo /nginx-dav-ext-module.zip https://github.com/arut/nginx-dav-ext-module/archive/refs/tags/v${VER_NGINX_DAV_EXT_MODULE}.zip
	unzip -d / /nginx-dav-ext-module.zip

# Brotli
# ##############################################################################
dep-nginx-brotli:
	cd /ngx-brotli-${VER_NGINX_BROTLI}/deps/brotli \
	&& mkdir out && cd out \
	&& cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed .. \
	&& cmake --build . --config Release --target brotlienc

# Zstd
# ##############################################################################
dep-nginx-zstd:
	cd /zstd \
	&& make \
	&& make install

# OpenResty Headers
# ##############################################################################
dep-headers-more-nginx-module:
	curl -sLo /headers-more-nginx-module.zip https://github.com/openresty/headers-more-nginx-module/archive/v${VER_OPENRESTY_HEADERS}.zip
	unzip -d / /headers-more-nginx-module.zip
