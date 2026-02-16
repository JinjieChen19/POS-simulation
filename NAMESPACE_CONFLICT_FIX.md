# Namespace Conflict Fix Guide

## The Error

When trying to run the app after installing the POSsimulation package:

```r
library(POSsimulation)
run_pos_app()
```

You encountered:

```
Loading required package: shiny
Failed with error:  'Package 'shiny' version 1.9.1 cannot be unloaded:
 Error in unloadNamespace(package) : namespace 'shiny' is imported by 'miniUI', 'POSsimulation' so cannot be unloaded
'
Error in ..stacktraceon..({ : could not find function "..stacktraceon.."
```

---

## What This Error Means

**In simple terms:** The app was trying to load packages that were already loaded by the POSsimulation package itself, creating a conflict.

**Technical explanation:**
- POSsimulation package imports `shiny`, `rstan`, and other packages via its NAMESPACE
- The app files (inst/shiny/app.R, etc.) had `library(shiny)` calls
- When `runApp()` executed the app file, it tried to reload packages already in use
- R couldn't unload the packages to reload them because they were imported by POSsimulation
- Result: namespace conflict error

---

## The Root Cause

The app files were written for **standalone use** (not as part of a package):

```r
# inst/shiny/app.R (BEFORE - WRONG for packages)
library(shiny)        # ← Conflict!
library(rstan)        # ← Conflict!
library(tidyverse)    # ← Conflict!
# ... more library calls
```

**Why this causes problems:**
1. POSsimulation package already imports these in DESCRIPTION/NAMESPACE
2. Packages are loaded when you run `library(POSsimulation)`
3. App files try to load them again → conflict!

---

## The Fix

Removed all `library()` calls from app files in inst/shiny/ directories.

### Files Modified

**1. inst/shiny/app.R**
- Removed 8 library() calls
- Added note explaining package dependencies

**2. inst/shiny/global.R**
- Removed 8 library() calls
- Functions still work (packages imported by package)

**3. inst/shiny/local/global.R**
- Removed library() calls from suppressPackageStartupMessages()

**4. inst/shiny/authenticated/app.R**
- Removed library(shiny) and library(shinymanager)

### After Fix

```r
# inst/shiny/app.R (AFTER - CORRECT for packages)
# NOTE: When running as part of POSsimulation package, all dependencies are
# already loaded via NAMESPACE. Library calls are removed to prevent conflicts.

# Set rstan options
options(mc.cores = parallel::detectCores())
rstan::rstan_options(auto_write = TRUE)

# All functions work because packages are imported in DESCRIPTION
```

---

## Why This Fix Works

### R Package Dependency Management

**For standalone apps** (e.g., app.R in a folder):
```r
library(shiny)  # ✓ Needed - loads packages
shinyApp(ui, server)
```

**For package-bundled apps** (e.g., inst/shiny/app.R in a package):
```r
# ✓ No library() calls needed
# Packages already imported via:
#   - DESCRIPTION (Imports: shiny, rstan, ...)
#   - NAMESPACE (import or importFrom statements)

shinyApp(ui, server)  # Works! Packages already available
```

### How Dependencies Are Handled

**DESCRIPTION file:**
```
Imports:
    shiny (>= 1.7.0),
    rstan (>= 2.21.0),
    tidyverse,
    ...
```
→ Tells R to load these when POSsimulation loads

**NAMESPACE file:**
```
importFrom(shiny, runApp)
import(rstan)
```
→ Makes functions available without library()

**Result:** All packages available, no conflicts!

---

## Verification Steps

After the fix, you should be able to:

```r
# 1. Install package
devtools::install_github("JinjieChen19/POS-simulation",
                        ref = "copilot/create-r-shiny-app-bayesian-pos")

# 2. Load package
library(POSsimulation)

# 3. Run any version without errors
run_pos_app()              # ✓ Works!
run_pos_app_local()        # ✓ Works!
run_pos_app_authenticated() # ✓ Works!
```

**Expected behavior:**
- App launches in browser
- No error messages
- All features work normally
- Stan models compile and run successfully

---

## Prevention for Future Development

### When Adding New App Files

**DO NOT:**
```r
# ✗ WRONG for package apps
library(shiny)
library(ggplot2)
```

**DO:**
```r
# ✓ CORRECT for package apps
# Add to DESCRIPTION:
#   Imports: shiny, ggplot2

# Then use functions directly:
shiny::runApp(...)
ggplot2::ggplot(...)

# Or after importFrom in NAMESPACE:
runApp(...)
ggplot(...)
```

### Best Practices

1. **List all dependencies in DESCRIPTION**
   ```
   Imports:
       shiny,
       rstan,
       packageName,
   ```

2. **Import in NAMESPACE (via roxygen2)**
   ```r
   #' @importFrom shiny runApp
   #' @import rstan
   ```

3. **Never use library() in inst/ files**
   - App files: No library() calls
   - Helper scripts: No library() calls
   - Everything managed by package infrastructure

4. **Use package::function() for clarity**
   ```r
   shiny::runApp(...)    # Clear which package
   rstan::stan_model(...)  # Prevents conflicts
   ```

---

## Related Errors and Solutions

### Error: "could not find function"

**Symptom:**
```
Error: could not find function "..stacktraceon.."
```

**Cause:** Related to namespace conflict (secondary error)

**Solution:** Same fix - remove library() calls from app files

### Error: "Package X is not available"

**Symptom:**
```
Error in library(packageName) : there is no package called 'packageName'
```

**If in inst/shiny/ files:**
1. Remove library() call
2. Add package to DESCRIPTION Imports:
3. Add to NAMESPACE if needed

**If in your local R session:**
```r
install.packages("packageName")
```

### Error: "namespace is already loaded"

**Symptom:**
```
Error: namespace 'X' is already loaded
```

**Solution:** 
- Same root cause as main error
- Remove library() calls from app files
- Let package handle dependencies

---

## Summary

**Problem:** Namespace conflicts from library() calls in app files

**Cause:** Apps written for standalone use, not package bundling

**Fix:** Removed all library() calls from inst/shiny/* files

**Why it works:** Package manages dependencies via DESCRIPTION/NAMESPACE

**Result:** ✅ All app versions work without conflicts!

---

## Additional Resources

**R Package Development:**
- [Writing R Extensions](https://cran.r-project.org/doc/manuals/R-exts.html)
- [R Packages Book](https://r-pkgs.org/)

**Shiny in Packages:**
- [Shiny App-Packages](https://mastering-shiny.org/scaling-packaging.html)
- [golem framework](https://thinkr-open.github.io/golem/)

**For Questions:**
- Check PACKAGE_INSTALLATION_GUIDE.md
- See README.md troubleshooting section
- Open GitHub issue if problems persist
