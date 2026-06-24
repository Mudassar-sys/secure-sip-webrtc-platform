# Secure SIP & WebRTC Platform

A layered, production-grade SIP architecture proof of concept demonstrating defense-in-depth for VoIP infrastructure.

## Repository Structure

```
/web      - Self-contained HTML presentation (architecture, rationale, WebRTC PoC, engagement)
/stack    - Containerized Docker stack (one-command bring-up on Ubuntu 22.04)
```

## Part A - Web Presentation (`/web`)

Open `web/index.html` directly in any browser - no build step, no server required.

**Four interactive tabs:**
- Architecture Flow - clickable 5-layer diagram with component detail panels
- Design Rationale - comparison table and threat control matrix
- WebRTC PoC - softphone simulator with live attack simulation logs
- Engagement - three-phase project structure

## Part B - Runnable Stack (`/stack`)

One-command containerized proof of concept. See [stack/README.md](stack/README.md) for full setup instructions.

**Services:**

| Container | Role |
|-----------|------|
| kamailio | Internet-facing SBC - anti-flood, auth, topology hiding, WSS/TLS |
| rtpengine | Media relay - DTLS-SRTP to SRTP bridge |
| asterisk | Call engine - PJSIP, dialplan, fraud guards |
| coturn | STUN/TURN for WebRTC NAT traversal |
| fail2ban | Reads Kamailio logs, bans at iptables level |
| mysql | Subscriber database |
| redis | Shared rate counters and ban tables |
| web | Nginx serving JsSIP WebRTC softphone |
| homer-webapp | SIP call capture and search |

**Quick start:**

```bash
cd stack
cp .env.example .env
# Edit .env - set PUBLIC_IP, DOMAIN, passwords
cd certs && bash gen-self-signed.sh YOUR_IP && cd ..
docker compose up -d
```

## Security Architecture

```
Internet
    |
[Kamailio SBC] -- Pike anti-flood, htable IP ban, fail2ban, topology hiding
    |
[RTPengine]    -- DTLS-SRTP <-> SRTP bridge, media anchoring
    |
[Asterisk]     -- B2BUA, dialplan fraud guards, per-tenant call limits
    |
[coturn]       -- STUN/TURN, time-limited HMAC credentials, RFC1918 deny
```
