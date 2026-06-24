FROM andrius/asterisk:latest

USER root

RUN apt-get update && apt-get install -y --no-install-recommends openssl gettext-base && rm -rf /var/lib/apt/lists/*

# Generate self-signed DTLS cert for WebRTC media
RUN mkdir -p /etc/asterisk/certs && \
    openssl req -x509 -newkey rsa:2048 -sha256 -days 365 -nodes \
      -keyout /etc/asterisk/certs/privkey.pem \
      -out /etc/asterisk/certs/fullchain.pem \
      -subj "/CN=asterisk-sip-poc" && \
    chmod 600 /etc/asterisk/certs/privkey.pem

COPY etc/asterisk/ /etc/asterisk.tmpl/
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 5060/tcp 5060/udp 8088/tcp 10000-10100/udp

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["asterisk", "-f", "-vvv"]
