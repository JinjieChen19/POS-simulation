# Quick Start: Local RStudio Server Version

## What's New in This Version?

This version is specifically designed for running on **your local laptop as a server** and sharing with your team. 

### Key Improvements:

1. ✅ **Compile Stan model ONCE** - happens at startup, not on every prior change
2. ✅ **Prior changes are instant** - no 1-2 minute wait for recompilation
3. ✅ **Real-time progress display** - users see MCMC sampling progress
4. ✅ **Team access ready** - optimized for multiple users on local network

---

## Files You Need

```
stan_universal_model.stan  <- Universal Stan model (flexible priors)
global_local.R             <- Configuration (compiles model once)
server_local.R             <- Server logic (with progress display)
ui_local.R                 <- User interface
app_local.R                <- Main app file
```

---

## How to Run

### Method 1: Quick Test (Local Only)

In RStudio console:

```r
shiny::runApp("app_local.R")
```

Access at: `http://localhost:3838`

### Method 2: Team Access (Recommended)

For team members to access from their computers:

```r
# Run with network access enabled
shiny::runApp("app_local.R", host = "0.0.0.0", port = 3838)
```

Then share with team:
- Find your IP: Run `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
- Share URL: `http://YOUR_IP:3838`
- Team members access via browser

---

## What Happens on Startup?

You'll see these messages (this is normal and expected):

```
=== Bayesian PoS Simulation - Local Server Version ===
Starting up...

Local server detected: 8 cores available
Using 7 cores for Stan sampling

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

=== Initialization Complete ===
```

**Important:** The 1-2 minute compilation happens ONCE. After this:
- All users share the compiled model
- Changing priors is instant (no recompilation!)
- Much faster for team usage

---

## How It's Different

### Traditional Approach (Original Version):

```
User selects priors → Build Stan code → Compile (1-2 min) → Sample
Every time you change priors: Wait 1-2 minutes
```

### New Approach (Local Server Version):

```
Server starts → Compile once (1-2 min) → Ready!

User selects priors → Pass as data → Sample (instant!)
Change priors: Instant! (no compilation)
```

---

## Example Usage Session

1. **Start the server:**
   ```r
   shiny::runApp("app_local.R", host = "0.0.0.0", port = 3838)
   ```

2. **Wait for compilation (first time only):**
   - Takes 1-2 minutes
   - See "✓ Universal Stan model compiled successfully!"

3. **Access the app:**
   - You: `http://localhost:3838`
   - Team: `http://YOUR_IP:3838`

4. **Change priors and run:**
   - Select "Fisher-z" prior → Click "Run Model" → See progress → Results
   - Change to "Uniform" prior → Click "Run Model" → **Instant!** → Results
   - No wait time when changing priors! 🚀

5. **Progress display:**
   - Users see: "MCMC Sampling in Progress..."
   - Progress bar shows stages
   - Real-time sampling iteration count
   - "✓ MCMC Sampling Complete!"

---

## Team Access Setup

### Option A: Direct Shiny Access (Easiest)

1. Run app with `host = "0.0.0.0"`
2. Find your laptop's IP address
3. Share URL with team: `http://YOUR_IP:3838`
4. Team members access via browser (no login required)

**Pros:** Easy setup, works immediately
**Cons:** No authentication, anyone with URL can access

### Option B: RStudio Server (More Secure)

1. Install RStudio Server on your laptop:
   ```bash
   # Linux
   sudo apt-get install rstudio-server
   
   # Start server
   sudo rstudio-server start
   ```

2. Create user accounts for team:
   ```bash
   sudo useradd -m teamuser1
   sudo passwd teamuser1
   ```

3. Share RStudio Server URL: `http://YOUR_IP:8787`

4. Team members:
   - Log in to RStudio Server
   - Open `app_local.R`
   - Click "Run App"

**Pros:** Secure, user authentication, audit trail
**Cons:** Requires RStudio Server setup

---

## Performance Expectations

### Compilation (One-Time):
- First startup: 1-2 minutes
- Subsequent sessions: <1 second (already compiled)

### MCMC Sampling:
- 2000 iterations, 1 chain: 30-60 seconds
- 2000 iterations, 4 chains: 30-60 seconds (parallel on local server)
- 4000 iterations, 4 chains: 60-120 seconds

### Prior Changes:
- Original version: 1-2 minutes (recompilation)
- Local version: <1 second (passed as data) ✅

---

## Troubleshooting

### "Stan model file not found"

**Solution:** Make sure `stan_universal_model.stan` is in the same directory as `app_local.R`

```r
getwd()  # Check working directory
list.files(pattern = "\\.stan$")  # Should show stan_universal_model.stan
```

### Team members can't connect

1. **Check firewall:**
   ```bash
   # Windows: Allow port 3838
   # Mac: System Preferences → Security → Firewall → Allow R
   # Linux: sudo ufw allow 3838/tcp
   ```

2. **Verify IP address:**
   ```r
   # Windows: ipconfig
   # Mac/Linux: ifconfig
   ```

3. **Test locally first:**
   ```r
   # On your laptop, access: http://localhost:3838
   # Should work before trying network access
   ```

### App is slow with multiple users

**Reduce chains per user:**

In `ui_local.R`, change default:
```r
numericInput("n_chains", "Number of Chains:", 
             value = 2,  # Reduced from 4
             min = 1, max = 4)
```

Or advise team to use fewer chains when server is busy.

---

## Complete Documentation

For comprehensive setup instructions, see:
- **LOCAL_SERVER_GUIDE.md** - Complete deployment guide
- **Comments in code** - Each file has detailed comments

---

## Summary

This local server version is perfect for:
- ✅ Small team collaboration (2-10 people)
- ✅ Rapid iteration with different priors
- ✅ Teaching/demos with live progress
- ✅ Secure local network access

**Key advantage:** No more waiting 1-2 minutes every time you change priors!

**Ready to run:** All files are complete and tested. Just run `app_local.R`!

---

**Questions?** See LOCAL_SERVER_GUIDE.md for detailed troubleshooting and advanced setup options.
