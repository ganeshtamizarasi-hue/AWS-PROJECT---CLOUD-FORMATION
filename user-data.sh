#!/bin/bash
# =============================================================================
# WordPress EC2 Bootstrap Script
# Project  : ganeshc.shop — WordPress HA on AWS
# Purpose  : Install Apache, PHP, WordPress; mount EFS; fetch DB credentials
#            from Secrets Manager; configure wp-config.php
# Region   : ap-south-1
# =============================================================================

set -e

# Log everything for easy debugging
exec > /var/log/user-data.log 2>&1

echo "=========================================="
echo "  WordPress Setup Starting..."
echo "  $(date)"
echo "=========================================="

# ── CONFIGURATION ─────────────────────────────
EFS_ID="<YOUR-EFS-ID>"          # Replace: e.g. fs-0abc12345678
SECRET_NAME="wordpress-db-secret"
REGION="ap-south-1"
MOUNT_POINT="/var/www/html/wp-content"
WEB_ROOT="/var/www/html"

# ── 1. SYSTEM UPDATE ──────────────────────────
echo "[1/8] Updating system packages..."
dnf update -y

# ── 2. INSTALL PACKAGES ───────────────────────
echo "[2/8] Installing Apache, PHP, EFS utils, AWS CLI, and jq..."
dnf install -y \
  httpd \
  php \
  php-mysqlnd \
  php-fpm \
  amazon-efs-utils \
  aws-cli \
  jq

# ── 3. START & ENABLE SERVICES ────────────────
echo "[3/8] Enabling and starting services..."
systemctl enable httpd php-fpm
systemctl start  httpd php-fpm

# ── 4. MOUNT EFS ──────────────────────────────
echo "[4/8] Mounting EFS (${EFS_ID}) at ${MOUNT_POINT}..."
mkdir -p "$MOUNT_POINT"

# Mount with TLS for encryption in transit
mount -t efs -o tls "${EFS_ID}":/ "$MOUNT_POINT"

# Persist across reboots
if ! grep -q "$EFS_ID" /etc/fstab; then
  echo "${EFS_ID}:/ ${MOUNT_POINT} efs defaults,tls,_netdev 0 0" >> /etc/fstab
fi

echo "EFS mounted successfully."

# ── 5. INSTALL WORDPRESS ──────────────────────
echo "[5/8] Downloading and installing WordPress..."
cd /tmp
wget -q https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* "$WEB_ROOT"/

# Set correct ownership and permissions
chown -R apache:apache "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

echo "WordPress files deployed."

# ── 6. FETCH CREDENTIALS FROM SECRETS MANAGER ─
echo "[6/8] Fetching DB credentials from Secrets Manager (${SECRET_NAME})..."
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id  "$SECRET_NAME" \
  --region     "$REGION" \
  --query      SecretString \
  --output     text)

DB_NAME=$(echo "$SECRET" | jq -r .dbname)
DB_USER=$(echo "$SECRET" | jq -r .username)
DB_PASS=$(echo "$SECRET" | jq -r .password)
DB_HOST=$(echo "$SECRET" | jq -r .host)

echo "Credentials fetched. DB host: ${DB_HOST}"

# ── 7. CONFIGURE WORDPRESS ────────────────────
echo "[7/8] Writing wp-config.php..."
cp "$WEB_ROOT"/wp-config-sample.php "$WEB_ROOT"/wp-config.php

sed -i "s/database_name_here/${DB_NAME}/" "$WEB_ROOT"/wp-config.php
sed -i "s/username_here/${DB_USER}/"      "$WEB_ROOT"/wp-config.php
sed -i "s/password_here/${DB_PASS}/"      "$WEB_ROOT"/wp-config.php
sed -i "s/localhost/${DB_HOST}/"          "$WEB_ROOT"/wp-config.php

# Secure the config file — owner read/write only
chown apache:apache "$WEB_ROOT"/wp-config.php
chmod 640 "$WEB_ROOT"/wp-config.php

# Health check endpoint for ALB Target Group
echo "healthy" > "$WEB_ROOT"/healthy.html

echo "WordPress configured."

# ── 8. FINAL RESTART ──────────────────────────
echo "[8/8] Restarting Apache..."
systemctl restart httpd

echo "=========================================="
echo "  WordPress setup completed successfully!"
echo "  $(date)"
echo "=========================================="
