# App Hosting System - Automated Workflow

## Summary
Zero-interaction app deployment system. You say "create app X", everything happens automatically.

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Your Request   │────▶│  create-app.sh   │────▶│  GitHub Repo    │
│  "create app"   │     │  (this script)   │     │  (CFVibe/*)     │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │
                               ▼
                        ┌──────────────────┐
                        │  Cloudflare DNS  │◀─── Automatic CNAME
                        │  Records         │
                        └──────────────────┘
                               │
                               ▼
                        ┌──────────────────┐
                        │  Ingress Rules   │◀─── Auto-registered
                        │  (rules.d/*.yml) │
                        └──────────────────┘
                               │
                               ▼
                        ┌──────────────────┐     ┌─────────────────┐
                        │  rebuild-config  │────▶│  Cloudflared    │◀── User service
                        │  (reload)        │     │  (tunnel)       │    (no sudo)
                        └──────────────────┘     └─────────────────┘
```

## Scripts Location
All automation scripts: `/home/cf/.openclaw/scripts/`

| Script | Purpose | Usage |
|--------|---------|-------|
| `create-app.sh` | Full app provisioning | `create-app.sh myapp 8080 8081` |
| `deploy-app.sh` | Deploy to test/prod | `deploy-app.sh myapp` |
| `register-app-ingress.sh` | Add routing rules | Auto-called by create-app |
| `rebuild-cloudflared-config.sh` | Reload tunnel config | Auto-called on changes |

## How It Works (No Sudo Needed)

### 1. Cloudflared as User Service
- Running under your user: `systemctl --user status cloudflared`
- Config location: `/home/cf/.openclaw/cloudflared-config/config.yml`
- Ingress rules directory: `/home/cf/.openclaw/ingress-rules.d/`
- You can modify config without sudo

### 2. Ingress Registration Flow
When a new app is created:
1. `create-app.sh` creates DNS records via `cloudflared tunnel route dns`
2. `register-app-ingress.sh` writes rule files to `ingress-rules.d/`
3. `rebuild-cloudflared-config.sh` concatenates all rules into config.yml
4. `systemctl --user reload cloudflared` applies changes

### 3. Adding a New App (Fully Automated)
```bash
# One command does everything:
create-app.sh myapp 8090 8091

# What happens:
# ✓ DNS record: myapp.christianfransson.com
# ✓ DNS record: myapp-test.christianfransson.com
# ✓ Ingress rules written
# ✓ Cloudflared config rebuilt and reloaded
# ✓ GitHub repo created (private)
```

### 4. Deploying Code
```bash
# Deploy to test first, then prod:
deploy-app.sh myapp

# Deploy only to test:
deploy-app.sh myapp --test-only

# Deploy only to prod (skip test):
deploy-app.sh myapp --prod-only
```

## Manual Operations (If Needed)

### Restart cloudflared
```bash
systemctl --user restart cloudflared
```

### View logs
```bash
systemctl --user status cloudflared --no-pager
journalctl --user -u cloudflared -f
```

### Rebuild config manually
```bash
/home/cf/.openclaw/scripts/rebuild-cloudflared-config.sh
```

## Migration from System Service

The system service has been disabled. If you need to revert:
```bash
# Re-enable system service
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
systemctl --user stop cloudflared
systemctl --user disable cloudflared
```

## Security

### Private Apps (Default)
Apps are private by default. Access control via Cloudflare Access:
- Allowlist: `dedooma@gmail.com` (your Google account)
- Login required via Google OAuth

### Public Apps
Add `--public` flag to `create-app.sh` (Access policy skipped).

### API Tokens
Cloudflare API token must be available as `CF_API_TOKEN` for Access policy automation. Currently optional — Access policies can be configured manually in Cloudflare dashboard.

## Troubleshooting

### URLs returning 404
1. Check cloudflared is running: `systemctl --user status cloudflared`
2. Verify ingress rules: `cat /home/cf/.openclaw/cloudflared-config/config.yml`
3. Rebuild config: `/home/cf/.openclaw/scripts/rebuild-cloudflared-config.sh`

### Port conflicts
Change ports in docker-compose.yml, then update ingress:
```bash
# Edit docker-compose.yml with new ports, then:
/home/cf/.openclaw/scripts/register-app-ingress.sh myapp NEW_PORT
```

### DNS not resolving
DNS propagation takes ~30 seconds. Check:
```bash
cloudflared tunnel route dns ls 256c70c4-55b1-4880-a91d-d42f3684ddc9
```

## History
- 2026-02-23: Migrated from system service to user service (zero sudo requirement)
