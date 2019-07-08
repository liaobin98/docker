FROM debian:stretch
MAINTAINER wenbin[IM:4590]

ADD ./build /build
RUN useradd keepalived_script && mkdir -p /etc/keepalived/conf.d

RUN mv /build/keepalived.conf /etc/keepalived \
    && mv /build/check_port.sh /etc/keepalived \
    && mv /build/docker-entrypoint.sh /docker-entrypoint.sh 

RUN chmod +x /docker-entrypoint.sh \
    && chmod +x /etc/keepalived/check_port.sh


RUN apt-get update \
    && apt-get upgrade \
    && apt-get install -y keepalived netcat procps \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /src/*.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /build

CMD ["/docker-entrypoint.sh"]
