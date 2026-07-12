# Architecture Overview
**Name:** Althea Barbato

---

## Infrastructure

Single Ubuntu 20.04 server on Oracle Cloud free tier at 163.192.117.50. Domain is althea-lab.duckdns.org, set up through DuckDNS (free dynamic DNS) pointing to the server IP.

There are three firewall layers in front of everything: Oracle VCN Security List at the cloud level, then iptables, then UFW on the host. All three have to allow a port for traffic to actually reach the server.

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
  port 80 redirects to 443
  port 443: Let's Encrypt TLS cert, HSTS, serves /var/www/html
    |
    v
Monitoring stack (Docker, --network host)
  Prometheus      :9090   scrapes node_exporter + nginx_exporter
  node_exporter   :9100   system metrics
  nginx_exporter  :9113   nginx metrics
  Grafana         :3000   3 provisioned dashboards
  Uptime Kuma     :3001   availability monitoring
```

---

## Security layers

| Layer | What it does |
|---|---|
| DuckDNS + Let's Encrypt | Real trusted TLS cert, auto-renews every 90 days via certbot cron |
| nginx HSTS | Forces HTTPS on return visits |
| UFW | Host firewall, default deny |
| iptables | Catches Docker traffic UFW misses |
| Oracle VCN | Cloud allow list, traffic blocked before it hits the server |
| fail2ban | Bans IPs after 3 failed SSH attempts, 1 hour ban time |
| auditd | Watches /etc/passwd, /etc/shadow, sudoers, sshd_config |
| SSH hardening | Key-only, no root, MaxAuthTries 3, 5 min idle timeout, X11 off |
| sysctl | SYN cookies, no ICMP redirects, rp_filter, dmesg restrict |

---

## How traffic flows

Browser hits althea-lab.duckdns.org on port 80 or 443. DuckDNS resolves to 163.192.117.50. Oracle VCN allows it through. UFW and iptables allow it. nginx terminates TLS and serves content. Port 80 just redirects to 443.

Prometheus scrapes node_exporter and nginx_exporter every 15 seconds. Grafana reads from Prometheus. Uptime Kuma independently pings HTTP, HTTPS, and Prometheus every 60 seconds. Alert rules in Prometheus fire if anything goes out of range.

Backups run at 2am via cron, tar up configs to /var/backups/final-project, keep 7 days, delete older ones automatically.

---

## Diagram

```
[Browser]
    |  HTTP/HTTPS
    v
[DuckDNS] althea-lab.duckdns.org -> 163.192.117.50
    |
    v
[Oracle VCN Security List]
    |
    v
[UFW + iptables]
    |
    v
[nginx]
  port 80  -> 301 redirect to HTTPS
  port 443 -> serves site, Let's Encrypt TLS, HSTS
    |
    v
[Docker containers, host network]
  Prometheus:9090 <- node_exporter:9100
                  <- nginx_exporter:9113
  Grafana:3000    <- Prometheus
  Uptime Kuma:3001 (independent availability checks)
    |
    v
[Prometheus alert rules -> Grafana dashboards]
```
