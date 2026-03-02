# File Location Guide - Pre-compilation Files

## ✅ Files Successfully Added

The following files for Stan model pre-compilation were successfully added in **commit 0ca7ab6**:

### 1. `precompile_model.R` (2.1 KB)
**Location:** Root directory  
**Purpose:** Pre-compiles the DEFAULT Stan model configuration  
**Status:** ✅ Present and committed

**To verify:**
```bash
ls -lh precompile_model.R
# Output: -rw-rw-r-- 1 runner runner 2.1K Feb 15 03:11 precompile_model.R
```

**Contents preview:**
```r
# Pre-compile DEFAULT Stan model for faster app startup
library(rstan)
source("global.R")

default_stan_code <- build_stan_model_improved(
  prior_rho_type = "fisher_z",
  prior_tau_type = "exponential",
  ...
)

model_compiled <- stan_model(model_code = default_stan_code)
saveRDS(model_compiled, "bayesian_pos_model.rds")
```

### 2. `PRECOMPILE_README.md` (3.4 KB)
**Location:** Root directory  
**Purpose:** Complete documentation for pre-compilation workflow  
**Status:** ✅ Present and committed

## How to Access

### Option 1: Via GitHub Web Interface
1. Go to: https://github.com/JinjieChen19/POS-simulation
2. Switch to branch: `copilot/create-r-shiny-app-bayesian-pos`
3. Files are in the **root directory**

### Option 2: Via Git Command Line
```bash
# Pull latest changes
git fetch origin
git checkout copilot/create-r-shiny-app-bayesian-pos
git pull

# Verify files
ls -lh precompile_model.R PRECOMPILE_README.md
```

### Option 3: Direct GitHub Links
- **precompile_model.R**: `blob/copilot/create-r-shiny-app-bayesian-pos/precompile_model.R`
- **PRECOMPILE_README.md**: `blob/copilot/create-r-shiny-app-bayesian-pos/PRECOMPILE_README.md`

## Usage

Once you have the files:

```bash
# 1. Pre-compile the model (one-time, takes 1-2 minutes)
R -e "source('precompile_model.R')"

# 2. Run the app (will auto-load pre-compiled model)
R -e "shiny::runApp()"
```

## Troubleshooting

**"I don't see the file"**
- Ensure you're on the `copilot/create-r-shiny-app-bayesian-pos` branch
- Try refreshing your browser (Ctrl+F5 / Cmd+Shift+R)
- Pull latest changes: `git pull origin copilot/create-r-shiny-app-bayesian-pos`

**Git verification:**
```bash
# Check if file is tracked
git ls-files | grep precompile
# Output: precompile_model.R

# Show file from latest commit
git show HEAD:precompile_model.R | head -20
```

## Files Added in Commit 0ca7ab6

```
PRECOMPILE_README.md
global.R (modified)
precompile_model.R
server.R (modified)
ui.R (modified)
ui.R.backup
```

All files are successfully committed and pushed to the repository.
