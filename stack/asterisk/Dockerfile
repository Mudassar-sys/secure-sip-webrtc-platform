FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    asterisk \
    asterisk-config \
    asterisk-modules \
    asterisk-dev \
    ca-certificates \
    curl \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

# Copy config templates (environment variables substituted at startup)
COPY etc/asterisk/ /etc/asterisk.tmpl/
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 5060/tcp 5060/udp

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["asterisk", "-f", "-vvv"]
