# Secure SIP & WebRTC Platform - Runnable Stack

One-command containerized proof of concept for the layered Kamailio-fronted SIP architecture.
Tested on Ubuntu 22.04 LTS (Scaleway/Hetzner cloud servers).

---

## What this stack includes

| Container | Role |
|-----------|------|
| `kamailio` | Internet-facing SBC - anti-flood, auth, topology hiding, WSS/TLS |
| `rtpengine` | Media relay - DTLS-SRTP to SRTP bridge, ICE, media anchoring |
| `asterisk` | Call engine - PJSIP, per-tenant dialplan, fraud guards |
| `coturn` | STUN/TURN server for WebRTC NAT traversal |
| `fail2ban` | Reads Kamailio logs, bans at iptables level |
| `mysql` | Subscriber database (usrloc, auth, dispatcher) |
| `redis` | Shared rate counters and IP ban tables across edge nodes |
| `web` | Nginx serving the JsSIP WebRTC softphone |
| `homer-webapp` | SIP call capture and search UI (Homer/HEP) |

---

## Prerequisites

Fresh Ubuntu 22.04 server with:
- At least 2 vCPU / 4 GB RAM
- Ports open: 22 (SSH), 80, 443, 5060 (UDP+TCP), 5061 (TCP/TLS), 8443 (TCP/WSS), 3478 (UDP/TCP), 20000-30000 (UDP - RTP)

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose plugin
sudo apt-get install -y docker-compose-plugin

# Verify
docker compose version
```

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_REPO/secure-sip-platform.git
cd secure-sip-platform/stack

# 2. Copy and configure environment
cp .env.example .env
nano .env          # Set PUBLIC_IP, DOMAIN, and all passwords

# 3. Generate TLS certificates
cd certs
bash gen-self-signed.sh YOUR_DOMAIN_OR_IP
cd ..
# For production: replace certs/fullchain.pem + certs/privkey.pem
# with Let's Encrypt output (certbot certonly --standalone -d your.domain)

# 4. Bring up the stack
docker compose up -d

# 5. Watch logs
docker compose logs -f kamailio
```

The JsSIP softphone is served at `https://YOUR_IP/` once the stack is up.

---

## Security Checklist

- [ ] All passwords in `.env` changed from defaults - never commit `.env`
- [ ] `PUBLIC_IP` set to the actual server public IP
- [ ] Firewall allows only the required ports (see Prerequisites above)
- [ ] RTP port range (20000-30000 UDP) open in cloud security group
- [ ] TURN secret (`TURN_SECRET`) is a random 32+ character string
- [ ] Self-signed certs replaced with real TLS certs for production
- [ ] fail2ban is running: `docker compose ps fail2ban`
- [ ] Homer is accessible only on localhost:9080 (not public)
- [ ] AMI bound to localhost only (see `manager.conf`)
- [ ] Test accounts (alice/bob) removed or passwords rotated before production

---

## Test Plan - Verifying Security Controls

### 1. Registration over WSS

```bash
# Open https://YOUR_IP in a browser
# Enter WSS endpoint: wss://YOUR_IP:8443/ws
# SIP URI: sip:alice@YOUR_DOMAIN  Password: (from .env ALICE_PASS)
# Click Register - all four status pills should go green
```

Expected: `200 OK` from Kamailio, registration visible in subscriber DB.

```bash
# Verify in Kamailio
docker exec sip-kamailio kamctl ul show
```

### 2. Two-client call (WebRTC DTLS-SRTP)

```bash
# Open the softphone in two browser tabs/windows
# Register alice in one, bob in the other
# Call sip:bob@YOUR_DOMAIN from alice
# Both should hear audio - SRTP active pill should light green
```

Expected: Call established with DTLS-SRTP on WebRTC leg, SRTP on internal leg.

### 3. Anti-flood (pike) firing

```bash
# From an external machine, send a SIP flood:
sipsak -f -F sip:test@YOUR_IP -C sip:flood@1.2.3.4 --flood-mode -n 200
# Or with sipflood: sipflood -d YOUR_IP -p 5060 -n 1000
```

Expected Kamailio log output:
```
ALERT: FLOOD from X.X.X.X - auto-banning
htable: IP X.X.X.X added to ban table
fail2ban: iptables DROP rule inserted for X.X.X.X
```

Verify:
```bash
docker exec sip-kamailio kamctl htable show ipban
docker exec sip-fail2ban fail2ban-client status kamailio
iptables -L INPUT -n | grep X.X.X.X
```

### 4. Auth brute force banning

```bash
# Try to register with wrong password 5+ times:
for i in {1..6}; do
  sipsak -r sip:alice@YOUR_IP -U -a wrongpassword -u alice -d YOUR_IP 2>&1 | grep -E "401|403"
done
```

Expected: After 5 failures, source IP is added to `ipban` htable and banned by fail2ban.

### 5. Toll fraud dialplan block

```bash
# Register as alice, then attempt to call a blocked prefix
# Target: sip:00883123456@YOUR_DOMAIN  (premium international)
```

Expected Asterisk log:
```
WARNING: FRAUD blocked_prefix account=alice dest=00883123456
```
Call is rejected with 403 before hitting the carrier trunk.

### 6. Extension enumeration defense

```bash
# Try both valid and invalid extensions:
sipsak -r sip:alice@YOUR_IP   # Valid user
sipsak -r sip:zzz999@YOUR_IP  # Invalid user
```

Expected: Both return `401 Unauthorized` (uniform response - no 404 for invalid users).

---

## Architecture Decision Notes

**Why Kamailio at the edge, not Asterisk?**
Kamailio is a stateless SIP proxy capable of millions of transactions per second with minimal per-request overhead. Asterisk is a B2BUA optimized for call logic. Exposing Asterisk to the internet means every flood packet consumes a thread. Kamailio absorbs and drops attacks before any call logic runs.

**Why RTPengine separate from Asterisk?**
WebRTC requires DTLS-SRTP; traditional SIP uses SRTP. RTPengine bridges these at the kernel level without decrypting content. Running media through Asterisk would require Asterisk to handle DTLS, which creates tight coupling and limits independent scaling of media and call logic capacity.

**Why coturn in the private zone with public TURN ports?**
TURN credentials are time-limited HMAC tokens generated per session. Coturn denies relay to private IP ranges, preventing TURN from being used to reach internal services. TURN ports (49152-65535) are the only RTP-adjacent ports exposed beyond the Kamailio SBC.

**Swapping self-signed for real certs**
```bash
# With certbot (domain required):
sudo certbot certonly --standalone -d your.domain
cp /etc/letsencrypt/live/your.domain/fullchain.pem stack/certs/
cp /etc/letsencrypt/live/your.domain/privkey.pem stack/certs/
docker compose restart kamailio web coturn
```

---

## Scaling beyond a single node

- **Edge layer**: Add more Kamailio nodes behind anycast or a UDP load balancer. All share Redis for rate counters and htable bans.
- **Media layer**: RTPengine scales independently - add nodes and configure Kamailio to round-robin across them.
- **Call engine**: Add Asterisk instances to the dispatcher set in MySQL. Kamailio health-checks and routes around failures automatically.
- **Shared state**: Redis Cluster or Sentinel for HA. Kamailio reads ban tables from Redis - any node sees bans set by any other node.
