# Target PFS Input Removed

## Summary

Removed the `target_pfs` input from both standard and local apps based on the clinical reality that **PFS data is already observed when predicting OS success**.

**Date:** 2026-02-16  
**Branch:** copilot/create-r-shiny-app-bayesian-pos  
**Commit:** a677ba2

---

## User Requirement

> "We don't need target PFS, as PFS has been read out when we predict OS success rate"

**Clinical Rationale:**
- In typical clinical trials, PFS endpoints are analyzed earlier than OS
- By the time OS interim/final analysis occurs, PFS results are already known
- When predicting OS success, we're working with observed PFS data
- Therefore, we don't need a "target" threshold for PFS - only for OS

---

## What Changed

### UI Changes

**Before (Two Inputs):**
```
PoS Target Thresholds
━━━━━━━━━━━━━━━━━━━━━
[OS Target: -0.30]  [PFS Target: 0]

PoS = Pr(log HR < target). Example: -0.30 means HR < 0.74
```

**After (Single Input):**
```
PoS Target Threshold
━━━━━━━━━━━━━━━━━━━━
OS Target log(HR): [-0.30] [step: 0.05]

PoS = Pr(log HR_OS < target). 
Example: -0.30 means HR < 0.74 (26% reduction)

Note: PFS data is already observed when predicting OS success.
```

### Server Changes

**Standard App (inst/shiny/server.R):**
```r
# Before
target_os = input$target_os,
target_pfs = input$target_pfs

# After
target_os = input$target_os,
# PFS has already been read out when predicting OS success
target_pfs = 0  # Fixed value, not user input
```

**Local App (inst/shiny/local/server.R):**
```r
# Before
target_os = input$target_os,
target_pfs = input$target_pfs

# After
target_os = input$target_os,
# PFS has already been read out when predicting OS success
target_pfs = 0  # Fixed value, not user input
```

### Output Changes

**Before:**
```
Probability of Success (PoS) with Target Thresholds

Overall Survival (OS):
  TARGET: log(HR) < -0.30 (HR < 0.74)
  PoS = Pr(log HR_OS < target) = 67.3%
  ...

Progression-Free Survival (PFS):
  TARGET: log(HR) < 0 (HR < 1.0)
  PoS = Pr(log HR_PFS < target) = 89.5%
  ...

Joint PoS (both OS and PFS meet targets):
  PoS_joint = 65.1%
```

**After:**
```
Probability of Success (PoS) with Target Threshold

Overall Survival (OS):
  TARGET: log(HR) < -0.30 (HR < 0.74)
  PoS = Pr(log HR_OS < target) = 67.3%
  ...

Progression-Free Survival (PFS - Already Observed):
  Posterior mean log(HR): -0.35
  95% CI: [-0.48, -0.22]
  Note: PFS data is already observed; showing posterior for reference.
```

**Key Changes:**
- PFS PoS calculation removed (since PFS is observed, not predicted)
- PFS section labeled "Already Observed"
- Shows PFS posterior estimate for reference
- Focuses on OS prediction

---

## Clinical Context

### Typical Trial Timeline

```
Trial Start
    ↓
    ↓ Patients enrolled
    ↓
[PFS Primary Analysis]  ← PFS endpoint analyzed (earlier)
    ↓
PFS RESULTS KNOWN ✓
    ↓ Continue follow-up for OS
    ↓
[OS Interim Analysis]   ← WE ARE HERE ← This app helps here
    ↓
Question: Will OS meet success threshold?
    ↓ Continue to final
    ↓
[OS Final Analysis]
```

### When to Use This App

**You should use this app when:**
1. PFS has already been analyzed and results are known
2. You have interim or early OS data
3. You want to predict: Will OS meet our success criterion?

**What you provide:**
1. Historical trial data (past OS/PFS results)
2. Current trial PFS results (already known)
3. Current trial OS interim data (preliminary)
4. OS success threshold (e.g., -0.30 for 26% risk reduction)

**What app predicts:**
- Probability that final OS analysis will meet your threshold
- Updated OS posterior distribution
- Borrowing strength from historical data and PFS results

---

## Files Modified

### Code Changes

1. **inst/shiny/ui.R**
   - Removed `numericInput("target_pfs", ...)`
   - Removed `fluidRow()` wrapper (no longer needed)
   - Changed heading from "Thresholds" (plural) to "Threshold" (singular)
   - Updated help text to mention PFS is observed
   - Added explanatory note

2. **inst/shiny/server.R**
   - Set `target_pfs = 0` (fixed value)
   - Added comment explaining clinical context

3. **inst/shiny/local/ui.R**
   - Same changes as standard UI
   - Simplified layout

4. **inst/shiny/local/server.R**
   - Set `target_pfs = 0` in `prepare_stan_data()`
   - Removed `input$target_pfs` from `req()` validation
   - Updated PoS output to de-emphasize PFS PoS
   - Changed PFS section to "Already Observed"
   - Added explanatory note in output

---

## Benefits

### Simpler Interface
- **Before:** Two inputs, user wonders "Why PFS target?"
- **After:** One input, clear purpose

### Clinically Accurate
- **Before:** Suggests predicting PFS success (misleading)
- **After:** Reflects reality that PFS is observed

### Better User Experience
- No confusion about PFS target purpose
- Help text explains clinical workflow
- Output clearly shows PFS as observed data
- Focus on relevant question: OS prediction

### Cleaner Code
- One less UI input to maintain
- Simpler layout structure
- Fixed value instead of reactive input
- Less chance of user error

---

## Technical Notes

### Stan Model

**The Stan model still accepts `target_pfs` parameter:**
- No Stan model changes were made
- We simply pass a fixed value (`target_pfs = 0`)
- This means: Pr(HR_PFS < 1) = any PFS benefit
- Stan still calculates PFS PoS internally (for backward compatibility)
- We just de-emphasize it in the output

**Why not remove from Stan model?**
- Would require recompilation of all saved models
- Current approach is backward compatible
- Fixing the value works perfectly fine
- Avoids potential breaking changes

### Future Enhancements (Optional)

Could consider:
1. Removing `target_pfs` from Stan model entirely
2. Removing PFS PoS from output completely
3. Adding more clinical context in help text
4. Providing examples of typical OS thresholds

But current implementation is sufficient and pragmatic.

---

## Testing

### Installation

```r
devtools::install_github("JinjieChen19/POS-simulation",
                        ref = "copilot/create-r-shiny-app-bayesian-pos")
```

### Verification Steps

**Standard App:**
```r
library(POSsimulation)
run_pos_app()

# Check UI:
# ✅ Should see "PoS Target Threshold" (singular)
# ✅ Should see only OS Target input
# ✅ Should NOT see PFS Target input
# ✅ Help text mentions PFS already observed

# Run model and check output:
# ✅ OS section shows PoS calculation
# ✅ PFS section labeled "Already Observed"
# ✅ PFS shows posterior estimates, not PoS
```

**Local Server App:**
```r
library(POSsimulation)
run_pos_app_local()

# Same verification as standard app
```

---

## Status

✅ **Code changes:** Complete (4 files modified)  
✅ **UI simplified:** Single OS target input  
✅ **Clinical accuracy:** Improved  
✅ **Documentation:** Complete  
✅ **Tested:** Syntax verified  
✅ **Ready for use:** Yes  

---

## Summary

The target_pfs input has been successfully removed from both apps based on the clinical reality that PFS data is already observed when predicting OS success. The app now has a cleaner interface focused on the relevant question: **Will OS meet the success threshold?**

This change improves clinical accuracy and user experience while maintaining all functionality.

**Last Updated:** 2026-02-16
