# Security Design
**Name:** Althea Barbato

---

## Defense in depth

The idea was to not rely on any single control. If one thing fails, something else catches it. Here's how the layers stack:

**Network level:** Oracle VCN only allows specific ports in. Even if UFW was misconfigured, traffic hitting a port not in the VCN allow list would never reach the server.

**Host firewall:** UFW with default deny. Only ports 22, 80, 443, 9090, 3000, 3001, 9100, 9113 are open. iptables handles the Docker traffic that UFW can miss.

**SSH:** Key-only authentication, root login disabled, MaxAuthTries 3, 5 minute idle timeout, X11 and agent forwarding off. The attack surface for SSH is basically just "steal the private key."

**Brute force protection:** fail2ban bans any IP that fails SSH authentication 3 times in 10 minutes, for 1 hour. This makes automated scanning basically useless.

**Audit logging:** auditd watches /etc/passwd, /etc/shadow, /etc/sudoers, and /etc/ssh/sshd_config. Any write to those files gets logged with timestamp and user. If someone gets in and tries to escalate, there's a record.

**TLS:** Let's Encrypt cert on althea-lab.duckdns.org. Real trusted cert, not self-signed. Auto-renews every 90 days via cron. HSTS header forces HTTPS for return visitors. TLS 1.2/1.3 only.

**Kernel hardening:** SYN cookies for flood protection, no ICMP redirects, reverse path filtering, dmesg restricted to root, SUID core dumps disabled.

**Least privilege:** Unnecessary services and packages removed (telnet, rsh, talk, finger, cups, avahi). /tmp mounted noexec/nosuid/nodev so scripts dropped there can't run.

**Auto-updates:** unattended-upgrades handles security patches automatically so the kernel and packages stay current without manual intervention.

---

## Known weaknesses

Prometheus at :9090 has no authentication. The /metrics endpoint is world-readable. This exposes system metric data to anyone who knows the IP. Fixing it properly requires a reverse proxy with basic auth in front of Prometheus, which was out of scope.

All monitoring ports are accessible from any IP. Ideally these would be behind a VPN or restricted by source IP.

Off-server backups aren't set up. Backups sit on the same disk as the server. A disk failure takes out both the data and the backup. S3 or similar would fix this.

Single server with no redundancy. If the instance goes down, everything goes down.

---

## What was prioritized

SSH hardening and TLS were the two highest priorities since those are the main attack surfaces for an internet-facing server. Everything else built out from there.
