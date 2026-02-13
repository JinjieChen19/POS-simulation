# Customizable Data Generation Parameters

## Overview

The Shiny app now provides complete control over the historical data generation process. Users can adjust all parameters that control how the 27 historical trials are simulated, enabling sensitivity analyses, simulation studies, and educational demonstrations.

## New Features

### Data Generation Parameters Panel

Located in the **"Run Model"** tab, a new "Data Generation Parameters" panel provides controls for:

1. **Random Seed**
2. **Population Parameters** (true values for data generation)
3. **Standard Error Ranges**
4. **Within-Trial Correlation Range**

### Real-Time Updates

- Historical data is now **reactive** - it regenerates automatically when any parameter changes
- The **Data tab** updates to show the new dataset
- The **Scatter Plot** updates to display the new data points
- No need to re-run the Stan model just to see data changes

## Parameter Reference

### 1. Random Seed

**Control:** `data_seed`  
**Default:** 20260212  
**Purpose:** Ensures reproducible data generation  

**Usage:**
- Keep constant for reproducible analyses
- Change to generate different random realizations
- Useful for simulation studies (run multiple seeds)

### 2. Population Parameters

These are the **TRUE** population values used to generate the 27 historical trials:

#### μ_OS (True OS Population Mean)
- **Control:** `data_mu_os`
- **Default:** -0.30
- **Typical range:** -0.50 to -0.10
- **Purpose:** Center of the OS logHR distribution across trials

#### μ_PFS (True PFS Population Mean)
- **Control:** `data_mu_pfs`
- **Default:** -0.45
- **Typical range:** -0.70 to -0.20
- **Purpose:** Center of the PFS logHR distribution across trials

#### τ_OS (True OS Between-Trial SD)
- **Control:** `data_tau_os`
- **Default:** 0.15
- **Typical range:** 0.05 to 0.30
- **Purpose:** How much trials vary in OS effect
- **Note:** Larger values = more heterogeneity

#### τ_PFS (True PFS Between-Trial SD)
- **Control:** `data_tau_pfs`
- **Default:** 0.15
- **Typical range:** 0.05 to 0.30
- **Purpose:** How much trials vary in PFS effect
- **Note:** Larger values = more heterogeneity

#### ρ (True Between-Trial Correlation)
- **Control:** `data_rho_true`
- **Default:** 0.65
- **Range:** -0.95 to 0.95
- **Purpose:** Correlation between trial-level OS and PFS effects
- **Interpretation:**
  - ρ > 0.7: Strong positive correlation (typical in oncology)
  - ρ = 0.4-0.7: Moderate positive correlation
  - ρ < 0.4: Weak or no correlation
  - ρ < 0: Negative correlation (rare)

### 3. Standard Error Ranges

These control the range of within-trial measurement precision:

#### SE_OS Range
- **Controls:** `data_se_os_min`, `data_se_os_max`
- **Defaults:** 0.10 to 0.13
- **Typical range:** 0.08 to 0.25
- **Purpose:** Variability in OS measurement precision across trials
- **Note:** SE inversely related to number of events (SE ≈ 2/√events)

#### SE_PFS Range
- **Controls:** `data_se_pfs_min`, `data_se_pfs_max`
- **Defaults:** 0.08 to 0.11
- **Typical range:** 0.06 to 0.20
- **Purpose:** Variability in PFS measurement precision across trials
- **Note:** PFS typically has more events → smaller SE than OS

### 4. Within-Trial Correlation Range

#### ρ_within Range
- **Controls:** `data_rho_within_min`, `data_rho_within_max`
- **Defaults:** 0.55 to 0.75
- **Typical range:** 0.40 to 0.90
- **Purpose:** Patient-level correlation between OS and PFS measurements
- **Note:** This is DIFFERENT from between-trial correlation (ρ)

**Key distinction:**
- **Between-trial ρ:** Correlation of trial-level effects (population parameter)
- **Within-trial ρ_within:** Correlation of measurements within a trial (sampling correlation)

## Use Cases

### 1. Sensitivity Analysis

**Question:** How sensitive is PoS to the true between-trial correlation?

**Steps:**
1. Run model with default ρ_true = 0.65
2. Note the PoS estimate
3. Change ρ_true to 0.40
4. Regenerate data (happens automatically)
5. Re-run Stan model
6. Compare PoS estimates

**Expected:** Lower ρ_true → less cross-endpoint borrowing → different PoS

### 2. Simulation Study

**Question:** How well does the model recover true parameters?

**Steps:**
1. Set known true values (e.g., ρ_true = 0.70, τ_os = 0.20)
2. Generate data with seed = 1
3. Run model, record posterior means
4. Repeat with seeds 2, 3, 4, ..., 100
5. Calculate bias, coverage, etc.

**Analysis:** Compare posterior means to true values

### 3. Impact of Heterogeneity

**Question:** How does heterogeneity affect estimation?

**Steps:**
1. Run with τ_os = τ_pfs = 0.05 (low heterogeneity)
2. Record posterior SD for ρ
3. Run with τ_os = τ_pfs = 0.25 (high heterogeneity)
4. Record posterior SD for ρ
5. Compare

**Expected:** Higher τ → harder to estimate ρ → wider credible intervals

### 4. SE Impact

**Question:** How do SE ranges affect results?

**Steps:**
1. Run with narrow SE ranges (0.10-0.11, 0.08-0.09)
2. Run with wide SE ranges (0.10-0.25, 0.08-0.20)
3. Compare uncertainty in estimates

**Expected:** Wider SE ranges → more variable data → wider posteriors

### 5. Within vs. Between Correlation

**Question:** How do within-trial and between-trial correlations interact?

**Steps:**
1. Set ρ_true = 0.70 (between-trial)
2. Set ρ_within = 0.40-0.50 (low within-trial)
3. Note the estimated ρ
4. Set ρ_within = 0.80-0.90 (high within-trial)
5. Compare

**Expected:** Within-trial correlation affects measurement noise but not structural ρ

## Examples

### Example 1: Default Settings (Realistic Oncology)

```r
seed = 20260212
μ_OS = -0.30, μ_PFS = -0.45
τ_OS = 0.15, τ_PFS = 0.15
ρ_true = 0.65
SE_OS: 0.10-0.13, SE_PFS: 0.08-0.11
ρ_within: 0.55-0.75
```

**Interpretation:** Typical immunotherapy trials with moderate heterogeneity and strong positive correlation.

### Example 2: High Heterogeneity

```r
seed = 20260212
μ_OS = -0.30, μ_PFS = -0.45
τ_OS = 0.25, τ_PFS = 0.25  ← INCREASED
ρ_true = 0.65
SE_OS: 0.10-0.13, SE_PFS: 0.08-0.11
ρ_within: 0.55-0.75
```

**Interpretation:** Trials vary substantially in treatment effects. Harder to estimate ρ.

### Example 3: Weak Correlation

```r
seed = 20260212
μ_OS = -0.30, μ_PFS = -0.45
τ_OS = 0.15, τ_PFS = 0.15
ρ_true = 0.20  ← LOW
SE_OS: 0.10-0.13, SE_PFS: 0.08-0.11
ρ_within: 0.55-0.75
```

**Interpretation:** OS and PFS benefits don't correlate strongly across trials. Less cross-endpoint borrowing.

### Example 4: Variable Precision

```r
seed = 20260212
μ_OS = -0.30, μ_PFS = -0.45
τ_OS = 0.15, τ_PFS = 0.15
ρ_true = 0.65
SE_OS: 0.10-0.25, SE_PFS: 0.08-0.20  ← WIDER RANGE
ρ_within: 0.55-0.75
```

**Interpretation:** Trials have very different sample sizes/event counts. More realistic variation.

## Technical Notes

### Data Generation Process

1. **Set seed:** `set.seed(data_seed)`
2. **Create covariance matrix:**
   ```r
   R_true <- matrix(c(1, ρ_true, ρ_true, 1), 2, 2)
   Σ_true <- diag(τ) %*% R_true %*% diag(τ)
   ```
3. **Generate trial effects:** `θ ~ MVN(μ_true, Σ_true)`
4. **Generate SEs:** Sample from uniform(min, max) for each trial
5. **Generate within-trial correlations:** Sample ρ_within from uniform(min, max)
6. **Generate observations:** For each trial k:
   ```r
   W_k <- build_within_trial_covariance(SE_k, ρ_within_k)
   y_k ~ MVN(θ_k, W_k)
   ```

### Reactive Behavior

The `historical_data` object is now a **reactive** that depends on all data generation inputs:

```r
historical_data <- reactive({
  prepare_historical_loghr_data(
    seed = input$data_seed,
    mu_os = input$data_mu_os,
    ...
  )
})
```

**Implications:**
- Any change to data generation inputs triggers re-generation
- Data tab, scatter plot, and model all use `historical_data()`
- Efficient - only regenerates when inputs actually change

### Relationship to Priors

**Important:** Data generation parameters are SEPARATE from model priors!

- **Data generation parameters:** TRUE population values used to create the 27 trials
- **Model priors:** Our beliefs about population parameters (may or may not match truth)

**Example:**
- Data: Generated with ρ_true = 0.65
- Prior: Fisher-z with μ_z = 0.5365 (implies ρ ~ [0.35, 0.80])
- Posterior: Should center near 0.65 (data wins)

**For simulation studies:**
- Set data parameters to known "truth"
- Use realistic priors
- Check if posterior recovers truth

## Recommendations

### Default Settings (Don't Change Unless Needed)

For typical oncology trials, the defaults are well-calibrated:
- ρ_true = 0.65 (strong positive correlation)
- τ = 0.15 (moderate heterogeneity)
- SE ranges match Schoenfeld-like precisions
- ρ_within = 0.55-0.75 (typical patient-level correlation)

**When to change:**
1. **Simulation studies:** Testing specific scenarios
2. **Sensitivity analysis:** Understanding robustness
3. **Educational demos:** Illustrating concepts
4. **Different disease:** Non-oncology settings

### Best Practices

1. **Document your settings:** Record all parameter values used
2. **Use informative seeds:** e.g., 20260213 = Feb 13, 2026
3. **Run multiple seeds:** For simulation studies, vary only seed
4. **Match reality:** Use τ and ρ values from meta-analyses if available
5. **Check data:** Always review Data tab and Scatter Plot after changes
6. **Separate concerns:** Data generation ≠ priors (set independently)

## Troubleshooting

### Q: I changed a parameter but nothing happened?

**A:** Make sure you're looking at the right tab:
- **Data tab:** Updates immediately when parameters change
- **Scatter Plot:** Updates immediately when parameters change
- **Results:** Only updates after clicking "Run Stan Model" again

### Q: My ρ estimate doesn't match ρ_true?

**A:** This is normal! Several reasons:
1. **Sampling variation:** With K=27, expect error ~±0.15
2. **Prior influence:** Informative priors pull estimates
3. **SE noise:** Large SEs → harder to estimate ρ
4. **Check:** Look at credible interval - does it include ρ_true?

### Q: What if I want more than 27 trials?

**A:** Currently fixed at K=27 in the code. This is intentional:
- 27 trials is realistic for oncology meta-analyses
- Enough for stable estimation
- Keeps computation reasonable
- To change: Edit `K <- 27` in `prepare_historical_loghr_data()`

### Q: Can I use negative ρ_true?

**A:** Yes! Set -0.95 ≤ ρ_true ≤ 0.95
- Negative ρ is rare in oncology but mathematically valid
- Useful for simulation studies
- May need adjusted priors (e.g., Uniform(-0.95, 0.95) instead of Fisher-z)

## Summary

The new data generation controls provide unprecedented flexibility for:
- ✅ Sensitivity analyses
- ✅ Simulation studies
- ✅ Educational demonstrations
- ✅ Custom scenarios
- ✅ Validation exercises

All while maintaining:
- ✅ Realistic default values
- ✅ Real-time reactive updates
- ✅ Clean separation from prior specifications
- ✅ Full documentation

**Next:** Try changing ρ_true and observing the impact on posterior estimates!
