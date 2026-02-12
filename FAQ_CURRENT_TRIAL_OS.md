# FAQ: Does the Model Use Current Trial's OS (Even If Immature)?

## Quick Answer

**YES! The model DOES incorporate the current trial's Overall Survival (OS) data, even if it's not mature yet.**

---

## Detailed Explanation

### What Gets Incorporated

The Bayesian hierarchical model uses **BOTH endpoints** from the current trial:

1. **PFS (Progression-Free Survival)** - Typically more mature
2. **OS (Overall Survival)** - Can be immature with fewer events

Both are entered as "interim" data with their respective standard errors.

---

## How Immature OS is Handled

### 1. Through Standard Error (SE)

**Immature OS = Larger SE**
- Few events → Large uncertainty → Large SE
- Mature OS → More events → Smaller SE

**Example:**
```
Immature OS: log(HR) = -0.35, SE = 0.30 (high uncertainty)
Mature OS:   log(HR) = -0.35, SE = 0.15 (low uncertainty)
```

The model automatically gives less weight to immature data through Bayesian inference.

### 2. Through Hierarchical Shrinkage

The model combines three sources of information:

```
Posterior θ_OS = f(
  1. Historical trials (27 trials, informative)
  2. Current OS interim (immature, less weight via large SE)
  3. Current PFS interim (via correlation ρ)
)
```

**Key insight:** Even immature OS contributes information, but with appropriate uncertainty!

---

## Where in the Model?

### Stan Model (lines 111-112, 183, 221)

```stan
// Data
vector[2] y_curr;         // Current trial: [OS, PFS]
matrix[2, 2] W_curr;      // Current trial covariance (includes SE²)

// Likelihood
y_curr ~ multi_normal(theta_curr, W_curr);
```

### R Code (line 221)

```r
y_curr <- c(loghr_os_interim, loghr_pfs_interim)  # BOTH OS and PFS
```

### UI (lines 372-373)

```r
numericInput("loghr_os_interim", "Interim log(HR) for OS:", ...)
numericInput("se_loghr_os_interim", "SE of log(HR) for OS:", ...)
```

---

## Information Flow

### Scenario: Immature OS at Interim

```
Historical Trials:
  - 27 trials with mature OS and PFS
  - Learn population parameters (μ, τ, ρ)

Current Trial:
  - PFS: log(HR) = -0.60, SE = 0.15  (mature)
  - OS:  log(HR) = -0.35, SE = 0.30  (immature, few events)

Model combines:
  1. Historical μ_OS ≈ -0.30 (strong information)
  2. Current OS = -0.35 ± 0.30 (weak information)
  3. Current PFS = -0.60 (strong) via ρ ≈ 0.65

Posterior θ_OS ≈ -0.38 (shrunk toward historical mean, pulled by PFS)
```

---

## Why Include Immature OS?

### 1. **Prevents Over-Reliance on PFS**

Without current OS:
- Model would ONLY use PFS + correlation
- Assumes perfect PFS-OS relationship
- Risk if actual trial differs from historical pattern

With immature OS:
- Even weak OS signal provides reality check
- Prevents over-optimistic borrowing
- More conservative, realistic PoS

### 2. **Captures Early Signals**

Even with few events:
- Trend direction matters (positive vs negative)
- Magnitude uncertainty captured by large SE
- Better than ignoring OS entirely

### 3. **Bayesian Optimality**

Bayesian inference automatically:
- Weights data by precision (1/SE²)
- Immature data → low weight, not zero weight
- Optimal combination of all information

---

## Practical Example

### Setup

```
Historical trials: 27 trials, μ_OS = -0.30, ρ = 0.65

Current trial at interim:
  - PFS: n_events = 200, log(HR) = -0.60, SE = 0.15
  - OS:  n_events = 50,  log(HR) = -0.35, SE = 0.30
```

### Posterior θ_OS Calculation (simplified)

**Precision (inverse variance):**
```
Precision_hist = 1/τ² ≈ 44  (from 27 trials)
Precision_curr_OS = 1/SE² = 1/0.30² ≈ 11  (from 50 events)
Precision_PFS_via_rho ≈ ρ² × 1/0.15² ≈ 18  (from PFS)

Total precision ≈ 73
```

**Weighted average:**
```
θ_OS ≈ (44×(-0.30) + 11×(-0.35) + 18×(-0.60)) / 73
     ≈ -0.38
```

**Key points:**
- Historical data: 60% weight (44/73)
- Current OS (immature): 15% weight (11/73)
- PFS via correlation: 25% weight (18/73)

**Even with only 50 OS events, it contributes 15% of posterior!**

---

## When OS is Very Immature

### Example: Only 10 OS Events

```
OS: log(HR) = -0.35, SE = 0.60 (very large!)

Precision_OS = 1/0.60² ≈ 2.8 (very low)

Posterior θ_OS ≈ (44×(-0.30) + 2.8×(-0.35) + 18×(-0.60)) / 64.8
              ≈ -0.40

Weight distribution:
  - Historical: 68%
  - Current OS: 4% (very small, but not zero!)
  - PFS: 28%
```

**Takeaway:** Even 10 events contribute ~4% of information. Better than 0%!

---

## Common Misconceptions

### ❌ "We only use PFS at interim"

**FALSE.** The model uses both PFS and OS. Even immature OS is included.

### ❌ "Immature OS is ignored"

**FALSE.** It's DOWN-weighted (via large SE), not ignored. Important distinction!

### ❌ "We need mature OS before running the model"

**FALSE.** The model is designed to work with immature OS. Large SE handles uncertainty.

### ❌ "PFS-only would give same result"

**FALSE.** Including even immature OS:
- Provides independent information
- Prevents over-borrowing via correlation
- More conservative PoS estimates

---

## How to Interpret Results

### Posterior for θ_OS includes:

1. **Historical mean** (μ_OS from 27 trials)
2. **Current OS signal** (even if weak)
3. **PFS information** (via correlation ρ)

### PoS Calculation

```
PoS = P(θ_OS < target | all data)
```

Where "all data" = 27 historical trials + current PFS + current OS (immature)

---

## Sensitivity to OS Maturity

### Impact on PoS

| OS Events | SE_OS | Weight | PoS Impact |
|-----------|-------|--------|------------|
| 200 (mature) | 0.15 | High | ±10% points |
| 100 (moderate) | 0.20 | Medium | ±5% points |
| 50 (immature) | 0.30 | Low | ±2% points |
| 10 (very immature) | 0.60 | Very low | ±0.5% points |

**Interpretation:**
- Mature OS: Strong influence on PoS
- Immature OS: Modest influence, but still matters
- Very immature: Minimal direct influence, but prevents over-reliance on PFS

---

## Recommendations

### 1. **Always Include OS Data**

Even if immature:
- Set realistic SE based on number of events
- Let the model handle uncertainty
- Don't manually exclude it

### 2. **Use Appropriate SE**

For immature OS:
- SE ≈ sqrt(4/n_events) for log(HR)
- Example: 50 events → SE ≈ 0.28
- Example: 100 events → SE ≈ 0.20
- Don't artificially inflate or deflate SE

### 3. **Report Uncertainty**

In your PoS report:
- State: "Based on interim OS with X events"
- Note: "OS data immature, SE = Y"
- Explain: "Model appropriately weights all information"

### 4. **Sensitivity Analysis**

Run model with different OS scenarios:
- Pessimistic: OS worse than observed
- Optimistic: OS better than observed
- Compare PoS range

---

## Technical Details

### Multivariate Normal Likelihood

```stan
y_curr ~ multi_normal(theta_curr, W_curr);
```

Where:
```
y_curr = [log(HR)_OS, log(HR)_PFS]
theta_curr = [θ_OS, θ_PFS]
W_curr = [[SE²_OS, cov], [cov, SE²_PFS]]
```

**Key:** SE_OS enters the likelihood directly. Large SE → less influence automatically.

### Information Matrix

```
I(θ_OS) = W_curr^(-1)
```

As SE_OS increases (immature data), information decreases, weight decreases.

**Mathematical guarantee:** Bayesian inference optimally weights information!

---

## Summary

### ✅ YES, Current OS is Incorporated

1. **Through direct likelihood:** `y_curr ~ multi_normal(...)`
2. **With appropriate uncertainty:** Large SE for immature data
3. **Via hierarchical shrinkage:** Combined with historical data
4. **Weighted optimally:** Bayesian inference handles it

### Key Principle

**"Use all available data, weight by precision"**

Even immature OS provides information. Don't discard it – let the model weight it appropriately through the standard error!

---

## Questions?

See also:
- `UNDERSTANDING_CORRELATION.md` - How PFS and OS are linked via ρ
- `HOW_RHO_IS_ESTIMATED.md` - Why 27 historical trials are sufficient
- `FAQ_CORRELATION.md` - General FAQ on the model

For specific questions about your trial's OS maturity and its impact on PoS, please consult with your statistician!
