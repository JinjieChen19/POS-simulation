# Precompiling the Stan Model

## Why Precompile?

Stan model compilation takes 1-2 minutes. By precompiling the model once and saving it as an `.rds` file, users experience instant app startup with zero compilation wait!

## How to Precompile

### Option 1: Run the Precompilation Script

From the package root directory:

```r
Rscript tools/precompile_stan_model.R
```

Or from within R:

```r
source("tools/precompile_stan_model.R")
```

### Option 2: Manual Precompilation

```r
library(rstan)

# Compile the model
model_compiled <- stan_model(
  file = "inst/stan/stan_universal_model_optimized.stan",
  model_name = "bayesian_pos_universal_optimized",
  verbose = TRUE
)

# Save it
saveRDS(model_compiled, "inst/stan/stan_model_compiled.rds", compress = "xz")
```

## What Gets Created

- **File:** `inst/stan/stan_model_compiled.rds`
- **Size:** ~1-3 MB (compressed)
- **Contains:** Precompiled Stan model ready for immediate use

## When to Recompile

Recompile only when the **Stan model code** changes:

- `inst/stan/stan_universal_model_optimized.stan` is modified
- Stan version is updated (major version changes)

**You do NOT need to recompile when:**
- Priors change (passed as data)
- Sampling parameters change (passed to sampling())
- UI changes
- App logic changes

## Benefits

- ✅ **Instant startup:** < 1 second vs 60-120 seconds
- ✅ **Better UX:** No waiting for compilation
- ✅ **Same functionality:** Model accepts all data/priors dynamically
- ✅ **Works offline:** No compilation tools needed on user machines

## Package Building

When building the package, ensure `inst/stan/stan_model_compiled.rds` is included:

```r
# In .Rbuildignore, do NOT exclude .rds files in inst/stan/
```

The precompiled model will be installed with the package and loaded automatically.
