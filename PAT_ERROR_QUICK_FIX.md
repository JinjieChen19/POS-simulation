# Quick Fix: 401 Authentication Error

## The Error You're Seeing

```
Using github PAT from envvar GITHUB_PAT
Error: Failed to install 'unknown package' from GitHub:
  HTTP error 401.
  Bad credentials
```

## Fastest Solution (30 seconds)

### Try This First:

```r
# Clear any existing PAT
Sys.unsetenv("GITHUB_PAT")

# Install without authentication
devtools::install_github("JinjieChen19/POS-simulation")
```

✅ **This works if the repository is public** (most common case)

---

## If That Didn't Work

The repository might be **private**. You need a GitHub Personal Access Token (PAT).

### Quick PAT Setup (5 minutes):

**1. Create PAT on GitHub:**
- Go to: https://github.com/settings/tokens
- Click "Generate new token (classic)"
- Select scope: ✅ **repo**
- Copy the token (starts with `ghp_...`)

**2. Configure in R:**
```r
# Install gitcreds if needed
install.packages("gitcreds")

# Set your PAT (paste when prompted)
gitcreds::gitcreds_set()
```

**3. Install package:**
```r
devtools::install_github("JinjieChen19/POS-simulation")
```

---

## Still Not Working?

See the complete guide: **GITHUB_PAT_FIX.md**

It covers:
- Multiple authentication methods
- Troubleshooting persistent issues
- Alternative installation methods
- Manual installation from ZIP

---

## Summary

**90% of cases:** Repository is public, just clear PAT and install
```r
Sys.unsetenv("GITHUB_PAT")
devtools::install_github("JinjieChen19/POS-simulation")
```

**10% of cases:** Repository is private, need valid PAT with repo scope

**Having trouble?** Read GITHUB_PAT_FIX.md for detailed help.
