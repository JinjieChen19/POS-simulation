# Testing Guide for POSsimulation Package

## Purpose

This guide explains how to test the POSsimulation package to ensure quality before distribution to users.

## Why Testing Matters

The package encountered several issues that testing would have caught:
1. ✗ Namespace conflicts from library() calls
2. ✗ UI syntax errors (parse failures)
3. ✗ Installation issues (404, 401 errors)
4. ✗ Build problems

**These testing tools prevent such issues from reaching users.**

---

## Testing Tools

### 1. Package Validation (`tests/validate_package.R`)

**What it checks:**
- Package structure (required directories and files)
- DESCRIPTION and NAMESPACE file validity
- No library() calls in inst/ files (prevents namespace conflicts)
- R syntax in all .R files (catches parse errors)
- Stan model file existence
- Common anti-patterns

**How to run:**
```r
source("tests/validate_package.R")
validate_package()
```

**Expected output:**
```
=== Package Validation ===

Checking package structure...
  ✓ Directory R exists
  ✓ Directory inst exists
  ✓ File DESCRIPTION exists
  ✓ File NAMESPACE exists

Validating DESCRIPTION file...
  ✓ DESCRIPTION file is valid

Checking for library() calls in inst/ files...
  ✓ No library() calls in inst/ files

Validating R syntax in all .R files...
  ✓ All R files have valid syntax

Checking for Stan model files...
  ✓ Found 2 Stan model file(s)

==========================================
All checks passed! ✓
Package is ready for distribution.
==========================================
```

### 2. Installation Testing (`tests/test_installation.R`)

**What it checks:**
- Package can be loaded
- All required functions exist
- Dependencies are available

**How to run:**
```r
# First install the package
devtools::install()

# Then test it
source("tests/test_installation.R")
test_installation()
```

### 3. Package Check (`tests/run_package_check.R`)

**What it checks:**
- Runs R CMD check
- Validates documentation
- Checks for build errors

**How to run:**
```r
source("tests/run_package_check.R")
run_package_check()
```

---

## Complete Testing Workflow

### Before Any Commit

```r
# Step 1: Validate package structure
source("tests/validate_package.R")
result <- validate_package()

# Step 2: If validation passes, check package
if (result$all_passed) {
  source("tests/run_package_check.R")
  run_package_check()
}
```

### Before Sharing with Users

```r
# Step 1: Run all validation
source("tests/validate_package.R")
validate_package()

# Step 2: Run package check
source("tests/run_package_check.R")
run_package_check()

# Step 3: Install and test
devtools::install()
source("tests/test_installation.R")
test_installation()

# Step 4: Test each app version manually
library(POSsimulation)
run_pos_app()              # Test standard version
run_pos_app_local()        # Test local server version
run_pos_app_authenticated() # Test authenticated version

# Step 5: Review PRE_DEPLOYMENT_CHECKLIST.md
```

---

## Interpreting Results

### Validation Script

**✓ PASS** - Check succeeded, no issues
**✗ FAIL** - Critical issue, must fix before sharing
**⚠ WARN** - Warning, review but may not block

**Common failures and fixes:**

**"Found library() calls in inst/ files"**
- Remove library() calls from app files
- Dependencies handled by DESCRIPTION/NAMESPACE

**"Syntax errors found"**
- Run parse(file) on the specific file to see error
- Fix syntax issues (unbalanced parentheses, incomplete expressions)

**"Missing directory: inst"**
- Create required directory structure
- Ensure package follows standard R package format

### Package Check

**Errors** - Must fix before distribution
**Warnings** - Should fix, may block some installations
**Notes** - Informational, usually OK

---

## Adding New Tests

To add a new validation check to `validate_package.R`:

```r
# Add to validate_package() function:

# X. Check for [your requirement]
if (verbose) cat("\nChecking for [requirement]...\n")
# ... your check logic ...
if (check_passes) {
  results$your_check <- "PASS"
  if (verbose) cat("  ✓ Check passed\n")
} else {
  results$your_check <- "FAIL: Description of failure"
  all_passed <- FALSE
  if (verbose) cat("  ✗ Check failed\n")
}
```

---

## CI/CD Integration (Optional)

For automated testing on every commit, add GitHub Actions:

```yaml
# .github/workflows/r-check.yml
name: R Package Check

on: [push, pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: r-lib/actions/setup-r@v2
      - name: Install dependencies
        run: |
          install.packages(c("devtools", "testthat"))
        shell: Rscript {0}
      - name: Validate package
        run: Rscript tests/validate_package.R
      - name: Check package
        run: Rscript tests/run_package_check.R
```

---

## Troubleshooting

**"devtools not available"**
```r
install.packages("devtools")
```

**"Package check takes too long"**
- Use `manual = FALSE, vignettes = FALSE` options
- Focus on validation script for quick checks

**"Tests pass but app still has issues"**
- Test manually with each app version
- Check GitHub branch status (on main vs other branch)
- Verify all files are committed

---

## Summary

**Quick check (1 minute):**
```r
source("tests/validate_package.R")
validate_package()
```

**Full check (5-10 minutes):**
```r
source("tests/validate_package.R"); validate_package()
source("tests/run_package_check.R"); run_package_check()
devtools::install()
source("tests/test_installation.R"); test_installation()
```

**Before sharing with users:**
- Follow PRE_DEPLOYMENT_CHECKLIST.md
- Test all three app versions manually
- Verify installation command works

**Result:** Confident, quality package distribution! ✓
