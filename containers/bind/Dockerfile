ARG ALPINE_VERSION=3.20
FROM alpine:${ALPINE_VERSION}

LABEL org.opencontainers.image.description="BIND 9 provides software for Domain Name System (DNS) management including both defining domain names authoritatively for a given DNS zone, and recursively resolving domain names to their IP addresses. In addition to BIND 9's DNS server itself, named, this container also includes tools for performing DNS queries and dynamic updates."

ARG BIND_VERSION=9.18.27
RUN apk add --update --no-cache \
    bind~=${BIND_VERSION} \
    bind-dnssec-tools~=${BIND_VERSION}

VOLUME /var/named /etc/bind

EXPOSE 53/tcp 53/udp 953/tcp

ENTRYPOINT [ "/usr/sbin/named", "-u", "named" ]
CMD ["-c","/etc/bind/named.conf","-g"]
