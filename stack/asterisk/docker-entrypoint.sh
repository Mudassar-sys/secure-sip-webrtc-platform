#!/bin/bash
set -e

# Substitute environment variables into all config templates
mkdir -p /etc/asterisk
for f in /etc/asterisk.tmpl/*.conf; do
    envsubst < "$f" > "/etc/asterisk/$(basename $f)"
done

exec "$@"
