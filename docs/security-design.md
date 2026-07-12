# Security Design
**Name:** Althea Barbato

---

## Defense in depth

The whole point was that no single control should be the only thing standing between the internet and the server. Each layer covers the gaps in the one before it.

**Network level:** Oracle VCN only allows specific ports in. Even if UFW was misconfigured, anything hitting a port not in the VCN allow list never reaches the server. It's a separate gate that I had to open manually in the Oracle console for each lab.

**Host firewall:** UFW with default deny. Only ports 22, 80, 443, 9090, 3000, 3001, 9100, 9113 are open. iptables runs alongside it to handle Docker traffic that UFW can miss.

**SSH:** Key-only auth, root login disabled, MaxAuthTries 3, 5 minute idle timeout, X11 forwarding off, agent forwarding off. The only real attack surface left is stealing the private key.

**Brute force protection:** fail2ban bans any IP that fails SSH auth 3 times in 10 minutes, for 1 hour. Automated scanners hit auth.log constantly on any internet-facing server, fail2ban makes that noise stop showing up.

**Audit logging:** auditd watches /etc/passwd, /etc/shadow, /etc/sudoers, and /etc/ssh/sshd_config. Any write to those files gets logged with timestamp and user. If someone got in and tried to escalate, there would be a record of it.

**TLS:** Let's Encrypt cert on althea-lab.duckdns.org. Real trusted cert, got it through certbot standalone mode during the deploy. Auto-renews every 90 days via cron. HSTS header so browsers remember to always use HTTPS. TLS 1.2/1.3 only. This was the upgrade from Lab 4 where I had a self-signed cert that caused browser warnings.

**Kernel hardening:** SYN cookies for flood protection, no ICMP redirects, reverse path filtering, dmesg restricted to root, SUID core dumps disabled. All applied via sysctl in Ansible.

**Least privilege:** Removed unnecessary packages (telnet, rsh, talk, finger) and disabled services that had no reason to run on a cloud server (cups, avahi-daemon were already gone from earlier labs). /tmp locked with noexec/nosuid/nodev.

**Auto-updates:** unattended-upgrades applies security patches automatically. Kernel updates still need a manual reboot but package-level patches happen without me doing anything.

---

## Known weaknesses

Prometheus at :9090 has no authentication. /metrics is open to anyone with the IP and port. The data is read-only system metrics so the actual risk is low, but it's not ideal. Fixing it properly means putting nginx in front of Prometheus with basic auth, which would add configuration complexity.

All monitoring ports are reachable from any IP. Ideally they'd be behind a VPN or restricted to known source IPs.

Backups are on the same server. Disk fails, backups gone. S3 would fix it.

Single server, no redundancy. If the instance goes down, everything goes down.

---

## What was prioritized

SSH hardening and real TLS were the top two since those are the main attack surfaces. Everything else built out from there across the four labs.
