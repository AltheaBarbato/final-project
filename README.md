# Final Project: Production Linux Deployment
**Name:** Althea Barbato

**Live URL:** https://althea-lab.duckdns.org
**Server:** 163.192.117.50 (Oracle Cloud free tier, Ubuntu 20.04)

Integrates everything from Labs 1-4 into a fully deployed, secured, monitored, and documented production-ready Linux server.

---

## What's running

- **nginx** serving HTTPS via Let's Encrypt cert on althea-lab.duckdns.org
- **Prometheus** collecting metrics from node_exporter and nginx_exporter
- **Grafana** with 3 provisioned dashboards (infrastructure, security events, availability)
- **Uptime Kuma** monitoring HTTP/HTTPS/Prometheus availability
- **fail2ban** blocking brute force SSH attempts
- **auditd** logging changes to sensitive system files
- **Automated nightly backups** with 7 day retention and tested restore

---

## Files

```
ansible/
  inventory.ini
  vars/main.yml
  site.yml
  roles/
    hardening/     - SSH, fail2ban, auditd, sysctl, least privilege
    tls/           - Let's Encrypt cert via certbot, nginx HTTPS config
    backup/        - backup and restore scripts, nightly cron

scripts/
  verify.sh        - 16 automated checks

docs/
  architecture.md
  security-design.md
  maintenance-plan.md
  reflection.md
```

---

## Deploying

```bash
bash deploy.sh
```

Idempotent. Safe to run again.

---

## Verifying

```bash
bash scripts/verify.sh
```

Checks DNS resolution, HTTPS via domain, HTTP redirect, Let's Encrypt cert, HSTS header, SSH hardening, fail2ban, auditd, UFW, Prometheus, Grafana, backup, and kernel hardening.

---

## Labs this builds on

| Lab | What it contributed |
|---|---|
| Lab 1 | Server provisioning, UFW, nginx, SSH key setup |
| Lab 2 | Ansible roles and playbook structure |
| Lab 3 | Prometheus, Grafana, Uptime Kuma, alerting, dashboards |
| Lab 4 | TLS, deeper hardening, auditd, fail2ban, backups |
| Final | DuckDNS domain, Let's Encrypt cert, HSTS, full integration |
