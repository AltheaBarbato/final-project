#!/bin/bash
set -e

BACKUP_DIR="/var/backups/final-project"
DATE=$(date +%Y%m%d-%H%M%S)
DEST="$BACKUP_DIR/$DATE"

mkdir -p "$DEST"

tar -czf "$DEST/nginx.tar.gz" /etc/nginx /var/www/html 2>/dev/null || true
tar -czf "$DEST/ssl.tar.gz" /etc/letsencrypt 2>/dev/null || true
tar -czf "$DEST/prometheus.tar.gz" /etc/prometheus 2>/dev/null || true
tar -czf "$DEST/grafana.tar.gz" /etc/grafana 2>/dev/null || true
tar -czf "$DEST/system-security.tar.gz" \
  /etc/ssh/sshd_config \
  /etc/fail2ban/jail.local \
  /etc/audit/rules.d \
  /etc/apt/apt.conf.d/20auto-upgrades \
  2>/dev/null || true

ln -sfn "$DEST" "$BACKUP_DIR/latest"

find "$BACKUP_DIR" -maxdepth 1 -mindepth 1 -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true

echo "backup completed: $DEST"
