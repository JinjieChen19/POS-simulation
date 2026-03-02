# PoS Calculation Fix

## Problem

The standard app was incorrectly calculating Probability of Success (PoS) as:

```
PoS = P(θ_OS < 0 | data)
```

This is **wrong** because it only checks if the hazard ratio is less than 1 (any benefit), rather than checking if it meets the user-specified target threshold.

## User Report

```
Probability of Success (PoS) for OS
============================================================ 

PoS = P(θ_OS < 0 | data) = 100%

Posterior Summary for θ_OS:
  Mean:   -0.303 
  Median: -0.3029 
  SD:     0.0732 
  95% CI: [-0.4454, -0.147]

Interpretation:
  Very high probability of success (≥90%) 这个还是算 OS <0 不对
```

**Translation:** "这个还是算 OS <0 不对" = "This is still calculating OS < 0, which is wrong"

## The Fix

### Before (Wrong)

**Code:**
```r
pos <- mean(theta_os_post < 0)

cat("PoS = P(θ_OS < 0 | data) = ", round(pos * 100, 2), "%\n\n", sep = "")
```

**Output:**
```
PoS = P(θ_OS < 0 | data) = 100%
```

**Problem:** This shows 100% because ALL posterior samples are < 0, but this doesn't tell us if the treatment meets the target success criterion (e.g., -0.30).

### After (Correct)

**Code:**
```r
req(input$target_os)

# Calculate PoS using user-specified target threshold
pos <- mean(theta_os_post < input$target_os)

# Also calculate traditional PoS (HR < 1) for comparison
pos_trad <- mean(theta_os_post < 0)

cat("TARGET: log(HR) < ", input$target_os, " (HR < ", round(exp(input$target_os), 3), ")\n", sep = "")
cat("PoS = P(θ_OS < ", input$target_os, " | data) = ", round(pos * 100, 2), "%\n", sep = "")
cat("Traditional PoS (HR < 1) = ", round(pos_trad * 100, 2), "%\n\n", sep = "")
```

**Output (with target_os = -0.30):**
```
TARGET: log(HR) < -0.3 (HR < 0.741)
PoS = P(θ_OS < -0.3 | data) = 52.7%
Traditional PoS (HR < 1) = 100%

Posterior Summary for θ_OS:
  Mean:   -0.303 
  Median: -0.3029 
  SD:     0.0732 
  95% CI: [-0.4454, -0.147]

Interpretation:
  Moderate probability of success (50-70%)
```

## Why This Matters

### Example Scenario

**Trial Design:**
- Target: 26% risk reduction (HR < 0.74, or log(HR) < -0.30)
- Posterior mean: log(HR) = -0.303
- Posterior SD: 0.0732

**Old (Wrong) Calculation:**
- PoS = P(log HR < 0 | data) = 100%
- Interpretation: "Guaranteed success!"
- **Problem:** This doesn't reflect the target criterion

**New (Correct) Calculation:**
- PoS = P(log HR < -0.30 | data) ≈ 52%
- Interpretation: "About 50-50 chance of meeting target"
- **Accurate:** Mean (-0.303) is very close to target (-0.30), so ~50% probability

### Clinical Decision Making

**Wrong PoS (100%):**
- Might lead to false confidence
- "100% success" sounds great but is misleading
- Doesn't help with Go/No-Go decision

**Correct PoS (52%):**
- Reflects actual probability of meeting success criterion
- "~50%" is borderline - need to consider risks
- Useful for informed decision-making

## Technical Details

### File Modified

**inst/shiny/server.R** (lines 254-282)

### Key Changes

1. **Added input validation:**
   ```r
   req(input$target_os)
   ```

2. **Calculate PoS with target:**
   ```r
   pos <- mean(theta_os_post < input$target_os)
   ```

3. **Show target in output:**
   ```r
   cat("TARGET: log(HR) < ", input$target_os, " (HR < ", round(exp(input$target_os), 3), ")\n", sep = "")
   ```

4. **Include traditional PoS for comparison:**
   ```r
   pos_trad <- mean(theta_os_post < 0)
   cat("Traditional PoS (HR < 1) = ", round(pos_trad * 100, 2), "%\n\n", sep = "")
   ```

## Verification

### How to Test

```r
# Install package
devtools::install_github("JinjieChen19/POS-simulation",
                        ref = "copilot/create-r-shiny-app-bayesian-pos")

# Run app
library(POSsimulation)
run_pos_app()

# Set parameters and run model
# Check output shows:
# ✅ "TARGET: log(HR) < -0.3"
# ✅ "PoS = P(θ_OS < -0.3 | data) = X%"
# ✅ "Traditional PoS (HR < 1) = Y%"
```

### Expected Results

**When posterior mean ≈ target:**
- Target-based PoS ≈ 50%
- Traditional PoS ≈ 100% (if mean < 0)

**When posterior mean << target:**
- Target-based PoS ≈ 100%
- Traditional PoS ≈ 100%

**When posterior mean >> target:**
- Target-based PoS ≈ 0%
- Traditional PoS may still be high

## Comparison: Standard vs Local App

**Both apps now consistent:**

| Feature | Standard App | Local App |
|---------|-------------|-----------|
| Uses target_os | ✅ FIXED | ✅ Already correct |
| Shows target | ✅ FIXED | ✅ Already correct |
| Shows traditional PoS | ✅ ADDED | ✅ Already has |
| Correct calculation | ✅ FIXED | ✅ Was correct |

## Summary

**Bug:** Standard app calculated PoS as P(θ < 0) instead of P(θ < target)

**Impact:** Misleading 100% PoS when mean < 0, regardless of target

**Fix:** Now uses `input$target_os` for calculation and display

**Result:** Accurate, meaningful PoS that reflects probability of meeting success criterion

**Status:** ✅ FIXED

---

**The PoS calculation now correctly reflects the probability of meeting the user-specified target threshold!** 🎯
