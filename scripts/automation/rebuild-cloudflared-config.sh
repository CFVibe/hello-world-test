#!/bin/bash
# rebuild-cloudflared-config.sh - Auto-generate cloudflared config from app ingress rules
# Run this after adding/removing apps — no sudo needed if cloudflared runs as user

set -e

INGRESS_DIR="/home/cf/.openclaw/ingress-rules.d"
CONFIG_DIR="/home/cf/.openclaw/cloudflared-config"
CONFIG_FILE="$CONFIG_DIR/config.yml"
PID_FILE="$CONFIG_DIR/cloudflared.pid"

mkdir -p "$CONFIG_DIR"

# Build the config
cat > "$CONFIG_FILE" << 'HEADER'
tunnel: 256c70c4-55b1-4880-a91d-d42f3684ddc9
credentials-file: /home/cf/.cloudflared/256c70c4-55b1-4880-a91d-d42f3684ddc9.json

ingress:
HEADER

# Add all app ingress rules (sorted for consistency)
if [ -d "$INGRESS_DIR" ] && [ "$(ls -A $INGRESS_DIR/*.yml 2>/dev/null)" ]; then
    for rule in $(ls -1 "$INGRESS_DIR"/*.yml | sort); do
        echo "  # From: $rule" >> "$CONFIG_FILE"
        cat "$rule" >> "$CONFIG_FILE"
    done
fi

# Add existing test.christianfransson.com route (preserved)
cat >> "$CONFIG_FILE" << 'FOOTER'
  - hostname: test.christianfransson.com
    service: http://localhost:8123
  - service: http_status:404
FOOTER

echo "Config rebuilt: $CONFIG_FILE"

# Validate
echo "Validating..."
if ! cloudflared tunnel ingress validate "$CONFIG_FILE" 2>&1; then
    echo "ERROR: Config validation failed!"
    exit 1
fi

# Reload strategy (in order of preference):
# 1. If running as user service: systemctl --user reload
# 2. If we have passwordless sudo for cloudflared: sudo systemctl reload
# 3. SIGHUP to running process
# 4. Start in background if not running

echo "Reloading cloudflared..."

if systemctl --user is-active --quiet cloudflared 2>/dev/null; then
    echo "Restarting user service..."
    systemctl --user restart cloudflared
elif sudo -n systemctl is-active --quiet cloudflared 2>/dev/null; then
    echo "Reloading system service (passwordless sudo)..."
    sudo systemctl reload cloudflared || sudo systemctl restart cloudflared
elif [ -f "$PID_FILE" ] && kill -0 "$(cat $PID_FILE)" 2>/dev/null; then
    echo "Sending SIGHUP to running process..."
    kill -HUP "$(cat $PID_FILE)"
else
    echo "Starting cloudflared in background..."
    nohup cloudflared tunnel --config "$CONFIG_FILE" run > "$CONFIG_DIR/cloudflared.log" 2>&1 &
    echo $! > "$PID_FILE"
    echo "Started with PID $(cat $PID_FILE)"
fi

echo "Done. Active ingress rules:"
grep -c "^  - hostname:" "$CONFIG_FILE"
