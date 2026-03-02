# Using Your Own Computer as Shiny Server

## Overview

This guide shows you how to run the Bayesian PoS Simulation app on your own laptop/computer and share it with your team over your local network or internet.

**What You'll Get:**
- ✅ Run app on your laptop
- ✅ Share URL with team (no cloud hosting needed)
- ✅ Full control over data and computation
- ✅ No monthly hosting costs
- ✅ Use all your computer's cores for faster MCMC

---

## Quick Start (5 Minutes)

### Step 1: Start the App

Open R/RStudio and run:

```r
shiny::runApp("app_local.R", host = "0.0.0.0", port = 3838)
```

**What happens:**
- App compiles Stan model (1-2 minutes first time)
- Server starts listening on port 3838
- You'll see: "Listening on http://0.0.0.0:3838"

### Step 2: Find Your IP Address

**On Windows:**
```cmd
ipconfig
```
Look for "IPv4 Address" under your network adapter (e.g., 192.168.1.100)

**On Mac/Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```
Look for your local IP (e.g., 192.168.1.100)

### Step 3: Share with Team

Give your team this URL:
```
http://YOUR_IP:3838
```

**Example:** `http://192.168.1.100:3838`

**That's it!** Team members on the same network can now access the app.

---

## Network Setup Options

### Option 1: Local Network Only (Easiest, Most Secure)

**Who can access:** Anyone on your WiFi/LAN
**Security:** Firewall protects you from internet
**Setup time:** 0 minutes (just run the app)

**When to use:**
- Small team in same office
- All team members on same network
- Don't need remote access

### Option 2: Internet Access (More Complex, Less Secure)

**Who can access:** Anyone with the URL (from anywhere)
**Security:** Requires port forwarding + firewall rules
**Setup time:** 30-60 minutes

**When to use:**
- Team members work remotely
- Need access from home/different locations
- Willing to manage security

**⚠️ Warning:** Opening ports to the internet has security risks. Consider using VPN or SSH tunnel instead.

---

## Local Network Access (Recommended)

### Requirements

1. **Your computer:**
   - Running R with the app
   - Connected to WiFi/LAN

2. **Team members:**
   - Connected to SAME WiFi/LAN
   - Have a web browser

### Step-by-Step Setup

#### 1. Start the App

```r
# In R or RStudio
setwd("/path/to/POS-simulation")
shiny::runApp("app_local.R", host = "0.0.0.0", port = 3838)
```

**Important:** `host = "0.0.0.0"` allows external connections

**Don't use:** `host = "127.0.0.1"` (only allows local connections)

#### 2. Keep Your Computer Awake

**On Windows:**
- Settings → System → Power & Sleep
- Set "Put my device to sleep" to "Never" (when plugged in)

**On Mac:**
- System Preferences → Energy Saver
- Uncheck "Put hard disks to sleep when possible"
- Check "Prevent computer from sleeping automatically"

#### 3. Configure Firewall (If Needed)

**Windows Firewall:**
```powershell
# Run as Administrator
netsh advfirewall firewall add rule name="Shiny Server" dir=in action=allow protocol=TCP localport=3838
```

**Mac Firewall:**
1. System Preferences → Security & Privacy → Firewall → Firewall Options
2. Click "+" to add R or RStudio
3. Allow incoming connections

**Linux (ufw):**
```bash
sudo ufw allow 3838/tcp
```

#### 4. Share the URL

Find your IP address (see Quick Start Step 2), then share:
```
http://YOUR_IP:3838
```

**Test it yourself first:**
- Open a browser
- Go to `http://YOUR_IP:3838`
- Make sure app loads

---

## Internet Access (Advanced)

**⚠️ Security Warning:** Only do this if you understand the risks and need remote access.

### Prerequisites

- Static IP address or Dynamic DNS (like No-IP.com)
- Router admin access
- Understanding of port forwarding
- Firewall configuration knowledge

### Steps

#### 1. Set Up Port Forwarding

**In your router:**
1. Log into router admin panel (usually 192.168.1.1 or 192.168.0.1)
2. Find "Port Forwarding" or "Virtual Server" section
3. Add rule:
   - External Port: 3838
   - Internal Port: 3838
   - Internal IP: Your computer's local IP
   - Protocol: TCP

#### 2. Find Your Public IP

```r
# In R
library(httr)
content(GET("https://api.ipify.org?format=text"), as = "text")
```

Or visit: https://www.whatismyip.com/

#### 3. Share Public URL

Give team members:
```
http://YOUR_PUBLIC_IP:3838
```

**Example:** `http://98.123.45.67:3838`

### Security Recommendations

**If exposing to internet, you MUST:**

1. **Use Strong Authentication:**
   - Use `app_authenticated.R` instead of `app_local.R`
   - Set strong passwords
   - Change default credentials

2. **Use HTTPS:**
   - Get SSL certificate (Let's Encrypt)
   - Configure reverse proxy (nginx or Apache)
   - Redirect HTTP to HTTPS

3. **Monitor Access:**
   - Check server logs regularly
   - Watch for suspicious activity
   - Limit IP addresses if possible

4. **Use VPN (Better Option):**
   - Set up VPN server on your network
   - Team members connect via VPN
   - Access app as if on local network
   - Much more secure than port forwarding

---

## Resource Management

### Handling Multiple Users

The app is designed for multi-user access. Here's what happens:

**Concurrent Users:**
- Each user gets their own R session
- Stan models run in parallel
- System resources are shared

**Resource Usage:**

| Users | RAM Needed | CPU Cores Recommended |
|-------|------------|----------------------|
| 1 | 2 GB | 2-4 |
| 2-3 | 4 GB | 4-6 |
| 4-5 | 8 GB | 6-8 |
| 6-10 | 16 GB | 8-12 |

### Optimizing for Multiple Users

#### 1. Monitor Resource Usage

**On Windows:**
- Task Manager → Performance tab
- Watch CPU and Memory usage

**On Mac:**
- Activity Monitor
- Watch CPU and Memory usage

**On Linux:**
```bash
htop
```

#### 2. Adjust MCMC Settings

For multiple simultaneous users, reduce resource usage:

```r
# In the app UI:
# - Iterations: 2000 (default) or 1000 (faster)
# - Chains: 2-4 (default 4)
# - Use defaults otherwise
```

#### 3. Set Core Limits (Advanced)

In `global_local.R`, you can limit cores per user:

```r
# Find this line:
safe_set_mc_cores <- function() {
  total_cores <- parallel::detectCores()
  # ... existing code ...
  
  # MODIFY to limit cores:
  max_cores_per_session <- 2  # Limit each user to 2 cores
  mc_cores <- min(mc_cores, max_cores_per_session)
  
  # ... rest of function
}
```

---

## Troubleshooting

### Problem: "Cannot Connect" Error

**Causes & Solutions:**

1. **Wrong IP Address**
   - Double-check your IP
   - Make sure team member is using your computer's IP, not theirs

2. **Firewall Blocking**
   - Disable firewall temporarily to test
   - If works, add firewall rule (see above)

3. **Not on Same Network**
   - Verify both on same WiFi/LAN
   - For internet access, need port forwarding

4. **App Not Running**
   - Make sure R is still running
   - Check R console for errors

### Problem: App is Slow

**Causes & Solutions:**

1. **Too Many Concurrent Users**
   - Reduce iterations (4000 → 2000)
   - Reduce chains (4 → 2)
   - Ask users to run one at a time

2. **Computer Under Load**
   - Close other applications
   - Check Task Manager/Activity Monitor
   - Consider upgrading RAM

3. **Stan Compilation**
   - First run is always slow (1-2 min)
   - Subsequent runs are faster
   - Pre-compile model if needed

### Problem: Connection Drops

**Causes & Solutions:**

1. **Computer Went to Sleep**
   - Disable sleep mode (see above)
   - Keep computer plugged in

2. **Network Changed**
   - WiFi dropped and reconnected
   - IP address may have changed
   - Restart app and share new IP

3. **App Crashed**
   - Check R console for errors
   - Restart app
   - Review error logs

### Problem: ESS Warnings Still Appearing

**Even with non-centered parameterization:**

1. **Increase Iterations:**
   ```r
   # In UI: MCMC Iterations = 4000 (or 8000)
   ```

2. **Increase Adapt Delta:**
   ```r
   # In UI: Adapt Delta = 0.90 (or 0.95)
   ```

3. **Check Priors:**
   - Very wide priors can cause issues
   - Try more informative priors
   - Use Fisher-z prior (recommended)

---

## Advanced: Using RStudio Server

For a more robust setup, use RStudio Server:

### Install RStudio Server

**Ubuntu/Debian:**
```bash
sudo apt-get install gdebi-core
wget https://download2.rstudio.org/server/focal/amd64/rstudio-server-2023.12.0-369-amd64.deb
sudo gdebi rstudio-server-2023.12.0-369-amd64.deb
```

**Other platforms:** See https://posit.co/download/rstudio-server/

### Configure for Team Access

1. **Create User Accounts:**
   ```bash
   sudo adduser analyst1
   sudo adduser analyst2
   ```

2. **Set Passwords:**
   ```bash
   sudo passwd analyst1
   sudo passwd analyst2
   ```

3. **Access RStudio Server:**
   - URL: `http://YOUR_IP:8787`
   - Team members log in with their credentials
   - Each runs `shiny::runApp("app_local.R")` in their session

**Benefits:**
- User authentication built-in
- Each user has separate environment
- Audit trail (who ran what)
- More professional setup

---

## Security Best Practices

### For Local Network Use:

1. **Trusted Network Only**
   - Only share on networks you trust
   - Don't share on public WiFi

2. **Password-Protect WiFi**
   - Use WPA2 or WPA3
   - Strong WiFi password

3. **Know Who Has Access**
   - Only share URL with authorized team members
   - Change port if needed to prevent accidental discovery

### For Internet Use:

1. **Use Authentication** (CRITICAL)
   - Use `app_authenticated.R` with shinymanager
   - Strong passwords (12+ characters)
   - Change default passwords immediately

2. **Use HTTPS** (CRITICAL)
   - Never send passwords over HTTP
   - Set up SSL/TLS certificate
   - Use reverse proxy (nginx)

3. **Limit Access**
   - IP whitelist if possible
   - VPN instead of port forwarding
   - Regular password changes

4. **Monitor and Log**
   - Review access logs weekly
   - Watch for suspicious activity
   - Keep R and packages updated

---

## Comparison: Own Computer vs Cloud

| Aspect | Own Computer | Cloud (shinyapps.io) |
|--------|--------------|---------------------|
| **Cost** | $0/month | $0-99/month |
| **Setup** | 5 minutes | 15 minutes |
| **Control** | Full | Limited |
| **Data Privacy** | Complete | Trust provider |
| **Performance** | Your hardware | Limited on free tier |
| **Reliability** | You manage | Provider manages |
| **Access** | Network/Internet | Internet only |
| **Maintenance** | You do it | Provider does it |

**When to use your computer:**
- ✅ Small team, same location
- ✅ Sensitive data (stay in-house)
- ✅ Want full control
- ✅ Have good hardware

**When to use cloud:**
- ✅ Remote team
- ✅ Want zero maintenance
- ✅ Need 24/7 reliability
- ✅ Don't want to manage infrastructure

---

## Summary

**To run on your own computer:**

1. **Start app:**
   ```r
   shiny::runApp("app_local.R", host = "0.0.0.0", port = 3838)
   ```

2. **Find your IP:**
   - Windows: `ipconfig`
   - Mac/Linux: `ifconfig`

3. **Share URL:**
   ```
   http://YOUR_IP:3838
   ```

4. **Keep computer running:**
   - Disable sleep
   - Keep app running

**For team access:**
- Local network: Easy, secure (recommended)
- Internet: Complex, less secure (use VPN)

**For production:**
- Consider RStudio Server
- Use authentication
- Monitor resources

---

## Next Steps

1. **Test locally:**
   - Run app on your computer
   - Access from your browser: `http://localhost:3838`

2. **Test from another device:**
   - Use phone/tablet on same WiFi
   - Go to `http://YOUR_IP:3838`

3. **Share with one team member:**
   - Have them try accessing
   - Troubleshoot any issues

4. **Roll out to full team:**
   - Share URL and instructions
   - Monitor performance
   - Adjust as needed

**Your own computer is now a Shiny server!** 🚀
