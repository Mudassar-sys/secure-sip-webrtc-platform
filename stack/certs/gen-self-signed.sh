#!/bin/bash
# Generate self-signed TLS certificates for prototype use.
# Replace with real certs (Let's Encrypt / ACME) for production.
set -e

DOMAIN=${1:-localhost}
DAYS=365

echo "Generating self-signed cert for: $DOMAIN"

openssl req -x509 -newkey rsa:4096 -sha256 -days $DAYS \
  -nodes \
  -keyout privkey.pem \
  -out fullchain.pem \
  -subj "/CN=$DOMAIN" \
  -addext "subjectAltName=DNS:$DOMAIN,DNS:localhost,IP:127.0.0.1"

echo "Done. Files: fullchain.pem + privkey.pem"
echo "To use real certs: replace with Let's Encrypt output (same filenames)."
