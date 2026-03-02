# Remote Access Guide - Bayesian PoS Simulation

## Overview

This guide explains **how to access your Shiny app remotely** from outside your local network. 

You have **4 main options**, ranging from quick/easy (ngrok) to secure/professional (cloud deployment).

---

## Quick Comparison

| Method | Setup Time | Monthly Cost | Security | Computer Always On? | Best For |
|--------|-----------|--------------|----------|---------------------|----------|
| **ngrok** ⭐ | 5 min | Free / $5 | Medium | While using | Quick demos, testing |
| **Port Forwarding** | 30-60 min | Free | Low ⚠️ | Yes | Small dedicated server |
| **VPN** 🔒 | 1-2 hours | $0-10 | High ✅ | Yes | Secure team access |
| **Cloud** 💼 | 15 min | $0-100 | High ✅ | No | Production, professional |

---

## Option 1: ngrok (Recommended for Quick Testing) ⭐

### What It Is

ngrok creates a secure tunnel from the public internet to your local machine. No router configuration needed!

### Pros

- ✅ Works anywhere (coffee shop, behind firewall, no router access)
- ✅ Free tier available
- ✅ HTTPS by default (secure)
- ✅ No firewall or router configuration
- ✅ Perfect for demos and testing

### Cons

- ⚠️ URL changes every time you restart (unless paid plan)
- ⚠️ Free tier has connection/bandwidth limits
- ⚠️ Requires ngrok process running
- ⚠️ Third-party service (privacy consideration)

### Setup (5 minutes)

**Step 1: Download ngrok**
```bash
# Go to https://ngrok.com/download
# Or:
# Mac: brew install ngrok
# Windows: Download from website
```

**Step 2: Start your Shiny app**
```r
shiny::runApp("app_local.R", port = 3838)
```

**Step 3: Create tunnel (in new terminal)**
```bash
ngrok http 3838
```

**Step 4: Share the URL**
```
ngrok will display:
Forwarding    https://abc123def.ngrok.io -> http://localhost:3838

Share this URL: https://abc123def.ngrok.io
```

### Example Session

```bash
# Terminal 1: Start R app
$ R
> shiny::runApp("app_local.R", port = 3838)
Listening on http://127.0.0.1:3838

# Terminal 2: Start ngrok
$ ngrok http 3838
ngrok                                                          

Session Status                online
Account                       user@email.com (Plan: Free)
Forwarding                    https://abc123def.ngrok.io -> http://localhost:3838

# Share https://abc123def.ngrok.io with your team!
```

### Free vs Paid

**Free Tier:**
- Random URL each time
- 1 concurrent tunnel
- 40 connections/minute
- Good for testing/demos

**Paid Plans ($5-10/month):**
- Custom subdomain (e.g., your-app.ngrok.io)
- More connections
- Reserved URLs
- Better for regular use

### Security with ngrok

**Recommended:**
- Use app_authenticated.R (adds login screen)
- Or configure ngrok Basic Auth:
  ```bash
  ngrok http -auth="username:password" 3838
  ```

### Troubleshooting

**"ngrok not found"**
- Download from ngrok.com
- Add to PATH or use full path

**"Too many connections"**
- Upgrade to paid plan
- Or use different method

**"Tunnel expired"**
- Free tier: Restart ngrok every ~2 hours
- Paid: No expiration

---

## Option 2: Port Forwarding (For Permanent Setup)

### What It Is

Configure your router to forward incoming internet requests to your computer running the Shiny app.

### Pros

- ✅ Permanent solution (no third-party)
- ✅ Free
- ✅ Direct connection
- ✅ Full control

### Cons

- ⚠️ Requires router access/configuration
- ⚠️ Exposes computer to internet (security risk)
- ⚠️ Public IP may change (need Dynamic DNS)
- ⚠️ Computer must stay on 24/7
- ⚠️ More complex troubleshooting

### Setup (30-60 minutes)

**Step 1: Find your local IP**
```bash
# Windows
ipconfig
# Look for IPv4 Address: 192.168.1.xxx

# Mac/Linux
ifconfig
# or
ip addr show
```

**Step 2: Find your public IP**
```
Visit: https://whatismyip.com
Note your public IP (e.g., 203.0.113.45)
```

**Step 3: Configure router port forwarding**

1. Access router admin (usually http://192.168.1.1 or http://192.168.0.1)
2. Find "Port Forwarding" or "Virtual Server" section
3. Add new rule:
   - External Port: 3838
   - Internal IP: 192.168.1.xxx (your computer)
   - Internal Port: 3838
   - Protocol: TCP
4. Save and apply

**Step 4: Configure firewall**

```bash
# Windows Firewall
# Control Panel → Windows Defender Firewall → Advanced Settings
# Inbound Rules → New Rule → Port → TCP 3838 → Allow

# Mac Firewall
# System Preferences → Security & Privacy → Firewall → Firewall Options
# Add shiny-server or R → Allow

# Linux (ufw)
sudo ufw allow 3838/tcp
```

**Step 5: Test and share**

```
Your app is now at: http://YOUR_PUBLIC_IP:3838
Example: http://203.0.113.45:3838
```

### Dynamic DNS (If IP Changes)

If your ISP changes your public IP frequently:

1. Sign up for free Dynamic DNS service (No-IP, DuckDNS, etc.)
2. Get a hostname (e.g., yourapp.ddns.net)
3. Install their update client on your computer
4. Share the hostname instead of IP

### Security Warnings ⚠️

**CRITICAL:** Port forwarding exposes your computer to the internet!

**Required security measures:**
1. **USE AUTHENTICATION** - See app_authenticated.R
2. Keep OS and software updated
3. Use strong passwords
4. Consider firewall rules to limit access
5. Monitor access logs
6. Don't run as admin/root

**Never:**
- ❌ Port forward without authentication
- ❌ Use default passwords
- ❌ Expose without monitoring

### Troubleshooting

**Cannot connect from outside**
- Check router port forwarding is correct
- Verify firewall allows port 3838
- Confirm app is running on 0.0.0.0 (not 127.0.0.1)
- Test from different network (mobile data)

**Port forwarding not working**
- Some ISPs block port forwarding
- Try different port (8080, 8888)
- Check if behind carrier-grade NAT

**Connection slow or drops**
- Check upload bandwidth (affects serving pages)
- Reduce MCMC iterations/chains
- Consider cloud deployment

---

## Option 3: VPN (Most Secure) 🔒

### What It Is

Set up a Virtual Private Network so team members connect securely to your network first, then access the app as if they were on your local network.

### Pros

- ✅ Most secure option
- ✅ Encrypted traffic (VPN tunnel)
- ✅ User authentication required
- ✅ App not exposed to public internet
- ✅ Access other local resources too
- ✅ Enterprise-grade security

### Cons

- ⚠️ More complex setup
- ⚠️ Each user needs VPN software
- ⚠️ Requires VPN knowledge
- ⚠️ Router configuration may be needed

### Setup (1-2 hours)

### Option 3a: WireGuard VPN (Recommended)

**What:** Modern, fast, simple VPN

**Step 1: Install WireGuard on your computer**

```bash
# Mac
brew install wireguard-tools

# Windows
# Download from wireguard.com

# Ubuntu/Debian
sudo apt install wireguard

# Generate keys
wg genkey | tee privatekey | wg pubkey > publickey
```

**Step 2: Configure WireGuard server**

Create `/etc/wireguard/wg0.conf`:
```ini
[Interface]
PrivateKey = YOUR_PRIVATE_KEY
Address = 10.0.0.1/24
ListenPort = 51820

[Peer]
# Team member 1
PublicKey = TEAM_MEMBER_1_PUBLIC_KEY
AllowedIPs = 10.0.0.2/32

[Peer]
# Team member 2
PublicKey = TEAM_MEMBER_2_PUBLIC_KEY
AllowedIPs = 10.0.0.3/32
```

**Step 3: Start VPN server**

```bash
sudo wg-quick up wg0
```

**Step 4: Create client configs**

For each team member, create a config file:
```ini
[Interface]
PrivateKey = THEIR_PRIVATE_KEY
Address = 10.0.0.2/24  # Unique for each user

[Peer]
PublicKey = YOUR_SERVER_PUBLIC_KEY
Endpoint = YOUR_PUBLIC_IP:51820
AllowedIPs = 192.168.1.0/24  # Your local network
```

**Step 5: Team members connect**

1. Install WireGuard client
2. Import config file
3. Connect to VPN
4. Access app at: http://192.168.1.xxx:3838

### Option 3b: Tailscale (Easiest VPN)

**What:** Managed WireGuard VPN (easiest setup)

**Step 1: Sign up**
```
Visit: https://tailscale.com
Create account (free for personal use)
```

**Step 2: Install Tailscale**

```bash
# All your computers and team members install Tailscale
# Mac: brew install tailscale
# Windows/Linux: Download from tailscale.com
```

**Step 3: Start Tailscale**

```bash
sudo tailscale up
```

**Step 4: Share**

```
Each user gets a Tailscale IP (e.g., 100.101.102.103)
Share your Tailscale IP with team
They access: http://100.101.102.103:3838
```

**Benefits:**
- ✅ No router configuration
- ✅ Works behind any firewall
- ✅ Free for personal use
- ✅ Cross-platform
- ✅ Super easy

### Security with VPN

**Already Secure:**
- VPN handles authentication
- All traffic encrypted
- App not exposed to internet

**Optional:** Still use app_authenticated.R for additional layer

### Troubleshooting

**Cannot connect to VPN**
- Check firewall allows VPN port (51820 for WireGuard)
- Verify keys are correct
- Check VPN server is running

**Connected to VPN but cannot access app**
- Verify app is running
- Check app binds to correct IP
- Test connectivity: ping YOUR_LOCAL_IP

---

## Option 4: Cloud Deployment (Professional) 💼

### What It Is

Deploy your app to a cloud platform instead of running on your computer.

### Pros

- ✅ No computer needs to stay on
- ✅ Professional hosting
- ✅ High reliability/uptime
- ✅ Built-in security (HTTPS)
- ✅ Scalable
- ✅ No network configuration

### Cons

- ⚠️ Monthly cost ($0-100+)
- ⚠️ Some learning curve
- ⚠️ Data stored on third-party servers

### Cloud Platforms

We already have comprehensive guides for cloud deployment:

**For quick deployment:**
→ See `QUICK_AUTH_SETUP.md`

**For complete guide:**
→ See `ONLINE_DEPLOYMENT_AUTH.md`

**Recommended platform:** shinyapps.io (15 minutes setup)

### Quick Example (shinyapps.io)

```r
# 1. Install packages
install.packages("rsconnect")

# 2. Create account at shinyapps.io

# 3. Configure credentials (one-time)
rsconnect::setAccountInfo(
  name = "your-account",
  token = "your-token",
  secret = "your-secret"
)

# 4. Deploy
rsconnect::deployApp(
  appFiles = c("app_local.R", "global_local.R", 
               "server_local.R", "ui_local.R",
               "stan_universal_model_optimized.stan")
)

# 5. Get permanent URL
# https://your-account.shinyapps.io/app_local/
```

**See detailed guides** for authentication, custom domains, and more.

---

## Security Considerations

### Comparison

| Method | Encryption | Authentication | Exposure |
|--------|-----------|----------------|----------|
| **ngrok** | HTTPS ✅ | App-level | Public URL |
| **Port Forwarding** | HTTP ⚠️ | App-level | Your IP exposed |
| **VPN** | VPN + optional HTTPS ✅ | VPN + App ✅ | None ✅ |
| **Cloud** | HTTPS ✅ | Platform ✅ | Platform managed |

### Required Security Measures

**For ALL remote access:**

1. **USE AUTHENTICATION**
   - See `app_authenticated.R`
   - Or use `ONLINE_DEPLOYMENT_AUTH.md` for cloud options

2. **Use HTTPS when possible**
   - ngrok: Built-in
   - Port forwarding: Use reverse proxy (nginx + Let's Encrypt)
   - VPN: Not needed (already encrypted)
   - Cloud: Built-in

3. **Strong passwords**
   - 12+ characters
   - Mix of letters, numbers, symbols
   - Unique per user

4. **Monitor access**
   - Check logs regularly
   - Look for suspicious activity
   - Remove old user accounts

### Security Best Practices

**Recommended:**
- ✅ Use VPN for sensitive data
- ✅ Use cloud for production
- ✅ Use ngrok for quick demos only
- ✅ Always use authentication
- ✅ Keep software updated

**Avoid:**
- ❌ Port forwarding without authentication
- ❌ Using default passwords
- ❌ Leaving computer unattended with access
- ❌ Sharing credentials insecurely

---

## Troubleshooting

### Cannot Connect

**Check network:**
```bash
# Ping your server from remote location
ping YOUR_IP

# If ping fails, network issue
# Check firewall, router, ISP
```

**Check app:**
```bash
# Verify app is running
# Check it binds to 0.0.0.0 (not 127.0.0.1)
shiny::runApp("app_local.R", host = "0.0.0.0", port = 3838)
```

**Check firewall:**
```bash
# Allow port 3838
# Windows: Windows Defender Firewall → Allow port
# Mac: System Preferences → Security → Firewall
# Linux: sudo ufw allow 3838
```

### Slow Performance

**Reduce MCMC complexity:**
- Reduce iterations (4000 → 2000)
- Reduce chains (4 → 2)
- Use defaults where possible

**Check bandwidth:**
- Remote access requires good upload speed
- Test: speedtest.net
- Consider cloud if upload < 10 Mbps

**Optimize code:**
- Pre-compile Stan model (use precompile_model.R)
- Reduce data transfer
- Use efficient priors

### Connection Drops

**For ngrok:**
- Free tier: Reconnect every 2 hours
- Paid: Should stay connected

**For Port Forwarding:**
- Check computer doesn't sleep
- Prevent R from timing out
- Monitor router uptime

**For VPN:**
- Keep VPN client running
- Check VPN server is up
- Verify network stability

### Authentication Issues

**Using app_authenticated.R:**
- Verify credentials are correct
- Check shinymanager package is installed
- See troubleshooting in ONLINE_DEPLOYMENT_AUTH.md

---

## Recommendations

### Quick Answer

**Need to demo TODAY?**
→ Use **ngrok** (5 minutes)

**Small team on local network?**
→ See `OWN_COMPUTER_SERVER_GUIDE.md`

**Remote team, security important?**
→ Use **VPN** (Tailscale is easiest)

**Production deployment?**
→ Use **Cloud** (shinyapps.io recommended)

**Permanent server on your computer?**
→ Use **VPN** (most secure) or **Port Forwarding** (if low security needs)

### By Use Case

**Academic Collaboration:**
- ngrok for quick demos
- VPN for ongoing access
- Cloud for publication supplements

**Industry/Pharma:**
- VPN for internal use
- Cloud for external stakeholders
- Authentication REQUIRED

**Personal Projects:**
- ngrok for friends/family
- Cloud for public sharing

**Enterprise:**
- VPN or RStudio Connect
- IT department involved
- Full security audit

---

## Cost Breakdown

### Free Options

- ngrok Free Tier: Limited connections
- Port Forwarding: Free (router required)
- WireGuard VPN: Free software (you host)
- Tailscale: Free personal use
- shinyapps.io: Free tier (25 hours/month)

### Paid Options

| Service | Monthly Cost | Best For |
|---------|-------------|----------|
| ngrok Pro | $5 | Regular demos |
| VPN Server (DigitalOcean) | $5-10 | Secure team access |
| Tailscale Pro | $5/user | Managed VPN |
| shinyapps.io Starter | $9 | Small team |
| shinyapps.io Basic | $39 | Medium team |
| shinyapps.io Standard | $99 | Production use |

---

## Summary

You have **4 main options** for remote access:

1. **ngrok** - Easiest (5 min), free, perfect for demos
2. **Port Forwarding** - Permanent but requires setup and has security risks
3. **VPN** - Most secure, best for teams with sensitive data
4. **Cloud** - Professional, no computer needed, recommended for production

**For most users:**
- Testing: ngrok
- Team access: VPN (Tailscale)
- Production: Cloud (shinyapps.io)

**Always use authentication** (see app_authenticated.R or deployment guides)

---

## Related Documentation

- `OWN_COMPUTER_SERVER_GUIDE.md` - Local network access
- `ONLINE_DEPLOYMENT_AUTH.md` - Cloud deployment with authentication
- `QUICK_AUTH_SETUP.md` - Fast cloud deployment
- `DEPLOYMENT_SUMMARY.md` - All deployment options overview
- `app_authenticated.R` - Authentication example code

---

## Questions?

**Need help choosing?**
→ Start with ngrok for testing, then move to cloud if you like it

**Security concerns?**
→ Use VPN or cloud, always use authentication

**Budget limited?**
→ Tailscale VPN (free personal) or shinyapps.io free tier

**Still stuck?**
→ Check troubleshooting sections in all guides
