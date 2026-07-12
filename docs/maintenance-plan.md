# Operational Maintenance Plan
**Name:** Althea Barbato

---

## Routine tasks

### Daily (automated)
- Backups run at 2am via cron, tar up all configs, delete anything older than 7 days
- Prometheus scrapes node_exporter and nginx_exporter every 15 seconds
- Uptime Kuma pings HTTP, HTTPS, and Prometheus every 60 seconds
- unattended-upgrades checks for and installs security patches

### Weekly (manual check)
- Log into Grafana and glance at the three dashboards (infrastructure, security events, availability)
- Check fail2ban ban list for anything unusual: `sudo fail2ban-client status sshd`
- Check disk usage hasn't crept up: `df -h`
- Confirm backups are still running: `sudo ls -lh /var/backups/final-project/latest/`

### Monthly
- Review auditd logs for any writes to sensitive files: `sudo ausearch -k identity | tail -50`
- Check auth.log for patterns: `sudo grep "Failed password" /var/log/auth.log | wc -l`
- Make sure auto-updates have been applying: `sudo apt list --upgradable`
- Review UFW rules and remove any temporary denies that are no longer needed

---

## Certificate renewal

Let's Encrypt certs expire every 90 days. Certbot auto-renews via cron (runs at 3am daily, renews if within 30 days of expiry). To verify it's working:

```bash
sudo certbot renew --dry-run
```

To check when the cert expires:
```bash
sudo certbot certificates
```

---

## Adding monitoring alerts

Prometheus alert rules are in `/etc/prometheus/alert.rules.yml` on the server. To add a new rule, edit that file and reload Prometheus:

```bash
sudo docker restart prometheus
```

---

## Handling server updates

Since unattended-upgrades handles security patches, kernel updates sometimes need a manual reboot:

```bash
sudo reboot
```

After reboot, verify everything came back up:
```bash
bash scripts/verify.sh
```

---

## Updating DuckDNS if IP changes

Oracle Cloud free tier IPs don't change often but if the instance is stopped/started it might get a new IP. Update DuckDNS at duckdns.org with the new IP, then verify DNS resolves correctly:

```bash
dig +short althea-lab.duckdns.org
```

---

## If something breaks

See docs/incident-response-summary.md for specific runbooks. The short version:
1. Check what's down with `sudo docker ps -a` and `sudo systemctl status nginx`
2. Check logs for the specific service
3. Restart it
4. If data is corrupted, restore from backup: `sudo /usr/local/bin/restore.sh`
5. If completely broken, redeploy: `bash deploy.sh`
