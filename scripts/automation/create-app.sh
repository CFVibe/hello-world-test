#!/bin/bash
# create-app.sh - Full app creation workflow
# Usage: create-app.sh <app-name> <prod-port> [test-port] [--public]

set -e

APP_NAME="${1:-}"
PROD_PORT="${2:-}"
TEST_PORT="${3:-}"
PUBLIC="${4:-private}"

if [ -z "$APP_NAME" ] || [ -z "$PROD_PORT" ]; then
    echo "Usage: create-app.sh <app-name> <prod-port> [test-port] [--public]"
    echo "Example: create-app.sh myapp 8080 8081"
    exit 1
fi

APP_DIR="/home/cf/.openclaw/apps/$APP_NAME"
REPO_NAME="CFVibe/$APP_NAME"

echo "=== Creating App: $APP_NAME ==="
echo "Ports: prod=$PROD_PORT, test=${TEST_PORT:-none}"
echo "Privacy: ${PUBLIC}"
echo ""

# 1. Create DNS records via cloudflared
echo "→ Creating Cloudflare DNS records..."
cloudflared tunnel route dns 256c70c4-55b1-4880-a91d-d42f3684ddc9 "$APP_NAME.christianfransson.com" 2>&1 || true
if [ -n "$TEST_PORT" ]; then
    cloudflared tunnel route dns 256c70c4-55b1-4880-a91d-d42f3684ddc9 "$APP_NAME-test.christianfransson.com" 2>&1 || true
fi

# 2. Register ingress
echo "→ Registering ingress routes..."
if [ -n "$TEST_PORT" ]; then
    /home/cf/.openclaw/scripts/register-app-ingress.sh "$APP_NAME" "$PROD_PORT" "$TEST_PORT" >/dev/null
else
    /home/cf/.openclaw/scripts/register-app-ingress.sh "$APP_NAME" "$PROD_PORT" >/dev/null
fi

# 3. Create GitHub repo
echo "→ Creating GitHub repo: $REPO_NAME..."
gh repo create "$REPO_NAME" --private 2>&1 || echo "  (repo may already exist)"

echo ""
echo "=== App Infrastructure Ready ==="
echo "DNS:     https://$APP_NAME.christianfransson.com"
[ -n "$TEST_PORT" ] && echo "Test:    https://$APP_NAME-test.christianfransson.com"
echo "Local:   http://localhost:$PROD_PORT"
echo "Repo:    https://github.com/$REPO_NAME"
echo ""
echo "Next steps:"
echo "1. Clone: git clone https://github.com/$REPO_NAME.git $APP_DIR"
echo "2. Build your app in $APP_DIR"
echo "3. Add docker-compose.yml with services on ports $PROD_PORT${TEST_PORT:+ and $TEST_PORT}"
echo "4. Deploy: cd $APP_DIR && docker compose up -d"
echo "5. Push code: git add . && git commit -m 'Initial' && git push"
