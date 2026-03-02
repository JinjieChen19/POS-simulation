# Local RStudio Server Deployment Guide

## Overview

This version is optimized for running on your **local laptop as an RStudio Server** and sharing with your team via network access. Key improvements:

1. ✅ **Compile Stan model ONCE** - Not on every prior change
2. ✅ **Prior changes passed as DATA** - No recompilation needed!
3. ✅ **Real-time progress display** - Shows sampling progress to users
4. ✅ **Multi-user support** - Multiple team members can use simultaneously
5. ✅ **Faster iterations** - Eliminates 1-2 minute compilation delay

---

## Quick Start

### 1. Files for Local Server

Use these files (instead of the original ui.R, server.R, global.R):

```
stan_universal_model.stan  <- Universal Stan model (compiles once)
global_local.R             <- Server configuration
server_local.R             <- Server logic with progress
ui_local.R                 <- User interface
```

### 2. Running the App

In RStudio, create a new file called `app_local.R`:

```r
# app_local.R - Local Server Version
# This file combines the local server components

# Source the files in order
source("global_local.R")     # Compiles Stan model (happens once)
ui <- source("ui_local.R")$value
server <- source("server_local.R")$value

# Run the app
shinyApp(ui = ui, server = server)
```

Then run:

```r
shiny::runApp("app_local.R", host = "0.0.0.0", port = 3838)
```

**Important:** Use `host = "0.0.0.0"` to allow network access from team members!

---

## Team Access Setup

### Option 1: Using RStudio Server (Recommended)

If you have RStudio Server installed on your laptop:

1. **Install RStudio Server:**
   - Linux: `sudo apt-get install rstudio-server`
   - Mac: Use RStudio Server Pro or docker
   - Windows: Use WSL2 + RStudio Server

2. **Configure user accounts:**
   ```bash
   # Create users for team members
   sudo useradd -m teamuser1
   sudo passwd teamuser1  # Set password
   ```

3. **Start RStudio Server:**
   ```bash
   sudo rstudio-server start
   ```

4. **Share access information with team:**
   - URL: `http://YOUR_LAPTOP_IP:8787`
   - Username: `teamuser1`
   - Password: (what you set)

5. **Team members access:**
   - Navigate to your laptop's URL
   - Log in with credentials
   - Open and run `app_local.R`

### Option 2: Direct Shiny App Sharing

Run the app directly and share the Shiny URL:

1. **On your laptop:**
   ```r
   library(shiny)
   runApp("app_local.R", host = "0.0.0.0", port = 3838)
   ```

2. **Find your laptop's IP address:**
   - Windows: `ipconfig`
   - Mac/Linux: `ifconfig` or `ip addr show`
   - Look for IP like `192.168.1.XXX`

3. **Share with team:**
   - URL: `http://YOUR_LAPTOP_IP:3838`
   - Team members access via browser
   - No login required (but less secure)

---

## Key Features

### 1. Single Stan Compilation

**How it works:**
- Stan model compiles ONCE when server starts (1-2 minutes)
- All users share the same compiled model
- Prior changes don't require recompilation!

**Startup messages:**
```
=== Compiling Universal Stan Model ===
This happens ONCE at server startup...
All users will share this compiled model.
Prior changes will NOT require recompilation.

Found Stan model file: stan_universal_model.stan
Compiling (this may take 1-2 minutes)...

✓ Universal Stan model compiled successfully!
  Compilation time: 87.3 seconds
  This model will be reused for all sessions.
  Prior changes will be passed as data (no recompilation).
```

### 2. Priors as Data (No Recompilation!)

**Traditional approach:**
```
User changes prior → Rebuild Stan code → Recompile (1-2 min) → Sample
```

**New approach:**
```
User changes prior → Pass as data to compiled model → Sample (instant!)
```

**Example:**
```r
# Changing from fisher_z to uniform prior:
# OLD: Waits 1-2 minutes to recompile
# NEW: Instant! Just passes different parameters as data
```

### 3. Real-Time Progress Display

When a user clicks "Run Model", they see:

```
MCMC Sampling in Progress...
============================================================

Configuration:
  Iterations: 2000
  Chains: 4
  Warmup: 1000
  Adapt delta: 0.99

Using pre-compiled universal model
(No compilation needed - priors passed as data)

Chain 1: Iteration:  1 / 2000 [  0%]
Chain 1: Iteration: 100 / 2000 [  5%]
...
Chain 4: Iteration: 2000 / 2000 [100%]

✓ MCMC Sampling Complete!
```

Progress bar also shows at top of screen with stages:
- Preparing data... (10%)
- Building Stan data... (20%)
- Starting MCMC sampling... (30%)
- [Sampling happens] (30-90%)
- Processing results... (90%)
- Complete! (100%)

---

## Performance Comparison

### Startup Time

| Scenario | Time | Notes |
|----------|------|-------|
| First server start | 2-3 min | Compiles universal Stan model |
| Subsequent user sessions | <1 sec | Model already compiled |
| Changing priors | <1 sec | No recompilation! |

### MCMC Sampling Time

| Configuration | Time | Cores Used |
|---------------|------|------------|
| 2000 iter, 1 chain | 30-60 sec | 1 |
| 2000 iter, 4 chains | 30-60 sec | 4 (parallel) |
| 4000 iter, 4 chains | 60-120 sec | 4 (parallel) |

**Note:** Local server can use multiple cores/chains simultaneously!

---

## Multi-User Behavior

### Scenario 1: Multiple Users, Same Session
- Each user gets their own R session
- All sessions share the compiled Stan model (in memory)
- No interference between users

### Scenario 2: Multiple Users, Different Priors
- User A: Uses fisher_z prior → Instant sampling
- User B: Uses uniform prior → Instant sampling
- Both use the same compiled model (priors passed as data)

### Scenario 3: Simultaneous MCMC Sampling
- Multiple users can run MCMC at the same time
- Each uses separate CPU cores
- May slow down if too many users (limited by total cores)

**Resource management:**
```r
# In global_local.R, cores are managed automatically:
total_cores <- parallel::detectCores()
mc_cores <- max(1, total_cores - 1)  # Leave 1 for system

# Example on 8-core laptop:
# - Reserves 7 cores for Stan
# - If 2 users sampling simultaneously, each gets ~3-4 cores
# - If 4 users, each gets ~1-2 cores
```

---

## Firewall / Network Configuration

### Allow Port 3838 (Shiny)

**Windows:**
```powershell
New-NetFirewallRule -DisplayName "Shiny Server" -Direction Inbound -LocalPort 3838 -Protocol TCP -Action Allow
```

**Mac:**
```bash
# System Preferences → Security & Privacy → Firewall → Firewall Options
# Add R and allow incoming connections
```

**Linux:**
```bash
sudo ufw allow 3838/tcp
```

### Allow Port 8787 (RStudio Server)

**Linux:**
```bash
sudo ufw allow 8787/tcp
```

---

## Troubleshooting

### Issue 1: "Stan model file not found"

**Symptom:**
```
✗ ERROR: Stan model file not found: stan_universal_model.stan
```

**Solution:**
Ensure `stan_universal_model.stan` is in the same directory as `global_local.R`

```r
# Check working directory
getwd()

# Should show the directory containing all files
list.files(pattern = "\\.stan$")
# Should show: stan_universal_model.stan
```

### Issue 2: "Universal Stan model not compiled"

**Symptom:**
```
ERROR: Universal Stan model not compiled!
Please restart the server to compile the model.
```

**Solution:**
Restart the Shiny app. The model compiles during startup in `global_local.R`.

### Issue 3: Team members can't connect

**Check 1: IP address**
```r
# On your laptop, verify IP
system("ipconfig")  # Windows
system("ifconfig")  # Mac/Linux
```

**Check 2: Port accessibility**
```bash
# Test if port 3838 is listening
netstat -an | grep 3838
```

**Check 3: Firewall**
Make sure firewall allows incoming connections on port 3838.

### Issue 4: Slow sampling with multiple users

**Symptom:** MCMC takes much longer when multiple users are running

**Solution:** Limit chains per user

```r
# In ui_local.R, change default chains:
numericInput("n_chains", "Number of Chains:", 
             value = 2,  # Reduced from 4
             min = 1, max = 4)
```

Or advise users to use fewer chains when server is busy.

---

## Security Considerations

### RStudio Server Approach (More Secure)
- ✅ User authentication required
- ✅ Each team member has separate account
- ✅ Audit trail of who ran what
- ✅ File permissions protect data

### Direct Shiny Approach (Less Secure)
- ⚠️ No authentication
- ⚠️ Anyone with URL can access
- ⚠️ No audit trail
- ⚠️ Only for trusted networks

**Recommendation:** Use RStudio Server for production team access.

---

## Advanced: Docker Deployment

If you want to deploy via Docker for easier team access:

1. **Create Dockerfile:**
```dockerfile
FROM rocker/shiny-verse:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libv8-dev \
    libnode-dev \
    clang

# Install R packages
RUN R -e "install.packages(c('rstan', 'bayesplot', 'DT', 'MASS'))"

# Copy app files
COPY stan_universal_model.stan /srv/shiny-server/
COPY global_local.R /srv/shiny-server/
COPY server_local.R /srv/shiny-server/
COPY ui_local.R /srv/shiny-server/
COPY app_local.R /srv/shiny-server/

# Expose port
EXPOSE 3838

# Run app
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/app_local.R', host='0.0.0.0', port=3838)"]
```

2. **Build and run:**
```bash
docker build -t bayesian-pos-local .
docker run -p 3838:3838 bayesian-pos-local
```

3. **Share:** Team accesses `http://YOUR_IP:3838`

---

## Best Practices

### For Server Admin (You)

1. **Keep server running:** Don't close RStudio while team is working
2. **Monitor resources:** Check CPU/memory usage with multiple users
3. **Regular restarts:** Restart server daily to clear memory
4. **Backup results:** Remind users to save their results locally

### For Team Members

1. **Save your work:** Download results before logging out
2. **Use reasonable settings:** Don't use 10,000 iterations unnecessarily
3. **Close when done:** Close browser tab when finished to free resources
4. **Report issues:** Let admin know if app is slow or errors occur

---

## File Structure Summary

```
your_project/
├── stan_universal_model.stan   <- Universal Stan model (compiled once)
├── global_local.R              <- Configuration & model compilation
├── server_local.R              <- Server logic with progress
├── ui_local.R                  <- User interface
├── app_local.R                 <- Main app file (combines above)
└── LOCAL_SERVER_GUIDE.md       <- This guide
```

---

## Comparison with Original Version

| Feature | Original | Local Server |
|---------|----------|--------------|
| Stan compilation | Every prior change | Once at startup |
| Prior changes | Rebuild + recompile (1-2 min) | Pass as data (<1 sec) |
| Progress display | No | Yes (withProgress) |
| Multi-user | Not optimized | Optimized |
| Cores used | 1 (cloud safety) | All available |
| Team access | Cloud deployment only | Local network |

---

## Next Steps

1. **Test locally first:**
   ```r
   source("app_local.R")
   shinyApp(ui, server)
   ```

2. **Verify Stan model compiles:**
   - Should see "✓ Universal Stan model compiled successfully!"
   - Takes 1-2 minutes on first run

3. **Test prior changes:**
   - Change from fisher_z to uniform prior
   - Should be instant (no compilation)

4. **Set up team access:**
   - Choose RStudio Server or direct Shiny approach
   - Configure firewall
   - Share credentials/URL

5. **Test with team:**
   - Have one team member connect
   - Run a model together
   - Verify progress shows correctly

---

## Support

If you encounter issues:

1. Check this guide's troubleshooting section
2. Verify all files are present and in correct locations
3. Check R console for error messages
4. Ensure Stan model compiled successfully on startup

For questions specific to your setup, consult with your IT team or system administrator.

---

**Enjoy fast, team-accessible Bayesian analysis!** 🚀
