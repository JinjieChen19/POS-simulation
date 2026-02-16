# Fix: GitHub PAT Authentication Error (401)

## The Error

```
Using github PAT from envvar GITHUB_PAT
Error: Failed to install 'unknown package' from GitHub:
  HTTP error 401.
  Bad credentials
```

## What This Means

- **401 Error** = Authentication problem
- GitHub can't verify your identity
- Either the PAT is invalid or not configured correctly

---

## Quick Fixes (Try in Order)

### Option 1: Install Without Authentication (Public Repo)

If the repository is **public**, you don't need a PAT at all!

```r
# Clear any existing PAT
Sys.unsetenv("GITHUB_PAT")

# Install without authentication
devtools::install_github("JinjieChen19/POS-simulation")
```

✅ **This should work if the repository is public**

---

### Option 2: Generate a New GitHub PAT

If the repository is **private** or you need a PAT:

#### Step 1: Create a New PAT on GitHub

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Give it a name: "R Package Installation"
4. **Select scopes:**
   - ✅ **repo** (Full control of private repositories)
   - ✅ **read:packages** (optional, for GitHub Packages)
5. Set expiration (90 days or custom)
6. Click "Generate token"
7. **COPY THE TOKEN** (you won't see it again!)

Example token: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

#### Step 2: Configure the PAT in R

**Method A: Using gitcreds (Recommended)**

```r
# Install gitcreds if needed
install.packages("gitcreds")

# Set the PAT (will prompt you to paste it)
gitcreds::gitcreds_set()
# Paste your token when prompted
```

**Method B: Using .Renviron file**

```r
# Edit your .Renviron file
usethis::edit_r_environ()

# Add this line (replace with YOUR token):
GITHUB_PAT=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Save and restart R
# Session → Restart R (in RStudio)
```

**Method C: Set temporarily for this session**

```r
# Set the PAT for current session only
Sys.setenv(GITHUB_PAT = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
```

#### Step 3: Verify It Works

```r
# Check if PAT is set
Sys.getenv("GITHUB_PAT")
# Should show your token (or part of it)

# Test installation
devtools::install_github("JinjieChen19/POS-simulation")
```

---

### Option 3: Use Auth Token Directly

```r
# Install with explicit auth
devtools::install_github(
  "JinjieChen19/POS-simulation",
  auth_token = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
)
```

---

## Troubleshooting

### Problem: Token Still Doesn't Work

**Check token scopes:**
1. Go to https://github.com/settings/tokens
2. Click on your token
3. Verify **repo** scope is checked
4. Regenerate if needed

### Problem: "Bad credentials" persists

**Clear and reset:**
```r
# Remove old PAT
Sys.unsetenv("GITHUB_PAT")

# Remove cached credentials
gitcreds::gitcreds_delete()

# Set new PAT
gitcreds::gitcreds_set()
```

### Problem: Repository is private and you don't have access

**Contact repository owner:**
- Ask JinjieChen19 to:
  1. Make the repository public, OR
  2. Add you as a collaborator

### Problem: Corporate firewall blocking GitHub

**Try HTTPS instead of SSH:**
```r
options(download.file.method = "libcurl")
devtools::install_github("JinjieChen19/POS-simulation")
```

---

## Best Practices

### For Public Repository (Recommended)

Make the repository public so coworkers can install without PAT:

1. Go to repository settings
2. Scroll to "Danger Zone"
3. Click "Change visibility" → "Make public"

**Benefits:**
- ✅ No authentication needed
- ✅ Easier for everyone
- ✅ Standard for open-source packages

### For Private Repository

If it must stay private:

1. **Each coworker needs:**
   - GitHub account
   - Access to repository (added as collaborator)
   - Valid PAT with repo scope

2. **Share these instructions:**
   - How to create PAT (see Step 1 above)
   - How to configure it (see Step 2 above)

---

## Verification Checklist

After fixing, verify:

- [ ] PAT is set correctly (`Sys.getenv("GITHUB_PAT")` shows token)
- [ ] Token has **repo** scope
- [ ] Token hasn't expired
- [ ] Repository is accessible (public or you have access)
- [ ] Installation command works

```r
# Should work without errors:
devtools::install_github("JinjieChen19/POS-simulation")
```

---

## Alternative: Manual Installation

If GitHub authentication is too complex:

### Method 1: Download and Install Locally

```r
# 1. Download repository as ZIP from GitHub
# 2. Extract to a folder
# 3. Install from local path:
devtools::install("/path/to/POS-simulation")
```

### Method 2: Share as Built Package

**For package creator:**
```r
# Build the package
devtools::build()
# Creates: POSsimulation_1.0.0.tar.gz
# Share this file with coworkers
```

**For coworkers:**
```r
# Install from downloaded file
install.packages("/path/to/POSsimulation_1.0.0.tar.gz", repos = NULL)
```

---

## Summary

**Quick Fix (if repo is public):**
```r
Sys.unsetenv("GITHUB_PAT")
devtools::install_github("JinjieChen19/POS-simulation")
```

**Full Fix (if repo is private):**
1. Generate new PAT with repo scope
2. Configure with `gitcreds::gitcreds_set()`
3. Install package

**Easiest Solution:**
Make repository public (no authentication needed)

---

**Need more help?** Check GitHub's authentication docs:
https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token
