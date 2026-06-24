#!/bin/bash
set -e

mkdir -p /etc/asterisk

# Only substitute env vars in pjsip.conf (has ${ALICE_PASS}, ${BOB_PASS})
# All other files are copied verbatim to preserve Asterisk's own ${EXTEN} etc.
for f in /etc/asterisk.tmpl/*.conf; do
    base=$(basename "$f")
    if [ "$base" = "pjsip.conf" ]; then
        envsubst '${ALICE_PASS} ${BOB_PASS}' < "$f" > "/etc/asterisk/$base"
    else
        cp "$f" "/etc/asterisk/$base"
    fi
done

exec "$@"
