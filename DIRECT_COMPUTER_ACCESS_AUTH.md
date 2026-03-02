# Direct Computer Access with Username/Password Authentication

## Overview

This guide shows you how to make your computer directly accessible from the internet with username/password authentication, so your team can access the Shiny app from anywhere.

**What you'll achieve:**
- ✅ Your computer accessible from internet (not just local network)
- ✅ Stable URL (yourname.ddns.net:3838) even if your IP changes
- ✅ Username/password required to access app
- ✅ Multiple users with different credentials
- ✅ Secure setup with proper hardening

**Time:** 30-40 minutes
**Cost:** Free (optional paid features: $5-10/month)
**Difficulty:** Medium

---

## Prerequisites

Before starting, verify you have:

- [ ] **Router access** - You can log into your home/office router
- [ ] **Public IP** - Your internet connection has a public IP (most do)
- [ ] **Computer stays on** - Your computer can stay on when you're away
- [ ] **R and packages** - Shiny app already working locally
- [ ] **Port 3838 available** - Not blocked by ISP (most aren't)

**Check your public IP:** Visit https://www.whatismyip.com/

---

## Part 1: Router Configuration (Port Forwarding)

### Step 1: Find Your Local IP Address

**Windows:**
```bash
ipconfig
# Look for "IPv4 Address" under your active connection
# Example: 192.168.1.100
```

**Mac/Linux:**
```bash
ifconfig
# or
ip addr show
# Look for inet address on active connection
# Example: 192.168.1.100
```

### Step 2: Access Your Router

1. Open web browser
2. Go to router admin page (usually one of these):
   - http://192.168.1.1
   - http://192.168.0.1
   - http://10.0.0.1
3. Log in with admin credentials
   - Often on sticker on router
   - Default: admin/admin or admin/password

### Step 3: Configure Port Forwarding

**Find the section** (varies by router brand):
- Look for: "Port Forwarding", "Virtual Server", "NAT", "Applications"
- Usually under: Advanced → NAT or Firewall → Port Forwarding

**Add new rule:**
```
Service Name: Shiny App
External Port: 3838
Internal IP: 192.168.1.100 (your computer's local IP)
Internal Port: 3838
Protocol: TCP (or Both)
```

**Save and Apply** - Router may need to reboot

### Step 4: Test Port Forwarding

1. Find your public IP: https://www.whatismyip.com/
2. From your phone (using cellular data, not WiFi):
   - Open browser
   - Go to: http://YOUR_PUBLIC_IP:3838
   - Should see your app (if running)

**If it doesn't work:**
- Check firewall on computer (allow port 3838)
- Verify router rule is active
- Ensure app is running on port 3838
- Some ISPs block certain ports - try port 8080 instead

---

## Part 2: Dynamic DNS (Stable URL)

### Why You Need This

Your public IP address might change (most home internet does). Dynamic DNS gives you a stable URL (yourname.ddns.net) that automatically updates to your current IP.

### Option A: No-IP (Recommended)

**1. Create Account**
- Go to: https://www.noip.com/
- Sign up for free account
- Verify email

**2. Create Hostname**
- Log in to No-IP dashboard
- Click "Create Hostname"
- Choose: yourappname.ddns.net (or other free domain)
- Enter your current public IP (auto-filled)
- Click "Create Hostname"

**3. Install Update Client (DUC)**

**Windows:**
- Download DUC: https://www.noip.com/download
- Install and run
- Log in with No-IP credentials
- Select your hostname
- It will auto-update your IP when it changes

**Mac/Linux:**
```bash
# Install
cd /usr/local/src
wget https://www.noip.com/client/linux/noip-duc-linux.tar.gz
tar xzf noip-duc-linux.tar.gz
cd noip-2.1.9-1
sudo make
sudo make install

# Configure
sudo /usr/local/bin/noip2 -C
# Enter your No-IP credentials and hostname

# Start
sudo /usr/local/bin/noip2
```

**4. Test**
- Wait 5 minutes for DNS to propagate
- From phone (4G) or friend's computer:
  - Visit: http://yourappname.ddns.net:3838
  - Should see your app

### Option B: DuckDNS (Alternative)

**1. Go to:** https://www.duckdns.org/
**2. Log in** with Google/GitHub
**3. Create subdomain:** yourappname.duckdns.org
**4. Install update script** following their instructions

---

## Part 3: Add Username/Password Authentication

### Use app_authenticated.R

The repository already includes `app_authenticated.R` with authentication built-in.

### Configure Users

**Edit app_authenticated.R:**

```r
# Define users and passwords
credentials <- data.frame(
  user = c("admin", "analyst1", "analyst2", "viewer1"),
  password = c(
    "Change_This_Admin_Pass_123!",
    "Change_This_Analyst_Pass_456!",
    "Change_This_Analyst_Pass_789!",
    "Change_This_Viewer_Pass_012!"
  ),
  admin = c(TRUE, FALSE, FALSE, FALSE),
  stringsAsFactors = FALSE
)
```

**Password Requirements:**
- Minimum 12 characters
- Include: uppercase, lowercase, numbers, symbols
- Unique for each user
- NOT the defaults shown above!

### Start Authenticated App

```r
shiny::runApp("app_authenticated.R", host = "0.0.0.0", port = 3838)
```

### Test Authentication

1. Open browser
2. Go to: http://yourappname.ddns.net:3838
3. Should see login screen
4. Enter username and password
5. Should gain access to app

**If no login screen appears:**
- Ensure you're using app_authenticated.R (not app_local.R)
- Check that shinymanager package is installed
- Restart the app

---

## Part 4: Security Hardening

### Critical Security Measures

#### 1. Strong Passwords ⚠️ REQUIRED

```r
# Bad - NEVER do this
password = "password123"

# Good - Strong password
password = "Xk9#mP2$vL5@nQ8!"
```

**Generate strong passwords:**
- Use password manager (LastPass, 1Password)
- Or: https://passwordsgenerator.net/
- Minimum 12 characters
- Random mix of characters

#### 2. Firewall Configuration

**Windows Firewall:**
```powershell
# Allow inbound on port 3838
New-NetFirewallRule -DisplayName "Shiny App" -Direction Inbound -LocalPort 3838 -Protocol TCP -Action Allow
```

**Linux (ufw):**
```bash
sudo ufw allow 3838/tcp
sudo ufw enable
```

**Mac:**
- System Preferences → Security & Privacy → Firewall
- Firewall Options → Add R
- Allow incoming connections

#### 3. HTTPS Setup (Highly Recommended)

**Why:** Encrypts traffic, prevents password interception

**Using Caddy (Easiest):**

```bash
# Install Caddy
# Mac
brew install caddy

# Linux
sudo apt install caddy

# Create Caddyfile
cat > Caddyfile << EOF
yourappname.ddns.net {
    reverse_proxy localhost:3838
}
EOF

# Start Caddy (auto-gets SSL cert)
sudo caddy run
```

**Result:** Access via https://yourappname.ddns.net (no port number!)

**Note:** For Let's Encrypt to work, your domain must be accessible from internet

#### 4. Monitor Access

**Add logging to app_authenticated.R:**

```r
# After successful authentication
observe({
  if (!is.null(res_auth)) {
    log_entry <- paste0(
      Sys.time(), " - ",
      "User: ", res_auth$user, " - ",
      "IP: ", session$clientData$url_hostname
    )
    write(log_entry, file = "access.log", append = TRUE)
  }
})
```

**Check logs:**
```bash
tail -f access.log
```

#### 5. Regular Updates

```bash
# Update R packages monthly
R -e "update.packages(ask = FALSE)"

# Keep computer OS updated
# Windows: Settings → Update & Security
# Mac: System Preferences → Software Update
# Linux: sudo apt update && sudo apt upgrade
```

#### 6. Fail2Ban (Advanced - Linux only)

**Protects against brute force attacks:**

```bash
# Install
sudo apt install fail2ban

# Configure for Shiny
sudo nano /etc/fail2ban/jail.local

# Add:
[shiny]
enabled = true
port = 3838
filter = shiny
logpath = /path/to/access.log
maxretry = 5
bantime = 3600
```

---

## Part 5: Testing

### Internal Test (From Your Network)

```bash
# 1. Start app
shiny::runApp("app_authenticated.R", host = "0.0.0.0", port = 3838)

# 2. From another device on same network
# Open browser, go to:
http://192.168.1.100:3838

# 3. Should see login screen
# 4. Log in with credentials
# 5. Verify app works
```

### External Test (From Internet)

```bash
# From phone (using 4G, NOT WiFi)
# Or from friend's computer at different location

# 1. Open browser
# 2. Go to:
http://yourappname.ddns.net:3838

# Or if using HTTPS:
https://yourappname.ddns.net

# 3. Should see login screen
# 4. Log in with credentials
# 5. Test all app features
```

### Verification Checklist

- [ ] Can access from phone (4G)
- [ ] Login screen appears
- [ ] Valid credentials work
- [ ] Invalid credentials rejected
- [ ] App functions normally after login
- [ ] Can run Stan model
- [ ] Results display correctly
- [ ] Can log out
- [ ] URL is stable (works after router reboot)

---

## Part 6: Sharing Access with Team

### What to Share

**Send to each team member:**

```
Bayesian PoS Simulation App Access

URL: http://yourappname.ddns.net:3838
(or https://yourappname.ddns.net if you set up SSL)

Your Credentials:
Username: analyst1
Password: [Send via secure channel - don't put in same email]

Instructions:
1. Open the URL in your web browser
2. Enter your username and password
3. The app will load after successful login
4. Click "Run Stan Model" to run analysis

Note: Please keep your credentials secure and don't share them.
```

**Security Best Practices:**
- Send password separately (not in same email as username)
- Use secure messaging (Signal, WhatsApp) for passwords
- Change default passwords immediately
- Each person gets unique credentials

### Adding New Users

**Edit app_authenticated.R:**

```r
credentials <- data.frame(
  user = c("admin", "analyst1", "analyst2", "newuser"),  # Add here
  password = c("AdminPass!", "A1Pass!", "A2Pass!", "NewUserPass!"),  # Add here
  admin = c(TRUE, FALSE, FALSE, FALSE),  # Admin status
  stringsAsFactors = FALSE
)
```

**Restart app** for changes to take effect.

### Removing Users

**Simply delete the row from credentials data frame and restart app.**

---

## Part 7: Troubleshooting

### Issue: Cannot Connect from Outside

**Symptoms:** Works locally but not from internet

**Solutions:**
1. **Check port forwarding:**
   - Log into router
   - Verify rule is enabled
   - Correct internal IP?
   - Try router reboot

2. **Check firewall:**
   ```bash
   # Windows - temporarily disable to test
   # If it works, create rule for port 3838
   
   # Linux - check rules
   sudo ufw status
   ```

3. **Check app is listening on 0.0.0.0:**
   ```r
   # Must use host = "0.0.0.0", not "127.0.0.1"
   shiny::runApp("app_authenticated.R", host = "0.0.0.0", port = 3838)
   ```

4. **ISP blocking:**
   - Some ISPs block common ports
   - Try port 8080 instead of 3838
   - Update port forwarding rule
   - Update app to use port 8080

5. **Dynamic DNS not updated:**
   - Check No-IP dashboard
   - Is IP correct?
   - Restart DUC client
   - Wait 5 minutes for DNS propagation

### Issue: Login Screen Doesn't Appear

**Symptoms:** Goes straight to app without authentication

**Solutions:**
1. **Wrong file:**
   - Ensure running `app_authenticated.R`, not `app_local.R`

2. **Missing package:**
   ```r
   install.packages("shinymanager")
   ```

3. **Check code:**
   ```r
   # UI must be wrapped
   ui <- secure_app(ui_original)
   
   # Server must have secure_server
   res_auth <- secure_server(check_credentials = check_credentials(credentials))
   ```

### Issue: "Invalid Credentials" Even with Correct Password

**Solutions:**
1. **Check credentials exactly:**
   - Passwords are case-sensitive
   - No extra spaces
   - Check special characters

2. **Restart app:**
   - After changing credentials, must restart
   - Stop with Ctrl+C
   - Start again

3. **Check data frame:**
   ```r
   print(credentials)
   # Verify usernames and passwords are correct
   ```

### Issue: App is Slow

**Solutions:**
1. **Reduce MCMC iterations:**
   - Use 2000 instead of 4000
   - Use 1 chain for testing

2. **Limit concurrent users:**
   - Check how many people connected
   - App shares computer resources

3. **Increase computer resources:**
   - Close other programs
   - Add more RAM if possible

4. **Network bandwidth:**
   - Check your upload speed
   - May need better internet plan

### Issue: Router Doesn't Have Port Forwarding

**Solutions:**
1. **Double-NAT situation:**
   - ISP router + your router
   - Need to forward on BOTH
   - Or put your router in bridge mode

2. **ISP restrictions:**
   - Some ISPs block port forwarding
   - Contact ISP for "bridged mode"
   - Or use alternative (ngrok, VPN)

3. **Use alternative:**
   - See REMOTE_ACCESS_GUIDE.md for ngrok option

---

## Part 8: Maintenance

### Regular Tasks

**Weekly:**
- [ ] Check access logs for unusual activity
- [ ] Verify app is running and accessible

**Monthly:**
- [ ] Update R packages
- [ ] Check Dynamic DNS is working
- [ ] Review user accounts (remove old users)
- [ ] Test access from external location

**Quarterly:**
- [ ] Change passwords
- [ ] Update computer OS
- [ ] Review security settings
- [ ] Test backup/restore procedure

### Monitoring

**Check who's connected:**
```r
# Add to server in app_authenticated.R
observe({
  print(paste("Connected sessions:", session$ns(NULL)))
})
```

**Monitor computer resources:**
- **Windows:** Task Manager → Performance
- **Mac:** Activity Monitor
- **Linux:** `htop` or `top`

**Set up alerts** (advanced):
- Email when app goes down
- Alert on high resource usage
- Notify on failed login attempts

### Backup

**Back up these files regularly:**
```bash
# App files
cp app_authenticated.R app_authenticated_backup_$(date +%Y%m%d).R
cp stan_universal_model_optimized.stan stan_backup_$(date +%Y%m%d).stan

# Logs
cp access.log access_log_backup_$(date +%Y%m%d).log
```

---

## Part 9: Cost Analysis

### Free Setup (Recommended)

```
Router port forwarding: $0
Dynamic DNS (No-IP free): $0
SSL (Let's Encrypt): $0
Authentication (shinymanager): $0
Computer electricity: ~$5-10/month
─────────────────────────────
TOTAL: $5-10/month
```

### Enhanced Setup

```
Router port forwarding: $0
Dynamic DNS (No-IP Plus): $25/year = $2/month
Static IP from ISP: $5-10/month
SSL (Let's Encrypt): $0
VPN (optional): $5-10/month
Computer electricity: ~$5-10/month
─────────────────────────────
TOTAL: $17-32/month
```

### Comparison with Cloud

```
Your Computer Direct: $5-10/month
shinyapps.io Starter: $9/month
shinyapps.io Standard: $99/month
AWS EC2 t3.small: ~$15-20/month
DigitalOcean Droplet: $12-24/month
```

**Your setup is cost-competitive!**

---

## Summary

### What You've Accomplished

✅ **Direct computer access from internet**
- Anyone can reach your computer via stable URL
- No cloud service needed
- Full control over hosting

✅ **Username/password authentication**
- Login required before accessing app
- Multiple users supported
- Admin and regular user roles

✅ **Security hardening**
- Strong passwords
- Firewall configured
- Optional HTTPS
- Access logging

✅ **Professional setup**
- Stable URL (yourname.ddns.net)
- Works from anywhere
- Reliable access for team

### Quick Reference

**Start app:**
```r
shiny::runApp("app_authenticated.R", host = "0.0.0.0", port = 3838)
```

**Team accesses:**
```
URL: http://yourappname.ddns.net:3838
Login: username + password
```

**Add user:**
- Edit credentials in app_authenticated.R
- Restart app

**Check logs:**
```bash
tail -f access.log
```

---

## Support Resources

**Router Help:**
- Port Forwarding guides: https://portforward.com/
- Router-specific instructions available

**Dynamic DNS:**
- No-IP documentation: https://www.noip.com/support
- DuckDNS help: https://www.duckdns.org/

**Security:**
- Let's Encrypt: https://letsencrypt.org/
- Strong password generator: https://passwordsgenerator.net/

**In This Repository:**
- `app_authenticated.R` - Authentication example
- `ONLINE_DEPLOYMENT_AUTH.md` - Alternative deployment
- `OWN_COMPUTER_SERVER_GUIDE.md` - Local network guide

---

## Next Steps

1. **Read this guide completely** (10 minutes)
2. **Configure router** (15 minutes)
3. **Set up Dynamic DNS** (10 minutes)
4. **Configure authentication** (5 minutes)
5. **Test access** (10 minutes)
6. **Share with team** (5 minutes)

**Total: 55 minutes to fully operational remote access!**

**You now have direct access to your computer from the internet with full username/password protection!** 🔒🌍
