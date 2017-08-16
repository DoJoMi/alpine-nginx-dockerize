FROM alpine:latest

MAINTAINER dojomi

RUN apk --update add pcre libbz2 ca-certificates libressl \
    && rm /var/cache/apk/* 

RUN adduser -h /etc/nginx -D -s /bin/sh nginx
WORKDIR /tmp

ENV NGINX_VERSION=1.12.1
ENV DOCKERIZE_VERSION v0.5.0
ENV PROXY_WORKER_PROCESSES 1
ENV PROXY_WORKER_CONNECTIONS 1024
ENV PROXY_PASS http://localhost


# add compilation env, build required C based gems and cleanup
RUN apk --update add --virtual build_deps build-base zlib-dev pcre-dev libressl-dev \
    && wget -O - https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | tar xzf - \
    && cd nginx-$NGINX_VERSION && ./configure \
       --prefix=/usr/share/nginx \
       --sbin-path=/usr/sbin/nginx \
       --conf-path=/etc/nginx/nginx.conf \
       --error-log-path=stderr \
       --http-log-path=/dev/stdout \
       --pid-path=/var/run/nginx.pid \
       --lock-path=/var/run/nginx.lock \
       --http-client-body-temp-path=/var/cache/nginx/client_temp \
       --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
       --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
       --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
       --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
       --user=nginx \
       --group=nginx \
       --with-http_addition_module \
       --with-http_auth_request_module \
       --with-http_gunzip_module \
       --with-http_gzip_static_module \
       --with-http_realip_module \
       --with-http_ssl_module \
       --with-http_stub_status_module \
       --with-http_sub_module \
       --with-http_v2_module \
       --with-threads \
       --with-stream \
       --with-stream_ssl_module \
       --without-http_memcached_module \
       --without-mail_pop3_module \
       --without-mail_imap_module \
       --without-mail_smtp_module \
       --with-pcre-jit \
       --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security' \
       --with-ld-opt='-Wl,-z,relro -Wl,--as-needed' \
    && make install \
    && cd .. && rm -rf nginx-$NGINX_VERSION \
    && mkdir /var/cache/nginx \
    && rm /etc/nginx/*.default \
    && wget -O /tmp/dockerize.tar.gz https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-linux-amd64-${DOCKERIZE_VERSION}.tar.gz \
    && tar -C /usr/local/bin -xzvf /tmp/dockerize.tar.gz \
    && rm -rf /tmp/dockerize.tar.gz \
    && apk del git \
               gcc \
               g++ \
               make \
    && apk del build_deps && rm /var/cache/apk/*

VOLUME ["/var/cache/nginx"]
EXPOSE 80 443

COPY nginx.conf.tmpl /etc/nginx/nginx.conf.tmpl
COPY conf.d/default.conf.tmpl /etc/nginx/conf.d/default.conf.tmpl

CMD dockerize -template /etc/nginx/nginx.conf.tmpl:/etc/nginx/nginx.conf -template /etc/nginx/conf.d/default.conf.tmpl:/etc/nginx/conf.d/default.conf -stdout /var/log/nginx/access.log -stderr /var/log/nginx/error.log /usr/sbin/nginx

