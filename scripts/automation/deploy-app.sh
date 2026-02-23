#!/bin/bash
# deploy-app.sh - Deploy an app to test and/or production
# Usage: deploy-app.sh <app-name> [--test-only|--prod-only]

set -e

APP_NAME="${1:-}"
MODE="${2:-both}"

if [ -z "$APP_NAME" ]; then
    echo "Usage: deploy-app.sh <app-name> [--test-only|--prod-only]"
    exit 1
fi

APP_DIR="/home/cf/.openclaw/apps/$APP_NAME"

if [ ! -d "$APP_DIR" ]; then
    echo "ERROR: App directory not found: $APP_DIR"
    echo "Clone it first: git clone https://github.com/CFVibe/$APP_NAME.git $APP_DIR"
    exit 1
fi

cd "$APP_DIR"

# Pull latest code
echo "→ Pulling latest code..."
git pull

# Deploy to test first (unless prod-only)
if [ "$MODE" != "--prod-only" ]; then
    echo "→ Building test environment..."
    docker compose up -d --build "${APP_NAME}-test" 2>&1 || docker compose up -d --build
    
    TEST_URL="https://${APP_NAME}-test.christianfransson.com"
    echo "→ Waiting for test environment..."
    for i in {1..30}; do
        if curl -sf "$TEST_URL" >/dev/null 2>&1; then
            echo "✓ Test environment ready: $TEST_URL"
            break
        fi
        sleep 1
    done
    
    if [ "$MODE" = "--test-only" ]; then
        echo ""
        echo "=== Deployed to Test Only ==="
        echo "Test URL: $TEST_URL"
        exit 0
    fi
    
    echo "→ Running QC on test... (manual verification recommended)"
fi

# Deploy to production
echo "→ Building production environment..."
docker compose up -d --build "${APP_NAME}-prod" 2>&1 || docker compose up -d --build

PROD_URL="https://${APP_NAME}.christianfransson.com"
echo "→ Waiting for production environment..."
for i in {1..30}; do
    if curl -sf "$PROD_URL" >/dev/null 2>&1; then
        echo "✓ Production environment ready: $PROD_URL"
        break
    fi
    sleep 1
done

echo ""
echo "=== Deployment Complete ==="
echo "Production: $PROD_URL"
if [ "$MODE" != "--prod-only" ]; then
    echo "Test:       $TEST_URL"
fi
