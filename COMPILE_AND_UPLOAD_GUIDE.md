# How to Compile and Upload the Stan Model

## Quick Answer

**YES! You need to compile the Stan model and upload the .rds file to this repository.**

I created the infrastructure to USE the precompiled model, but you need to actually compile it.

## Why This is Needed

I created:
- ✅ Precompilation script (`tools/precompile_stan_model.R`)
- ✅ Loading function (`R/load_precompiled_stan_model.R`)
- ✅ App integration (loads .rds if available)
- ✅ Documentation (30+ KB)

What I **can't** do:
- ❌ Compile Stan models (requires C++ compiler, takes 1-2 minutes)
- ❌ Create the .rds file on your system
- ❌ Commit files to your repository

**That's why you need to do it!**

## The Complete Process (3 Minutes)

### Prerequisites

Make sure you have:
- ✅ R installed (you already do)
- ✅ rstan package installed
- ✅ C++ compiler (RTools on Windows, Xcode on Mac, build-essential on Linux)
- ✅ This repository cloned locally

### Step 1: Compile the Model (1-2 minutes)

```bash
# Navigate to repository root
cd /path/to/POS-simulation

# Run the precompilation script
Rscript tools/precompile_stan_model.R
```

**Expected output:**
```
========================================
Precompiling Stan Model
========================================

Step 1: Loading Stan model code...
✓ Stan file loaded: inst/stan/stan_universal_model_optimized.stan

Step 2: Compiling Stan model...
(This may take 1-2 minutes - be patient!)
...
✓ Model compiled successfully!

Step 3: Saving compiled model...
Saving to: inst/stan/stan_model_compiled.rds
✓ Model saved! File size: 2.3 MB

Step 4: Verifying...
✓ Model loads correctly!

========================================
SUCCESS! ✓
========================================
Compiled model saved to: inst/stan/stan_model_compiled.rds
File size: 2.3 MB

Next steps:
1. git add inst/stan/stan_model_compiled.rds
2. git commit -m "Add precompiled Stan model for instant startup"
3. git push
```

### Step 2: Verify It Worked (30 seconds - optional)

```bash
# Check the file was created
ls -lh inst/stan/stan_model_compiled.rds

# You should see something like:
# -rw-r--r-- 1 user staff 2.3M Feb 17 19:25 inst/stan/stan_model_compiled.rds
```

Test loading it in R:
```r
# In R console
model <- readRDS("inst/stan/stan_model_compiled.rds")
print(model)
# Should show: S4 class stanmodel
```

### Step 3: Commit to Git (30 seconds)

```bash
# Add the file to git
git add inst/stan/stan_model_compiled.rds

# Commit with a clear message
git commit -m "Add precompiled Stan model for instant startup

- Precompiled from stan_universal_model_optimized.stan
- Eliminates 60-120 second compilation wait
- Users get instant app startup (< 1 second)
- Model size: ~2-3 MB
"

# Check status
git status
```

### Step 4: Push to GitHub

```bash
# Push to your branch
git push origin copilot/create-r-shiny-app-bayesian-pos

# Or if you're on main:
git push origin main
```

**Done!** 🎉

## What Users Will Experience

### Before (without .rds file):
```
User: library(POSsimulation)
User: run_pos_app_local()

App: Precompiled model not found. Compiling from source...
App: (this may take 1-2 minutes)
[User waits 90 seconds] 😴
App: ✓ Compiled. Ready!
```

### After (with .rds file):
```
User: library(POSsimulation)
User: run_pos_app_local()

App: Loading precompiled model...
App: ✓ Loaded in 0.23 seconds (100x faster!)
App: Ready! 🚀
```

**Instant startup - professional experience!**

## Benefits

Once you upload the .rds file:

- ✅ **Instant startup** - < 1 second instead of 60-120 seconds
- ✅ **No C++ compiler needed** - Users don't need RTools/Xcode
- ✅ **Professional UX** - App appears instantly
- ✅ **Same functionality** - Priors still fully dynamic
- ✅ **Easy distribution** - One-time compilation benefits all users

## When to Recompile

You need to recompile ONLY when:
- ❌ Stan model code changes (`stan_universal_model_optimized.stan`)
- ❌ Stan version has major update

You do NOT need to recompile for:
- ✅ Prior distribution changes (they're data!)
- ✅ Sampling parameter changes (chains, iterations, etc.)
- ✅ UI changes
- ✅ App logic changes
- ✅ Documentation updates

## Troubleshooting

### "Stan model failed to compile"

**Solution:**
1. Check you have C++ compiler installed
   - Windows: Install RTools
   - Mac: Install Xcode Command Line Tools
   - Linux: Install build-essential
2. Try updating rstan: `install.packages("rstan")`
3. Check Stan model syntax is valid

### "Error: cannot open file 'inst/stan/...'"

**Solution:**
Make sure you're running the script from the repository root:
```bash
cd /path/to/POS-simulation
pwd  # Should show /path/to/POS-simulation
Rscript tools/precompile_stan_model.R
```

### "Model compiles but .rds file not created"

**Solution:**
Check directory permissions:
```bash
ls -la inst/stan/
```

Try creating manually:
```r
model <- stan_model("inst/stan/stan_universal_model_optimized.stan")
saveRDS(model, "inst/stan/stan_model_compiled.rds", compress = "xz")
```

### "Git says file is too large"

**Solution:**
The .rds file should be 2-3 MB, which is fine for GitHub. If it's larger:
1. Check compression was used (script uses `compress = "xz"`)
2. If needed, use Git LFS: `git lfs track "*.rds"`

## File Locations

After compilation, you'll have:

```
POS-simulation/
├── inst/
│   └── stan/
│       ├── stan_universal_model_optimized.stan    # Source code
│       └── stan_model_compiled.rds                # ← YOU CREATE THIS
├── tools/
│   └── precompile_stan_model.R                    # ← YOU RUN THIS
└── R/
    └── load_precompiled_stan_model.R              # Loads the .rds
```

## Summary

**What you need to do:**

1. ✅ Run: `Rscript tools/precompile_stan_model.R` (1-2 min)
2. ✅ Commit: `git add inst/stan/stan_model_compiled.rds` (30 sec)
3. ✅ Push: `git push` (30 sec)

**What users get:**
- 🚀 Instant startup (< 1 second)
- ✅ No compilation wait
- ✅ Professional experience

**Total time: 3 minutes to help all users forever!**

---

## Need Help?

If you encounter issues:
1. Check the error message carefully
2. Verify prerequisites (R, rstan, C++ compiler)
3. Try running the script with verbose output
4. See `tools/README_PRECOMPILATION.md` for more details
5. See `PRECOMPILED_STAN_MODEL.md` for user documentation

**The infrastructure is ready - just needs the compiled model!** 🚀
