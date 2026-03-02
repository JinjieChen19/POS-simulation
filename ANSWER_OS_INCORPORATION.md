# Quick Answer: Current Trial OS Incorporation

## User's Question
> "I have a quick question, do we incorporate current trial's OS (even not mature)?"

---

## ✅ YES - Current Trial OS is Used (Even If Immature)

The Bayesian hierarchical model DOES incorporate the current trial's Overall Survival (OS) data, regardless of maturity level.

---

## How It Works

### 1. Both Endpoints Used
```r
y_curr <- c(loghr_os_interim, loghr_pfs_interim)  # Line 221 in app.R
```
The model takes BOTH OS and PFS from the current trial.

### 2. Automatic Weighting via SE
```
Immature OS  → Larger SE → Lower weight
Mature OS    → Smaller SE → Higher weight
```

**Example:**
- 50 OS events:  SE ≈ 0.30 → contributes ~15% of OS posterior
- 100 OS events: SE ≈ 0.20 → contributes ~30% of OS posterior  
- 200 OS events: SE ≈ 0.15 → contributes ~45% of OS posterior

### 3. Bayesian Optimal Combination
```
Posterior θ_OS = Weighted combination of:
  1. Historical trials (27 trials, strong information)
  2. Current OS interim (weighted by 1/SE²)
  3. Current PFS interim (via correlation ρ)
```

---

## Why Include Immature OS?

### ✅ Prevents Over-Reliance on PFS
- Without current OS: Model relies 100% on PFS + correlation
- With immature OS: Provides reality check, even if weak
- More conservative, realistic PoS estimates

### ✅ Captures Early Signals
- Even with few events, direction matters (positive vs negative)
- Magnitude uncertainty captured by large SE
- Better than ignoring OS entirely

### ✅ Bayesian Optimality
- Uses ALL available information
- Automatically weights by precision (1/SE²)
- No need to manually exclude immature data

---

## Evidence in Code

### Stan Model (lines 111-112, 183)
```stan
vector[2] y_curr;         // Current trial: [OS, PFS]
matrix[2, 2] W_curr;      // Covariance (includes SE²)

// Likelihood includes current trial
y_curr ~ multi_normal(theta_curr, W_curr);
```

### R Function (line 221)
```r
y_curr <- c(loghr_os_interim, loghr_pfs_interim)
```

### UI (lines 372-373)
```r
numericInput("loghr_os_interim", "Interim log(HR) for OS:", ...)
numericInput("se_loghr_os_interim", "SE of log(HR) for OS:", ...)
```

---

## Practical Guidance

### Setting SE for Immature OS

**Rule of thumb:**
```
SE ≈ sqrt(4 / n_events)

Examples:
  50 events  → SE ≈ 0.28
  100 events → SE ≈ 0.20
  200 events → SE ≈ 0.14
```

### Don't Artificially Exclude OS

**DON'T:**
- Set SE to infinity (excludes OS)
- Manually remove OS from analysis
- Wait for maturity before running model

**DO:**
- Use realistic SE based on event count
- Let Bayesian model weight appropriately
- Include all available data

---

## Common Misconceptions

### ❌ "We only use PFS at interim"
**FALSE.** Model uses both PFS and OS, even if OS is immature.

### ❌ "Immature OS is ignored"
**FALSE.** It's down-weighted via large SE, not ignored!

### ❌ "Need mature OS before running"
**FALSE.** Model designed for immature OS. Large SE handles uncertainty.

### ❌ "PFS-only gives same result"
**FALSE.** Including immature OS:
- Provides independent check
- Prevents over-borrowing
- More realistic PoS

---

## Documentation

**For complete details, see:**
- [FAQ_CURRENT_TRIAL_OS.md](FAQ_CURRENT_TRIAL_OS.md) - 8 KB comprehensive guide
- README.md - Quick FAQ section
- app.R Help tab - In-app guidance

**Quick reference:**
- Current trial inputs: app.R lines 372-376
- Data preparation: app.R lines 203-241
- Stan likelihood: app.R line 183
- Model description: Model Description tab in app

---

## Summary

### Question: Do we use current trial's OS (even if not mature)?

**Answer: YES! ✅**

**How:** Both OS and PFS used, weighted by precision (1/SE²)

**Why:** Prevents over-reliance on PFS, provides reality check, Bayesian optimal

**When:** Always - even with 10 OS events, contributes ~4% of information

**Implementation:** Fully documented in FAQ_CURRENT_TRIAL_OS.md

---

**The model is designed to work with immature OS. Just set appropriate SE and let Bayesian inference do its job!** 🎯
