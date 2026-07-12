# Final Reflection
**Name:** Althea Barbato

---

## Where I started

At the start of this course I had done some basic Linux stuff but had never managed a real server from scratch or written infrastructure as code. I didn't really know what Ansible was. By the end I have a publicly accessible server at althea-lab.duckdns.org with a real Let's Encrypt TLS cert, Prometheus monitoring with alerts, Grafana dashboards, automated backups with a tested restore, and security hardening, all deployed with a single command. That's a real difference from where I started.

---

## Operational growth

The biggest mindset shift was thinking about idempotency. Early on I was writing things that would just break or behave weirdly if you ran them twice. Learning to write Ansible tasks that check state before changing it meant that `bash deploy.sh` became something I could run over and over without worrying. By the end of the final project, running it a second time came back all ok, changed=0. That felt like actually understanding what I was doing rather than just hoping it worked.

Getting the monitoring stack set up in Lab 3 changed how I think about running a server. Before that, if something broke you'd find out when you went to use it. Now there are five Prometheus alert rules and Uptime Kuma pinging every 60 seconds. It actually fired the InstanceDown alert when I stopped a container to test it, which made it feel real.

The backup and restore cycle was underestimated by me. Writing the backup script was the easy part. Testing the restore by moving nginx.conf out of place on purpose and watching it come back from backup was what made me actually understand why backups matter. Having a backup and knowing the restore works are two different things.

The verify script pattern was something I came to really appreciate. Early in the labs I was debugging by SSH-ing in and manually checking things. Having a script that runs 15 checks and tells me pass or fail in 30 seconds is way better.

---

## Security lessons

The three-layer firewall situation on Oracle Cloud caught me off guard. I kept opening ports in UFW and traffic still wasn't getting through because the Oracle VCN Security List is completely separate. Once I understood that all three layers had to agree, it made sense. It's actually a good architecture even if it was frustrating to figure out.

fail2ban is doing real work on this server. Auth.log fills up with failed SSH attempts from automated scanners within hours of any internet-facing server going live. fail2ban banning those IPs automatically means the noise stops. It's not a theoretical security control, it's visibly doing something.

Auditd taught me to think about what actually matters to watch. You could log everything but then the logs are useless noise. Picking the four files that matter most (passwd, shadow, sudoers, sshd_config) means if something shows up in auditd it's worth reading.

The Let's Encrypt upgrade from Lab 4 was more meaningful than I expected. The self-signed cert technically encrypts traffic but browsers show a scary warning that makes it look broken. Getting a real cert through certbot with DuckDNS for the domain meant https://althea-lab.duckdns.org just works in a browser like a normal site. The auto-renewal cron means I don't have to remember to deal with it every 90 days either.

---

## Infrastructure tradeoffs

Single server was the obvious one. Everything on one box is a single point of failure. Oracle Cloud free tier gives two instances so load balancing is actually possible, but adding a second server would double the Ansible complexity and was out of scope.

Docker with --network host was a deliberate simplicity choice. The alternative is bridge networks and internal DNS, which is more correct but significantly more complex for a single-server setup. Host networking means all containers talk to each other on localhost, simple and works fine.

On-server backups are better than no backups but worse than off-server. If the disk fails, the backups go with it. S3 would fix this but costs money.

Prometheus having no auth is the thing I'm least happy about but accepted as a known risk. The metrics are read-only, but the endpoint is open. The right fix is nginx in front of Prometheus with basic auth. I didn't do it because setting that up without breaking the Grafana connection to Prometheus needed more time than I had.

---

## Real-world applicability

The Ansible structure I ended up with is closer to how real teams manage infrastructure than I expected. Roles, handlers, idempotent tasks, variable files. The pattern of writing locally, deploying to the server, and running a verify script to catch regressions is basically a simplified CI/CD pipeline.

The monitoring stack is what a lot of companies actually run. Prometheus and Grafana are real production tools. The dashboards I built are basic but the structure is the same. Understanding how Prometheus scrapes work, how to write alert rules, and how Grafana provisioning as code works is a real foundation.

The security hardening gave me a practical checklist I can apply on any Linux server. SSH config, fail2ban, auditd, sysctl, unnecessary services, auto-updates. That list travels to any future server I set up.

---

## What I'd do differently

Set up DuckDNS and Let's Encrypt from Lab 1 instead of using an IP the whole time and switching at the end. The cert migration was fine but having the domain from the start would have been cleaner.

Off-server backups from the beginning. Even a simple S3 sync after the nightly backup would have made the resilience story complete.

Write the verify script earlier. It would have saved a lot of SSH debugging sessions in the early labs.

---

## Closing

This was the most hands-on technical work I've done in school. The gap between reading about SSH hardening and actually configuring it on a real server with real automated scanners hitting it is significant. I have a real baseline now for what running a production Linux service involves and I feel like I'd know where to start if someone handed me a server and said make it production-ready.
