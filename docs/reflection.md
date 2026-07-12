# Final Reflection
**Name:** Althea Barbato

---

## Where I started

At the beginning of this course I genuinely did not know what Ansible was. I had done some basic Linux stuff before but nothing close to managing a real server from scratch. The idea of writing infrastructure as code and having it be repeatable was something I'd heard of but never actually done. By the end of this I have a publicly accessible server with TLS, monitoring, alerting, automated backups, and security hardening, all deployed with a single command. That's a real difference.

---

## Operational growth

The biggest mindset shift for me was thinking about things being idempotent. Early on I was writing scripts that would just fail or do weird things if you ran them twice. Learning to write Ansible tasks so they check state before changing it meant that `bash deploy.sh` became something I could run over and over without worrying about breaking something that was already configured.

Getting the monitoring stack set up in Lab 3 changed how I think about running a server. Before that, if something broke you'd find out when you tried to use it. Now there are five alert rules and Uptime Kuma pinging every 60 seconds. Seeing Prometheus actually fire the InstanceDown alert when I stopped a container made it feel real.

The backup and restore cycle was something I underestimated. Writing the backup script was easy. Actually testing the restore by breaking nginx on purpose and seeing it come back from backup was the part that made me understand why it matters. It's one thing to have a backup. It's another to know the restore actually works.

---

## Security lessons

The three-layer firewall situation on Oracle Cloud surprised me. I kept opening ports in UFW and wondering why traffic still wasn't getting through, until I figured out Oracle VCN has its own security list that's completely separate. That's actually a good thing once you understand it but it was frustrating to debug.

fail2ban is doing real work. Even on a class project server, auth.log fills up with failed SSH attempts from automated scanners within hours of the server being public. fail2ban banning those IPs automatically means the noise stops showing up in the logs.

The auditd setup taught me to think about what I actually need to watch. You could audit everything but then the logs are useless because they're full of noise. Picking the four files that matter most (passwd, shadow, sudoers, sshd_config) and only watching those means if something shows up in the auditd logs it's actually worth looking at.

Let's Encrypt was a big upgrade from the self-signed cert in Lab 4. The self-signed cert encrypts traffic fine but browsers show a security warning which makes it look broken. Getting a real cert through certbot with DuckDNS for the domain meant https://althea-lab.duckdns.org works in a browser without any warnings. The auto-renewal cron means I don't have to remember to renew it every 90 days.

---

## Infrastructure tradeoffs

Single server is the obvious one. Everything on one box means a single point of failure. Oracle Cloud free tier gives two instances so load balancing is possible, but adding a second server would double the configuration complexity and was out of scope for this project. The tradeoff was simplicity over resilience.

Docker with --network host was a deliberate choice. The alternative is setting up Docker bridge networks and managing internal DNS, which is more correct but significantly more complex. Host networking means all the containers talk to each other on localhost, which is simple and works fine for a single-server monitoring stack.

On-server backups are better than no backups but worse than off-server backups. If the disk fails or the instance is terminated, the backups are gone. S3 would solve this but it costs money and was out of scope. The actual risk is low since Oracle Cloud free tier instances don't just disappear, but it's a real gap.

Prometheus having no authentication is something I'm not happy about but accepted as a known risk. The metrics it exposes are read-only and not sensitive, but it's not great that /metrics is open to the world. The right fix is a reverse proxy with basic auth in front of Prometheus, but setting that up cleanly with nginx and not breaking the Grafana connection was more complexity than I had time for.

---

## Real-world applicability

The Ansible structure I ended up with is closer to how real teams manage infrastructure than I expected when I started. Roles, handlers, idempotent tasks, variable files, separate playbooks for logical groups of work. The pattern of writing it locally, deploying to the server, and having a verify script to check the result is basically a simplified version of what CI/CD pipelines do.

The monitoring setup is genuinely useful. Prometheus + Grafana + alerting is what a lot of companies actually run. The dashboards I built are basic but the structure is the same. Learning how Prometheus scrapes work, how to write alert rules, and how Grafana provisioning works as code means I have a starting point for understanding more complex observability setups.

The security hardening gave me a practical list of things to check on any Linux server. SSH config, fail2ban, auditd, sysctl parameters, unnecessary services, auto-updates. That's a real checklist I can apply again. It also made me understand why security is layered. No single control is enough but each one raises the bar.

---

## What I'd do differently

Start with the domain from the beginning instead of switching from a self-signed cert to Let's Encrypt at the end. The cert migration caused some downtime and would have been cleaner to plan from the start.

Set up off-server backups. Even a simple cron job to copy the backup directory to an S3 bucket would have made the backup story much stronger.

Put Prometheus behind nginx with basic auth from the start instead of leaving the /metrics endpoint open. It's not hard but requires planning the nginx config around it from the beginning.

Write the verify script earlier. I ended up debugging deployment issues by SSH-ing into the server and manually checking things, which is slow. Having verify.sh catching problems automatically would have saved time.

---

## Closing

This was the most hands-on technical thing I've done in school so far. The gap between reading about SSH hardening and actually configuring it on a real server with real traffic hitting it is significant. I feel like I have a real baseline now for what it takes to run a production Linux service, which is what the course was supposed to do.
