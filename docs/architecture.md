# Architecture Overview
**Name:** Althea Barbato

---

## Infrastructure

Single Ubuntu 20.04 server on Oracle Cloud free tier (163.192.117.50). Public hostname: althea-lab.duckdns.org via DuckDNS (free dynamic DNS).

Three firewall layers sit in front of everything: Oracle VCN Security List, OS-level iptables, and UFW. All three have to allow a port for traffic to get through.

---

## Stack

```
Internet
    |
    v
Oracle VCN Security List (cloud firewall)
    |
    v
UFW + iptables (host firewall)
    |
    v
nginx (ports 80/443)
  - port 80 redirects to 443
  - port 443: Let's Encrypt TLS, serves /var/www/html
    |
    +-- Monitoring stack (Docker, --network host)
        |
        +-- Prometheus      :9090  scrapes node_exporter + nginx_exporter
        +-- node_exporter   :9100  system metrics
        +-- nginx_exporter  :9113  nginx metrics
        +-- Grafana         :3000  dashboards (3 provisioned)
        +-- Uptime Kuma     :3001  availability monitoring
```

---

## Security layers

| Layer | What it does |
|---|---|
| DuckDNS + Let's Encrypt | Real trusted TLS cert, auto-renews every 90 days |
| nginx HSTS | Forces HTTPS even if someone types http:// |
| UFW | Host-level firewall, default deny |
| iptables | Handles Docker network traffic UFW misses |
| Oracle VCN | Cloud-level allow list before traffic hits the server |
| fail2ban | Bans IPs after 3 failed SSH attempts, 1 hour ban |
| auditd | Watches /etc/passwd, /etc/shadow, sudoers, sshd_config |
| SSH hardening | Key-only, no root, MaxAuthTries 3, 5 min idle timeout |
| sysctl | SYN cookies, no ICMP redirects, rp_filter, dmesg restrict |

---

## Data flow

Browser hits althea-lab.duckdns.org on port 80/443. DuckDNS resolves to 163.192.117.50. Oracle VCN allows it. UFW/iptables allow it. nginx handles TLS termination and serves content.

Prometheus scrapes node_exporter and nginx_exporter every 15 seconds. Grafana reads from Prometheus. Uptime Kuma independently pings HTTP, HTTPS, and Prometheus every 60 seconds. Alerts fire through Prometheus alertmanager rules.

Backups run via cron at 2am, tar up configs, keep 7 days, delete old ones automatically.

---

## Diagram

```
[Browser]
    |  HTTPS (443)
    v
[DuckDNS] --> althea-lab.duckdns.org --> 163.192.117.50
    |
    v
[Oracle VCN Security List]
    |
    v
[UFW + iptables]
    |
    v
[nginx]
  |--[port 80]--> 301 redirect to HTTPS
  |--[port 443]--> serves site (Let's Encrypt TLS)
    |
    v
[Monitoring - Docker host network]
  Prometheus:9090 <-- node_exporter:9100
                  <-- nginx_exporter:9113
  Grafana:3000    <-- Prometheus
  Uptime Kuma:3001 (independent checks)
    |
    v
[Alerts] --> Prometheus rules --> Grafana alert panels
```
