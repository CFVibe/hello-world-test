#!/bin/bash
# Daily backup sync: CFVibe → jarvisbot1000-sudo (backup account)
# Run via cron or heartbeat

set -e

PRIMARY_USER="CFVibe"
BACKUP_USER="jarvisbot1000-sudo"
BACKUP_DIR="$HOME/.openclaw/backups/github-repos"
LOG_FILE="$HOME/.openclaw/logs/github-backup.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
NOTIFY_FILE="/tmp/github-backup-failed"

# Get jarvisbot1000-sudo PAT from gh cli
BACKUP_TOKEN=$(gh auth token --user jarvisbot1000-sudo 2>/dev/null || echo "")

if [ -z "$BACKUP_TOKEN" ]; then
  echo "[$DATE] ERROR: Cannot get jarvisbot1000-sudo token" >> "$LOG_FILE"
  echo "[$DATE] ERROR: Cannot get jarvisbot1000-sudo token" > "$NOTIFY_FILE"
  exit 1
fi

echo "[$DATE] Starting GitHub backup sync..." >> "$LOG_FILE"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Get list of repos from CFVibe account
repos=$(gh repo list "$PRIMARY_USER" --limit 100 --json name -q '.[].name' 2>/dev/null || echo "")

if [ -z "$repos" ]; then
  echo "[$DATE] No repos found from CFVibe account" >> "$LOG_FILE"
  exit 0
fi

FAILED_REPOS=""
SUCCESS_COUNT=0
TOTAL_COUNT=0

for repo in $repos; do
  TOTAL_COUNT=$((TOTAL_COUNT + 1))
  REPO_DIR="$BACKUP_DIR/$repo"
  
  if [ -d "$REPO_DIR/.git" ]; then
    # Repo exists, pull latest
    echo "[$DATE] Updating $repo..." >> "$LOG_FILE"
    cd "$REPO_DIR"
    if ! git fetch origin 2>/dev/null; then
      echo "[$DATE] WARNING: Failed to fetch $repo" >> "$LOG_FILE"
      FAILED_REPOS="$FAILED_REPOS $repo(fetch)"
      continue
    fi
    git reset --hard origin/main 2>/dev/null || git reset --hard origin/master 2>/dev/null || true
  else
    # Clone fresh using HTTPS
    echo "[$DATE] Cloning $repo..." >> "$LOG_FILE"
    cd "$BACKUP_DIR"
    if ! git clone "https://github.com/$PRIMARY_USER/$repo.git" "$repo" 2>/dev/null; then
      echo "[$DATE] WARNING: Failed to clone $repo" >> "$LOG_FILE"
      FAILED_REPOS="$FAILED_REPOS $repo(clone)"
      continue
    fi
  fi
  
  # Push to backup account (jarvisbot1000-sudo) if cloned successfully
  if [ -d "$REPO_DIR/.git" ]; then
    cd "$REPO_DIR"
    
    # Create backup remote with embedded token
    git remote remove backup 2>/dev/null || true
    git remote add backup "https://$BACKUP_TOKEN@github.com/$BACKUP_USER/$repo.git" 2>/dev/null || true
    
    # Push to backup
    if ! git push backup --all --force 2>/dev/null; then
      echo "[$DATE] WARNING: Failed to push $repo to backup ($BACKUP_USER)" >> "$LOG_FILE"
      FAILED_REPOS="$FAILED_REPOS $repo(push)"
      continue
    fi
    echo "[$DATE] Backed up $repo to $BACKUP_USER" >> "$LOG_FILE"
  fi
  
  SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
done

# Summary
echo "[$DATE] Backup sync complete: $SUCCESS_COUNT/$TOTAL_COUNT repos successful" >> "$LOG_FILE"

# Notify if failures
if [ -n "$FAILED_REPOS" ]; then
  ERROR_MSG="[$DATE] BACKUP FAILED for repos:$FAILED_REPOS. Check $LOG_FILE"
  echo "$ERROR_MSG" >> "$LOG_FILE"
  echo "$ERROR_MSG" > "$NOTIFY_FILE"
  echo "[$DATE] Notification written to $NOTIFY_FILE" >> "$LOG_FILE"
  exit 1
else
  # Clear any previous failure notification
  rm -f "$NOTIFY_FILE"
fi

exit 0
