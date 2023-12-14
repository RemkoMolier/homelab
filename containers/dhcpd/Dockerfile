FROM alpine:3.19@sha256:51b67269f354137895d43f3b3d810bfacd3945438e94dc5ac55fdac340352f48

# renovate: datasource=repology depName=alpine_3_18/dhcp versioning=loose
ARG DHCP_VERSION="4.4.3_p1-r2"

RUN apk add --no-cache \
        dhcp-server-vanilla="${DHCP_VERSION}" && \
    touch /var/lib/dhcp/dhcpd.leases && \
    chown dhcp:dhcp /var/lib/dhcp/dhcpd.leases

EXPOSE 67/udp 67/tcp 
VOLUME /etc/dhcp

USER dhcp

HEALTHCHECK NONE

ENTRYPOINT [ "/usr/sbin/dhcpd" ]
CMD [ "-4", "-f", "-d", "--no-pid", "-cf", "/etc/dhcp/dhcpd.conf" ]