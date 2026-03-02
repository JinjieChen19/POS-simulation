# Quick Reference Card - POSsimulation Package

## For You (Package Creator)

### Testing the Package Locally

```r
# Load package for testing (from package directory)
devtools::load_all()

# Test each version
run_pos_app()
run_pos_app_local()
run_pos_app_authenticated()

# Check package structure
devtools::check()
```

### Updating the Package

```bash
# 1. Make your changes to files in R/ or inst/
# 2. Update version in DESCRIPTION if needed
# 3. Commit and push
git add .
git commit -m "Your update message"
git push origin create-r-package  # or main after merge
```

---

## For Your Coworkers

### First Time Setup (5-10 minutes)

```r
# 1. Install devtools
install.packages("devtools")

# 2. Install POSsimulation
devtools::install_github("JinjieChen19/POS-simulation")
```

### Every Time Use (Instant!)

```r
library(POSsimulation)
run_pos_app()  # Opens in browser
```

### Update to Latest Version

```r
devtools::install_github("JinjieChen19/POS-simulation")
```

---

## Three App Versions

### 1. Standard (Full Features)
```r
run_pos_app()
```
- Complete documentation
- Help and Model Description tabs
- Best for learning

### 2. Local Server (Team Optimized)
```r
run_pos_app_local()
```
- Compiles Stan model once
- Prior changes instant
- Real-time progress
- Perfect for team access

### 3. Authenticated (Secure)
```r
run_pos_app_authenticated()
```
- Username/password required
- Remote access ready
- Default: admin / Change_This_Password_123!

---

## Common Issues & Solutions

### Issue: "Could not find function 'run_pos_app'"
```r
# Solution: Load library first
library(POSsimulation)
run_pos_app()
```

### Issue: Stan compilation errors
```r
# Solution: Install rstan separately
install.packages("rstan", repos = "https://cloud.r-project.org/")
devtools::install_github("JinjieChen19/POS-simulation")
```

### Issue: No C++ compiler
**Windows:**
```r
install.packages("installr")
installr::install.Rtools()
```

**Mac:**
```bash
xcode-select --install
```

---

## Getting Help

```r
# Function help
?run_pos_app

# Package help
help(package = "POSsimulation")

# In-app help
run_pos_app()  # Click Help tab
```

---

## Sharing with New Coworkers

Send them this:

```
To install the Bayesian PoS Simulation app:

1. Install devtools:
   install.packages("devtools")

2. Install POSsimulation:
   devtools::install_github("JinjieChen19/POS-simulation")

3. Run the app:
   library(POSsimulation)
   run_pos_app()

First install takes 5-10 minutes.
After that, it's instant!

For help: See PACKAGE_INSTALLATION_GUIDE.md
```

---

## What Gets Installed

- The app itself (all three versions)
- All required packages (shiny, rstan, etc.)
- Stan models (pre-compiled)
- Documentation and help files

**Total size:** ~100-200 MB (first time)

**Updates:** Much faster (~1 minute)

---

## Summary

**To install:**
```r
devtools::install_github("JinjieChen19/POS-simulation")
```

**To run:**
```r
library(POSsimulation)
run_pos_app()
```

**To update:**
```r
devtools::install_github("JinjieChen19/POS-simulation")
```

**Simple!** 🚀
