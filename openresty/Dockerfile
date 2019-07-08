FROM openresty/openresty:stretch 

ADD ./build /build
RUN mv -f /build/html /usr/local/openresty/nginx/conf/html \
    && mv /build/nginx/* /build/waf /build/custom /usr/local/openresty/nginx/conf

RUN rm -rf /build

