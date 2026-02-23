#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/home/cf/.openclaw/workspace"
TOKEN_FILE="/home/cf/.openclaw-github-token"
REPO_URL="https://chrfra:$(cat $TOKEN_FILE)@github.com/chrfra/Openclaw-backup.git"
BACKUP_DIR="/tmp/openclaw-backup-$$"
REPO_DIR="/home/cf/.openclaw-backup-repo"
ZIP_DIR="/home/cf/.openclaw/backups"
DATE=$(date +%Y-%m-%d)
LOG_FILE="/home/cf/.openclaw/backups/backup.log"

mkdir -p "$ZIP_DIR"
exec >> "$LOG_FILE" 2>&1
echo ""
echo "=== Backup started: $(date) ==="

# --- 1. Prepare backup staging area ---
mkdir -p "$BACKUP_DIR/workspace"

# Copy workspace files, excluding sensitive patterns and large files
rsync -a --quiet \
  --exclude='*.token' \
  --exclude='*.key' \
  --exclude='*.pem' \
  --exclude='*.secret' \
  --exclude='*.password' \
  --exclude='*.credentials' \
  --exclude='.env' \
  --exclude='.env.*' \
  --exclude='media/' \
  --exclude='watch-history.html' \
  --exclude='node_modules/' \
  --exclude='.git/' \
  --exclude='*.sqlite' \
  --exclude='*.db' \
  "$WORKSPACE/" "$BACKUP_DIR/workspace/"

# Copy redacted config
REDACTED_CONFIG="$BACKUP_DIR/openclaw.json"
python3 -c "
import json, re
with open('/home/cf/.openclaw/openclaw.json') as f:
    raw = f.read()
raw = re.sub(r'\"(botToken|apiKey|token|password|secret)\"\s*:\s*\"[^\"]+\"',
             lambda m: m.group(0).split(':')[0] + ': \"REDACTED\"', raw)
with open('$REDACTED_CONFIG', 'w') as f:
    f.write(raw)
"
echo "Workspace staged and config redacted."

# --- 2. Create zip archive ---
ZIP_PATH="$ZIP_DIR/openclaw-backup-$DATE.zip"
cd /tmp && zip -r -q "$ZIP_PATH" "$(basename $BACKUP_DIR)/"
echo "Zip created: $ZIP_PATH"

# Keep only last 30 backups
ls -t "$ZIP_DIR"/openclaw-backup-*.zip 2>/dev/null | tail -n +31 | xargs -r rm -f

# --- 3. Push to git ---
if [ ! -d "$REPO_DIR/.git" ]; then
  git clone "$REPO_URL" "$REPO_DIR" --quiet
  echo "Repo cloned."
else
  cd "$REPO_DIR"
  git remote set-url origin "$REPO_URL"
  git pull --quiet origin main 2>/dev/null || git pull --quiet origin master 2>/dev/null || true
fi

rsync -a --quiet --delete \
  --exclude='.git/' \
  "$BACKUP_DIR/" "$REPO_DIR/"

cd "$REPO_DIR"
git add -A

if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "Backup $DATE" --quiet
  # Mask token in any output
  git push origin HEAD --quiet 2>&1 | sed "s|$(cat $TOKEN_FILE)|TOKEN|g"
  echo "Pushed to GitHub."
fi

# --- 4. Export cron jobs ---
openclaw cron list --json 2>/dev/null > "$BACKUP_DIR/workspace/cron-jobs.json" || true
echo "Cron jobs exported."

# --- 5. Cleanup (renumbered) ---
rm -rf "$BACKUP_DIR"

# --- 6. Check for OpenClaw updates ---
echo "Checking for OpenClaw updates..."
CURRENT=$(openclaw --version 2>/dev/null | grep -oP '\d{4}\.\d+\.\d+' | head -1 || echo "unknown")
LATEST=$(npm view openclaw version 2>/dev/null || echo "unknown")

if [ "$CURRENT" != "unknown" ] && [ "$LATEST" != "unknown" ] && [ "$CURRENT" != "$LATEST" ]; then
  echo "Update available: $CURRENT -> $LATEST. Updating..."
  npm install -g openclaw@latest --quiet
  openclaw gateway restart 2>/dev/null || true
  echo "OpenClaw updated to $LATEST."
else
  echo "OpenClaw up to date: $CURRENT"
fi

echo "=== Backup completed: $(date) ==="
