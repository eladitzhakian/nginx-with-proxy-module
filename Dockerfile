FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential libssl-dev ca-certificates wget git \
  libpcre3 libpcre3-dev zlib1g zlib1g-dev \
  && apt-get clean

WORKDIR /tmp
RUN git clone --depth=1 https://github.com/chobits/ngx_http_proxy_connect_module.git ngx_http_proxy_connect_module \
  && wget -q https://openresty.org/download/openresty-1.25.3.1.tar.gz \
  && tar xf openresty-1.25.3.1.tar.gz \
  && cd openresty-1.25.3.1/bundle/nginx-1.25.3 \
  && patch -p1 < ../../../ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_102101.patch \
  && cd ../.. \
  && ./configure --prefix=/opt/openresty \
    --without-http_ssi_module \
    --without-http_userid_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module \
    --with-http_sub_module \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_gzip_static_module \
    --with-http_gunzip_module \
    --with-http_realip_module \
    --with-http_stub_status_module \
    --with-select_module \
    --with-poll_module \
    --with-file-aio \
    --with-pcre-jit \
    --add-module=../ngx_http_proxy_connect_module \
  && make install \
  && ln -sf /dev/stdout /opt/openresty/nginx/logs/access.log \
  && ln -sf /dev/stderr /opt/openresty/nginx/logs/error.log


STOPSIGNAL SIGQUIT

ENV PATH="$PATH:/opt/openresty/luajit/bin:/opt/openresty/nginx/sbin:/opt/openresty/bin"

EXPOSE 80

CMD ["/opt/openresty/bin/openresty", "-g", "daemon off;"]
