# Namespace Conflict Fix: MASS::select vs dplyr::select

## Problem Summary

Two errors were occurring in the Shiny app:

1. **Scatter Plot Tab Error:**
   ```
   Error: unused arguments (loghr_pfs, loghr_os, type)
   ```

2. **Data Tab Error:**
   ```
   Error: unused arguments (trial_id, cancer_type, n_patients, loghr_os, 
                           se_loghr_os, loghr_pfs, se_loghr_pfs, corr_pfs_os)
   ```

## Root Cause

The `MASS` package (loaded for `mvrnorm` function) exports a `select()` function that was masking `dplyr::select()` from the tidyverse package.

**Package Loading Order:**
```r
library(tidyverse)  # Loads dplyr::select
# ... other libraries ...
library(MASS)       # Masks dplyr::select with MASS::select
```

**Function Signature Difference:**
- `dplyr::select(data, col1, col2, ...)` - Select columns by name
- `MASS::select(formula, data, ...)` - Different purpose entirely

## Solution

Explicitly specify the namespace for `select()` calls to use `dplyr::select()`:

### Line 677 (Data Tab):
```r
# BEFORE (incorrect):
historical_data %>%
  select(trial_id, cancer_type, n_patients, ...)

# AFTER (correct):
historical_data %>%
  dplyr::select(trial_id, cancer_type, n_patients, ...)
```

### Line 719 (Scatter Plot):
```r
# BEFORE (incorrect):
plot_data %>% select(loghr_pfs, loghr_os, type)

# AFTER (correct):
plot_data %>% dplyr::select(loghr_pfs, loghr_os, type)
```

## Why This Works

By explicitly using `dplyr::select()`, we bypass R's function search path and directly call the correct function from the dplyr package, avoiding the namespace conflict.

## Best Practices

### Option 1: Explicit Namespacing (Used Here)
Always use `package::function()` notation when conflicts are possible:
```r
dplyr::select(...)
dplyr::filter(...)
dplyr::summarize(...)
```

### Option 2: Load Order Management
Load conflicting packages before tidyverse:
```r
library(MASS)       # Load first
library(tidyverse)  # Loads last, masks MASS functions
```

### Option 3: Use conflicted Package
```r
library(conflicted)
conflict_prefer("select", "dplyr")
conflict_prefer("filter", "dplyr")
```

## Impact

- ✅ Data tab now displays historical trial data correctly
- ✅ Scatter plot renders with all 27 historical + 1 current trial points
- ✅ No more "unused arguments" errors
- ✅ Minimal code changes (only 2 lines)

## Files Modified

- `app.R` - Lines 677 and 719

## Testing

To verify the fix:
1. Run the Shiny app
2. Navigate to "Data" tab - should see historical trials table
3. Navigate to "Scatter Plot" tab - should see 27 blue points + 1 red diamond
4. No errors should appear in R console

## References

- [dplyr::select documentation](https://dplyr.tidyverse.org/reference/select.html)
- [MASS::select documentation](https://stat.ethz.ch/R-manual/R-devel/library/MASS/html/select.html)
- [Managing namespace conflicts in R](https://conflicted.r-lib.org/)
