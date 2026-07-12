#!/bin/bash
set -e

BACKUP_DIR="/var/backups/final-project"
RESTORE_FROM="${1:-$BACKUP_DIR/latest}"

echo "restoring from $RESTORE_FROM"

systemctl stop nginx 2>/dev/null || true
systemctl stop docker 2>/dev/null || true

if [[ -f "$RESTORE_FROM/nginx.tar.gz" ]]; then
  tar -xzf "$RESTORE_FROM/nginx.tar.gz" -C / 2>/dev/null || true
fi
if [[ -f "$RESTORE_FROM/ssl.tar.gz" ]]; then
  tar -xzf "$RESTORE_FROM/ssl.tar.gz" -C / 2>/dev/null || true
fi
if [[ -f "$RESTORE_FROM/system-security.tar.gz" ]]; then
  tar -xzf "$RESTORE_FROM/system-security.tar.gz" -C / 2>/dev/null || true
fi

systemctl start nginx 2>/dev/null || true
systemctl start docker 2>/dev/null || true

echo "restore complete"
