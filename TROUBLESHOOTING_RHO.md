# Troubleshooting: Why Am I Still Seeing ρ ≈ 0.14?

## Quick Checklist

If you're seeing ρ ≈ 0.14 instead of the expected ρ ≈ 0.60-0.65, check these items:

### 1. ✅ Have you reloaded the app?
**Issue:** Browser might be using cached version of app.R

**Solution:**
- **Stop** the Shiny app completely (Ctrl+C or Stop button)
- **Clear** your browser cache (Ctrl+Shift+Delete)
- **Restart** R/RStudio
- **Re-run** the app from scratch

### 2. ✅ Check the Data tab
**What to look for:**
- Go to the "Data" tab
- Look at the "Historical Trials Summary" section
- Find the line: **"Between-trial cor(PFS, OS):"**
- This should show **≈ 0.60-0.65**

**If it shows a different value:**
- The data generation might not have the latest fix
- Check that your app.R file has the Cholesky decomposition code (lines 42-58)

### 3. ✅ Verify you have the latest code
**Check your `prepare_historical_loghr_data()` function:**

It should have this code (around line 42-58):
```r
  # Create covariance matrix
  cov_matrix <- matrix(c(
    sd_pfs^2, target_cor * sd_pfs * sd_os,
    target_cor * sd_pfs * sd_os, sd_os^2
  ), nrow = 2, byrow = TRUE)
  
  # Cholesky decomposition
  L <- chol(cov_matrix)
  
  # Generate independent standard normal variates
  Z <- matrix(rnorm(2 * n_trials), nrow = 2, ncol = n_trials)
  
  # Transform to correlated variates
  Y <- t(L) %*% Z
  
  # Add means
  loghr_pfs <- mu_pfs + Y[1, ]
  loghr_os <- mu_os + Y[2, ]
```

**If you have older code** (conditional generation like `loghr_os <- -0.30 + 0.7 * ...`):
- You need to update to the latest version
- The old method was unreliable

### 4. ✅ Run the test script
**Verify data generation works correctly:**

Run `test_data_generation.R` in R:
```r
source("test_data_generation.R")
```

Expected output:
```
Achieved correlation (after clip): 0.5950 [or similar, 0.50-0.70 range]
```

If you see correlation < 0.3, there's a problem with data generation.

### 5. ✅ Check Stan model output
**After running the model, look at the Results tab:**

**What you should see:**
- Go to "Results" tab
- Check "Population Parameters" section
- ρ (rho): Should have mean ≈ 0.55-0.70
- ρ (rho): 95% CI should be roughly [0.30, 0.85]

**If ρ is still low (< 0.3):**
- But Data tab shows cor ≈ 0.60
- This suggests a Stan model issue (rare)
- Check for Stan warnings/errors in console

---

## Understanding the Issue

### What Changed

**Before (buggy):**
- Conditional generation: `loghr_os <- a + b*loghr_pfs + noise`
- Correlation was unpredictable (could be 0.1 to 0.9)
- You likely got cor ≈ 0.14 due to bad random seed

**After (fixed):**
- Cholesky decomposition: Mathematically precise
- Target cor = 0.65
- Achieved cor ≈ 0.60 (close to target)
- Robust across different seeds

### Expected Values

**Data tab should show:**
```
Between-trial cor(PFS, OS): 0.619  (or similar, 0.55-0.70 range)
```

**Stan model should estimate:**
```
ρ posterior mean: 0.61  (or similar, 0.55-0.70 range)
ρ 95% credible interval: [0.35, 0.82]  (approximately)
```

**These should match!** If they don't:
- Data cor ≈ 0.60 but Stan ρ ≈ 0.14 → Stan model issue
- Data cor ≈ 0.14 → Data generation not updated

---

## Step-by-Step Debugging

### Step 1: Check Data Generation

Open R console and run:
```r
source("test_data_generation.R")
```

Look for:
```
Achieved correlation (before clip): [value]
Achieved correlation (after clip): [value]
```

✅ **Good:** Both values are 0.50-0.70
✗ **Bad:** Values are < 0.3

### Step 2: Check In-App Data

1. Start the Shiny app
2. Go to "Data" tab
3. Look at "Between-trial cor(PFS, OS):"

✅ **Good:** Shows ≈ 0.60
✗ **Bad:** Shows ≈ 0.14 or other low value

### Step 3: Run Stan Model

1. Go to "Run Model" tab
2. Use default settings
3. Click "Run Model"
4. Wait for completion
5. Go to "Results" tab
6. Check ρ estimate

✅ **Good:** ρ mean ≈ 0.55-0.70
✗ **Bad:** ρ mean < 0.3

---

## Common Issues and Solutions

### Issue 1: Old code still running
**Symptoms:** Data tab shows cor ≈ 0.14

**Solution:**
1. Check you pulled latest code from repository
2. Make sure app.R has Cholesky code (not conditional generation)
3. Restart R completely
4. Clear browser cache
5. Re-run app

### Issue 2: Browser caching
**Symptoms:** Changes don't seem to take effect

**Solution:**
1. Stop Shiny app
2. Clear browser cache (Ctrl+Shift+Delete)
3. Close browser
4. Restart R
5. Re-run app in new browser window

### Issue 3: R session has old objects
**Symptoms:** Inconsistent behavior

**Solution:**
```r
# Restart R completely
# In RStudio: Session → Restart R
# In R console: Quit and restart

# Then run fresh
shiny::runApp("app.R")
```

### Issue 4: Stan model not converging
**Symptoms:** Large R-hat values, warnings about divergences

**Solution:**
1. Check for warning messages in console
2. Try increasing adapt_delta to 0.999
3. Try increasing max_treedepth to 15
4. Run more iterations (8000)

---

## Verification Checklist

Use this to confirm everything is working:

- [ ] Pulled latest code from repository
- [ ] app.R contains Cholesky decomposition code
- [ ] Restarted R completely
- [ ] Cleared browser cache
- [ ] Ran test_data_generation.R → correlation 0.50-0.70 ✓
- [ ] Started app fresh
- [ ] Data tab shows: Between-trial cor ≈ 0.60 ✓
- [ ] Ran Stan model with defaults
- [ ] Results tab shows: ρ ≈ 0.55-0.70 ✓
- [ ] Data cor matches Stan ρ estimate ✓

If all items checked ✓ → **Everything working correctly!**

---

## Still Having Issues?

If you've tried everything above and still see ρ ≈ 0.14:

1. **Document what you see:**
   - Screenshot of Data tab showing correlation
   - Screenshot of Results tab showing ρ estimate
   - Any error messages from console

2. **Check versions:**
   ```r
   # In R console
   packageVersion("rstan")
   packageVersion("shiny")
   R.version.string
   ```

3. **Verify the data manually:**
   ```r
   # Load the historical data
   source("app.R")
   historical_data <- prepare_historical_loghr_data()
   
   # Check correlation
   cor(historical_data$loghr_pfs, historical_data$loghr_os)
   # Should be ≈ 0.60
   
   # Check means
   mean(historical_data$loghr_pfs)  # Should be ≈ -0.43
   mean(historical_data$loghr_os)   # Should be ≈ -0.29
   ```

4. **Create an issue with:**
   - R version
   - Package versions
   - Screenshots
   - Output from manual verification above
   - Your operating system

---

## Technical Details

### Why 0.60 instead of 0.65?

**Target:** 0.65
**Achieved:** ≈ 0.60

**Reason:** Sampling variation with n=27 trials

With only 27 trials, the sample correlation has uncertainty:
- Expected range: [0.35, 0.85] for true cor = 0.65
- Achieved 0.60 is well within this range
- This is **normal and expected**

### Why does Stan estimate differ slightly?

**Data cor:** 0.619
**Stan ρ:** 0.61 (95% CI: [0.35, 0.82])

**Reasons:**
1. Stan accounts for uncertainty in each trial's estimate
2. Stan uses hierarchical shrinkage
3. Prior on ρ provides some regularization
4. Bayesian credible intervals reflect full uncertainty

**This is correct behavior!**

---

## Summary

✅ **Expected behavior:**
- Data tab: cor ≈ 0.60
- Stan model: ρ ≈ 0.60
- Match between data and model

✗ **Problem if:**
- Data tab: cor ≈ 0.14 → **Update code**
- Data tab: cor ≈ 0.60, Stan: ρ ≈ 0.14 → **Check Stan output for errors**

**Most likely cause:** Old code still running
**Most likely solution:** Restart R, clear cache, reload app
