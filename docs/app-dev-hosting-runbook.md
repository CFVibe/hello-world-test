# App dev + hosting runbook (Christian ↔ Jarvis)

This runbook is distilled from our Slack chat around setting up:
- Cloudflare Tunnel on the ThinkCentre
- DNS + (optional) Cloudflare Access for private apps
- A repeatable “create app / delete app” lifecycle

If anything below conflicts with what Christian says in the moment, Christian overrides.

## Defaults (unless Christian says otherwise)

- Repo-per-app.
- Naming: force lowercase (slugify); explicitly report normalization.
- URL pattern (current): `https://<app>.christianfransson.com`
- Default exposure: **private** (Cloudflare Access gate). Public only when Christian says “public”.
- Delete policy: when an app is deleted, delete the GitHub repo **+24h later** (grace window).

## What’s considered “ready”

Checklist we reached in chat:
- Domain + Cloudflare DNS: done
- Cloudflare Tunnel (`cloudflared`): running as a **systemd service** on the ThinkCentre
- Cloudflare API token with needed permissions: available (but should be stored on-host, not in chat)
- GitHub CLI auth with repo scopes on the ThinkCentre: enabled

## Cloudflare pieces (mental model)

- Domain = stable URLs
- Cloudflare = DNS + edge routing
- Cloudflare Tunnel = securely exposes local services without opening inbound ports
- Cloudflare Access = login gate for private apps (SSO-style)

### Access allowlist
- Private apps should be accessible only after login.
- Allowed identity (as discussed): `dedooma@gmail.com`.

## Cloudflare automation token (do this safely)

Do NOT paste tokens into Slack.

Best practice: store token on the ThinkCentre:
- `/etc/cloudflared/env` (chmod 600)
- systemd override loads it:
  - `EnvironmentFile=/etc/cloudflared/env`

Token permissions we discussed:
- Account → Cloudflare Tunnel → Edit
- Zone → Zone → Read
- Zone → DNS → Edit
- Zone → Access: Apps and Policies → Edit (optional but recommended)

## Hosting model (current)

- Apps run on the ThinkCentre (local ports) typically via Docker Compose.
- cloudflared ingress maps hostname → local service.
- DNS for tunnel hostnames is created automatically by tunnel routing when possible; otherwise created via Cloudflare DNS API.

## Workflow

### When Christian asks for a new app
Christian sends:
- App name (one word, lowercase preferred) OR Jarvis slugifies
- What it should do (1–3 bullets)
- Public or private (default private)
- Data needs: none / simple notes / file upload / etc.

Jarvis does:
1) Confirm scope + defaults.
2) Create GitHub repo (lowercase slug) and scaffold.
3) Implement in small increments; keep `main` deployable.
4) Deploy on ThinkCentre (compose/service), wire hostname via cloudflared.
5) Apply Access policy if private; skip if public.
6) Return URL + update/rollback + logs + delete instructions.

### When Christian asks to delete an app
Jarvis does:
1) Stop/remove the service.
2) Remove tunnel ingress/hostname mapping.
3) Delete DNS record.
4) Confirm it’s gone.
5) Schedule GitHub repo deletion in **24h**.

## Canonical doc

The canonical, always-up-to-date workflow file is:
- `docs/APP_WORKFLOW.md`
