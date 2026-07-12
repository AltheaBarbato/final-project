#!/bin/bash
DOMAIN="althea-lab.duckdns.org"
SERVER_IP="163.192.117.50"
SSH_KEY="$HOME/.ssh/lab1-key.pem"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no -o ConnectTimeout=10"
PASS=0
FAIL=0

check() {
    local label="$1"
    local result="$2"
    if [[ "$result" == "ok" ]]; then
        echo "  [PASS] $label"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $label ($result)"
        FAIL=$((FAIL + 1))
    fi
}

echo "--- DNS ---"
resolved=$(dig +short "$DOMAIN" | head -1)
check "DNS resolves to correct IP" "$( [[ "$resolved" == "$SERVER_IP" ]] && echo ok || echo "got $resolved" )"

echo "--- TLS ---"
tls=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN")
check "HTTPS reachable via domain" "$( [[ "$tls" == "200" ]] && echo ok || echo "got $tls" )"

redirect=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN")
check "HTTP redirects to HTTPS" "$( [[ "$redirect" == "301" ]] && echo ok || echo "got $redirect" )"

cert_issuer=$(curl -sv "https://$DOMAIN" 2>&1 | grep "issuer" | head -1)
check "Let's Encrypt cert" "$( echo "$cert_issuer" | grep -qi "let" && echo ok || echo "not lets encrypt: $cert_issuer" )"

hsts=$(curl -sI "https://$DOMAIN" | grep -i "strict-transport")
check "HSTS header present" "$( [[ -n "$hsts" ]] && echo ok || echo missing )"

echo "--- SSH Hardening ---"
root=$(ssh $SSH_OPTS "sysadmin@$SERVER_IP" "grep '^PermitRootLogin' /etc/ssh/sshd_config | awk '{print \$2}'")
check "PermitRootLogin no" "$( [[ "$root" == "no" ]] && echo ok || echo "got $root" )"

pwauth=$(ssh $SSH_OPTS "sysadmin@$SERVER_IP" "grep '^PasswordAuthentication' /etc/ssh/sshd_config | awk '{print \$2}'")
check "PasswordAuthentication no" "$( [[ "$pwauth" == "no" ]] && echo ok || echo "got $pwauth" )"

echo "--- Security Services ---"
f2b=$(ssh $SSH_OPTS "sysadmin@$SERVER_IP" "sudo systemctl is-active fail2ban")
check "fail2ban running" "$( [[ "$f2b" == "active" ]] && echo ok || echo "$f2b" )"

auditd=$(ssh $SSH_OPTS "sysadmin@$SERVER_IP" "sudo systemctl is-active auditd")
check "auditd running" "$( [[ "$auditd" == "active" ]] && echo ok || echo "$auditd" )"

echo "--- Firewall ---"
ufw=$(ssh $SSH_OPTS "sysadmin@$SERVER_IP" "sudo ufw status | head -1 | awk '{print \$2}'")
check "UFW active" "$( [[ "$ufw" == "active" ]] && echo ok || echo "not active" )"

echo "--- Monitoring (from Lab 3) ---"
prom=$(curl -s -o /dev/null -w "%{http_code}" "http://$SERVER_IP:9090/-/ready")
check "Prometheus up" "$( [[ "$prom" == "200" ]] && echo ok || echo "got $prom" )"

grafana=$(curl -s -o /dev/null -w "%{http_code}" "http://$SERVER_IP:3000")
check "Grafana up" "$( [[ "$grafana" == "200" || "$grafana" == "302" ]] && echo ok || echo "got $grafana" )"

echo "--- Backup ---"
backup=$(ssh $SSH_OPTS "sysadmin@$SERVER_IP" "sudo test -d /var/backups/final-project/latest && echo ok || echo missing")
check "backup exists" "$backup"

backup_files=$(ssh $SSH_OPTS "sysadmin@$SERVER_IP" "sudo ls /var/backups/final-project/latest/ 2>/dev/null | grep -c '\.tar\.gz'")
check "backup has files ($backup_files)" "$( [[ "$backup_files" -ge 3 ]] && echo ok || echo "only $backup_files" )"

echo "--- Kernel ---"
syncookies=$(ssh $SSH_OPTS "sysadmin@$SERVER_IP" "sysctl -n net.ipv4.tcp_syncookies")
check "tcp_syncookies on" "$( [[ "$syncookies" == "1" ]] && echo ok || echo "got $syncookies" )"

echo ""
echo "done: $PASS passed, $FAIL failed"
