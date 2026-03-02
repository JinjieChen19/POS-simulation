# Local Server Implementation - Complete Index

## Quick Navigation

Looking for information? Start here:

### 🚀 Want to Get Started Quickly?
→ Read **[QUICK_START_LOCAL.md](QUICK_START_LOCAL.md)** (5-minute guide)

### 📚 Need Complete Setup Instructions?
→ Read **[LOCAL_SERVER_GUIDE.md](LOCAL_SERVER_GUIDE.md)** (comprehensive guide)

### 📊 Want to Understand What Was Built?
→ Read **[LOCAL_SERVER_SUMMARY.md](LOCAL_SERVER_SUMMARY.md)** (implementation overview)

### 💻 Ready to Run the App?
→ Use **[app_local.R](app_local.R)** (main application file)

---

## File Purpose Guide

### Core Application Files (Use These):

| File | Purpose | Size | When to Use |
|------|---------|------|-------------|
| `app_local.R` | Main app file | 3.0 KB | **Run this to start the app** |
| `global_local.R` | Configuration & Stan compilation | 9.6 KB | Sources automatically |
| `server_local.R` | Server logic with progress | 14.8 KB | Sources automatically |
| `ui_local.R` | User interface | Same as ui.R | Sources automatically |
| `stan_universal_model.stan` | Universal Stan model | 6.0 KB | Compiles automatically |

### Documentation Files (Read These):

| File | Content | Size | For Whom |
|------|---------|------|----------|
| `QUICK_START_LOCAL.md` | Quick start guide | 6.4 KB | **Start here!** Everyone |
| `LOCAL_SERVER_GUIDE.md` | Complete deployment guide | 11.8 KB | Server admins, detailed setup |
| `LOCAL_SERVER_SUMMARY.md` | Implementation overview | 9.8 KB | Technical understanding |
| `LOCAL_SERVER_INDEX.md` | This file | - | Navigation |

---

## What's Different from Original?

### Original Version Files:
- `app.R` or `ui.R` + `server.R` + `global.R`
- Recompiles Stan model on every prior change (1-2 min wait)
- No progress display

### Local Server Version Files:
- `app_local.R` + `ui_local.R` + `server_local.R` + `global_local.R` + `stan_universal_model.stan`
- Compiles Stan model ONCE at startup
- Prior changes are instant (<1 sec)
- Full progress display during MCMC

**Use local server version when:** Running on your laptop for team access

---

## Quick Reference: How to Run

### For Local Testing:
```r
shiny::runApp("app_local.R")
```
Access at: http://localhost:3838

### For Team Access:
```r
shiny::runApp("app_local.R", host = "0.0.0.0", port = 3838)
```
Then share: http://YOUR_IP:3838 with team

---

## Key Features

### ✅ What You Get:

1. **Single Stan Compilation**
   - Compiles once at startup (1-2 min)
   - All users share compiled model
   - No recompilation when changing priors!

2. **Instant Prior Changes**
   - Was: 1-2 minutes per change
   - Now: <1 second per change
   - **Time saved:** 10-20 min/day for active users

3. **Real-Time Progress**
   - Progress bar shows stages
   - Real-time MCMC iteration count
   - Estimated time remaining

4. **Team Access**
   - Multiple users simultaneously
   - Each has separate session
   - Share via network URL

5. **Multi-Core Support**
   - Uses all available cores
   - Automatic detection
   - Parallel chain sampling

---

## Documentation Structure

```
QUICK_START_LOCAL.md        ← Start here (5 min read)
    ↓
Understand basics, run app locally
    ↓
LOCAL_SERVER_GUIDE.md        ← Read for team setup (20 min read)
    ↓
Set up team access, configure firewall
    ↓
LOCAL_SERVER_SUMMARY.md      ← Read for technical details (10 min read)
    ↓
Understand implementation, performance metrics
```

---

## Common Tasks

### Task: Run app for first time
**Steps:**
1. Read QUICK_START_LOCAL.md
2. Run: `shiny::runApp("app_local.R")`
3. Wait for compilation (1-2 min)
4. Use the app!

### Task: Share with team
**Steps:**
1. Read LOCAL_SERVER_GUIDE.md section "Team Access Setup"
2. Choose deployment method (Shiny or RStudio Server)
3. Configure firewall (port 3838 or 8787)
4. Share URL with team

### Task: Troubleshoot issues
**Steps:**
1. Check QUICK_START_LOCAL.md "Troubleshooting" section
2. Check LOCAL_SERVER_GUIDE.md "Troubleshooting" section
3. Verify all files are present
4. Check R console for errors

### Task: Understand performance
**Steps:**
1. Read LOCAL_SERVER_SUMMARY.md "Performance Metrics"
2. See time savings estimates
3. Compare with original version

---

## File Dependencies

```
app_local.R
    ↓ sources
global_local.R
    ↓ compiles
stan_universal_model.stan
    ↓ creates
UNIVERSAL_STAN_MODEL (global variable)
    ↓ used by
server_local.R
    ↓ with
ui_local.R
    ↓ creates
Shiny App (running)
```

**Important:** All files must be in the same directory!

---

## Technical Specifications

### Stan Model:
- **Type:** Universal model
- **Priors:** Accepts as data parameters
- **ρ prior types:** 5 (fisher_z, uniform, uniform_pos, beta, lkj)
- **τ prior types:** 3 (exponential, half_normal, uniform)
- **Compilation:** Once at startup

### Performance:
- **Startup:** 2-3 min (first time only)
- **Prior change:** <1 sec (was 1-2 min)
- **MCMC (2000 iter, 4 chains):** 30-60 sec
- **Cores used:** All available

### Requirements:
- R 4.0+
- rstan package
- shiny, tidyverse, bayesplot, DT
- 8+ GB RAM recommended
- Multi-core CPU recommended

---

## Support Matrix

| Question | Documentation | Section |
|----------|---------------|---------|
| How do I start? | QUICK_START_LOCAL.md | "How to Run" |
| How do I share with team? | LOCAL_SERVER_GUIDE.md | "Team Access Setup" |
| Why is it faster? | LOCAL_SERVER_SUMMARY.md | "Key Technical Innovations" |
| What changed from original? | LOCAL_SERVER_SUMMARY.md | "What's Different" |
| How do I troubleshoot? | Both guides | "Troubleshooting" |
| How does Stan model work? | LOCAL_SERVER_SUMMARY.md | "Universal Stan Model" |
| What are performance gains? | LOCAL_SERVER_SUMMARY.md | "Performance Metrics" |
| How do I configure firewall? | LOCAL_SERVER_GUIDE.md | "Firewall / Network Config" |

---

## Version Comparison

| Feature | Original | Fly.io | Local Server |
|---------|----------|--------|--------------|
| Target | Cloud | Cloud containers | Local laptop |
| Stan compilation | Every prior change | Once at startup | Once at startup |
| Prior changes | 1-2 min | <1 sec | <1 sec |
| Progress display | None | Yes | Yes |
| Multi-user | Not optimized | Single user | Optimized |
| Team access | Via cloud | Via cloud | Via local network |
| Cores used | 1 | 1 | All available |
| Best for | General use | Cloud deploy | Team collaboration |

**Use local server version when:**
- Running on your laptop
- Team needs access
- Want fastest iteration
- Need to try many different priors
- Want instant feedback

---

## Success Metrics

After implementing local server version, you should see:

✅ **Compilation:** Happens once at startup (1-2 min)
✅ **Prior changes:** Instant (<1 sec, no waiting!)
✅ **Progress:** Real-time display during MCMC
✅ **Team access:** Multiple users can connect
✅ **Time saved:** 10-20 minutes per day for active users

---

## Next Steps

1. **Now:** Read QUICK_START_LOCAL.md
2. **Next:** Run app locally to test
3. **Then:** Set up team access (if needed)
4. **Finally:** Use in production for PoS analyses

---

## Quick Commands Reference

```r
# Test locally
shiny::runApp("app_local.R")

# Enable team access
shiny::runApp("app_local.R", host = "0.0.0.0", port = 3838)

# Check files present
list.files(pattern = "local")

# Verify Stan file
list.files(pattern = "\\.stan$")

# Find your IP (Windows)
system("ipconfig")

# Find your IP (Mac/Linux)
system("ifconfig")
```

---

## Summary

**You have everything you need to run a fast, team-accessible Bayesian PoS simulation app on your local laptop!**

- **7 application files** (complete implementation)
- **4 documentation files** (28 KB guides)
- **Instant prior changes** (no recompilation!)
- **Real-time progress** (during MCMC)
- **Team access** (multiple methods)

**Start with:** QUICK_START_LOCAL.md → Run app_local.R → Share with team!

---

**All files ready for immediate use!** 🚀
