#!/bin/bash
# register-app-ingress.sh - Register a new app with cloudflared
# Usage: register-app-ingress.sh <app-name> <prod-port> [test-port]

set -e

APP_NAME="${1:-}"
PROD_PORT="${2:-}"
TEST_PORT="${3:-}"

if [ -z "$APP_NAME" ] || [ -z "$PROD_PORT" ]; then
    echo "Usage: register-app-ingress.sh <app-name> <prod-port> [test-port]"
    echo "Example: register-app-ingress.sh hello-world 8080 8081"
    exit 1
fi

INGRESS_DIR="/home/cf/.openclaw/ingress-rules.d"
mkdir -p "$INGRESS_DIR"

# Create production route
cat > "$INGRESS_DIR/$APP_NAME-prod.yml" << EOF
  - hostname: $APP_NAME.christianfransson.com
    service: http://localhost:$PROD_PORT
EOF

# Create test route if test port provided
if [ -n "$TEST_PORT" ]; then
    cat > "$INGRESS_DIR/$APP_NAME-test.yml" << EOF
  - hostname: $APP_NAME-test.christianfransson.com
    service: http://localhost:$TEST_PORT
EOF
fi

echo "Registered: $APP_NAME"
echo "  Production: https://$APP_NAME.christianfransson.com → localhost:$PROD_PORT"
[ -n "$TEST_PORT" ] && echo "  Test:       https://$APP_NAME-test.christianfransson.com → localhost:$TEST_PORT"

# Rebuild and reload
echo ""
exec /home/cf/.openclaw/scripts/rebuild-cloudflared-config.sh
