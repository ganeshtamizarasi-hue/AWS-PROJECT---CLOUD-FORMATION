#!/bin/bash
# =============================================================================
# S3 Backup Script
# Project  : ganeshc.shop — WordPress HA on AWS
# Schedule : Add to crontab — runs hourly for uploads, daily for full code
# Usage    : sudo bash /usr/local/bin/s3-backup.sh
# =============================================================================

set -e

# ── CONFIGURATION ─────────────────────────────
REGION="ap-south-1"
S3_MEDIA_BUCKET="ganeshc-wp-media-backup"
S3_CODE_BUCKET="ganeshc-wp-code-backup"
WEB_ROOT="/var/www/html"
UPLOADS_DIR="${WEB_ROOT}/wp-content/uploads"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
LOG_FILE="/var/log/s3-backup.log"

echo "========================================" >> "$LOG_FILE"
echo "[${TIMESTAMP}] Starting S3 backup..."    >> "$LOG_FILE"

# ── 1. SYNC MEDIA UPLOADS ─────────────────────
echo "[${TIMESTAMP}] Syncing wp-content/uploads to s3://${S3_MEDIA_BUCKET}..." >> "$LOG_FILE"

aws s3 sync "$UPLOADS_DIR" "s3://${S3_MEDIA_BUCKET}/uploads/" \
  --region "$REGION" \
  --delete \
  --sse AES256 \
  >> "$LOG_FILE" 2>&1

echo "[${TIMESTAMP}] Media sync complete." >> "$LOG_FILE"

# ── 2. BACKUP FULL WP CODE (daily archive) ────
echo "[${TIMESTAMP}] Creating WordPress code archive..." >> "$LOG_FILE"

ARCHIVE="/tmp/wordpress-code-${TIMESTAMP}.tar.gz"
tar --exclude="${WEB_ROOT}/wp-content/uploads" \
    --exclude="${WEB_ROOT}/wp-content/cache" \
    -czf "$ARCHIVE" \
    -C /var/www html

aws s3 cp "$ARCHIVE" "s3://${S3_CODE_BUCKET}/backups/wordpress-code-${TIMESTAMP}.tar.gz" \
  --region "$REGION" \
  --sse AES256 \
  >> "$LOG_FILE" 2>&1

rm -f "$ARCHIVE"
echo "[${TIMESTAMP}] Code backup complete." >> "$LOG_FILE"

# ── 3. REMOVE BACKUPS OLDER THAN 30 DAYS ─────
echo "[${TIMESTAMP}] Pruning backups older than 30 days from S3..." >> "$LOG_FILE"

aws s3 ls "s3://${S3_CODE_BUCKET}/backups/" \
  --region "$REGION" \
  | awk '{print $4}' \
  | while read -r key; do
      file_date=$(echo "$key" | grep -oP '\d{4}-\d{2}-\d{2}')
      if [[ -n "$file_date" ]]; then
        cutoff=$(date -d "30 days ago" +%Y-%m-%d)
        if [[ "$file_date" < "$cutoff" ]]; then
          aws s3 rm "s3://${S3_CODE_BUCKET}/backups/${key}" --region "$REGION" >> "$LOG_FILE" 2>&1
          echo "[${TIMESTAMP}] Deleted old backup: ${key}" >> "$LOG_FILE"
        fi
      fi
    done

echo "[${TIMESTAMP}] Backup finished successfully." >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
