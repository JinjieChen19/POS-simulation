# Understanding Between-Trial Correlation and Information Borrowing

## Introduction

This document explains the role of between-trial correlation (ρ) in hierarchical Bayesian models and clarifies what information can be borrowed from historical data, even when between-trial correlation is low.

---

## The Hierarchical Model Structure

Our Bayesian PoS model has a hierarchical structure:

```
Level 1: Population Distribution
   μ_OS, μ_PFS    (population means)
   τ_OS, τ_PFS    (between-trial heterogeneity)
   ρ              (between-trial correlation)

Level 2: Individual Trial Effects
   θ_k ~ N(μ, Σ)  where Σ depends on τ_OS, τ_PFS, ρ

Level 3: Observed Data
   y_k ~ N(θ_k, W_k)  where W_k is within-trial variance
```

---

## What is Between-Trial Correlation (ρ)?

**Between-trial correlation (ρ)** measures how trial-level deviations from the population mean correlate across endpoints.

### Example:
- Trial A has OS effect = -0.40 (better than average -0.30)
- Does Trial A also tend to have better-than-average PFS?
- If yes → positive ρ
- If no → ρ close to zero

### Important Distinction:

| Type | What It Measures | Where Used |
|------|------------------|------------|
| **Within-Trial Correlation** | How OS and PFS outcomes correlate *within a single study* | W_k matrices (data) |
| **Between-Trial Correlation (ρ)** | How trial-level effects correlate *across the population* | Σ matrix (model) |

**Key Insight:** These can be different! A patient-level correlation of 0.70 doesn't imply trial-level correlation is also 0.70.

---

## Why Might Between-Trial Correlation Be Low?

Even with high within-trial correlation, between-trial correlation can be low for several reasons:

### 1. **Different Trial Characteristics**
- Trials may differ in patient populations, disease severity, prior treatments
- A trial's PFS advantage might not translate to OS due to post-progression treatments
- Different follow-up durations affect endpoint measurement

### 2. **Biological Heterogeneity**
- The mechanism driving PFS benefit might differ from OS benefit
- Some tumors respond quickly (good PFS) but progress aggressively later (poor OS)
- Immune-oncology: delayed OS benefits might not correlate with early PFS

### 3. **Statistical Sampling**
- Trial-level effects include sampling variability
- Small trials add noise to the trial-level correlation
- True correlation might be moderate but estimated as low due to limited data

### 4. **Real-World Example**
Consider three immunotherapy trials:

```
Trial 1: Good PFS (-0.50), Good OS (-0.40)  → Consistent
Trial 2: Good PFS (-0.52), Poor OS (-0.15)  → Inconsistent
Trial 3: Poor PFS (-0.30), Good OS (-0.38)  → Inconsistent
```

Correlation across these three trials would be low, even if within each trial, PFS and OS are correlated.

---

## What Information Can Still Be Borrowed?

**Critical Point:** Even with low or zero between-trial correlation, the hierarchical model still borrows substantial information from historical data!

### 1. **Population Mean Effects (μ_OS, μ_PFS)**

**What is learned:**
- Average treatment effect across all trials
- Expected log(HR) for a "typical" trial

**Impact on current trial:**
- Shrinks current trial estimate toward population mean
- Stronger shrinkage when current trial has high uncertainty
- Works even with ρ = 0

**Example:**
```
Historical data: 27 trials, μ_OS = -0.30
Current trial: Interim OS = -0.50 ± SE = 0.30 (uncertain)

Even with ρ = 0:
- Posterior for current trial ≈ -0.35 (shrunk toward -0.30)
- Reduces uncertainty by borrowing strength from historical trials
```

### 2. **Between-Trial Heterogeneity (τ_OS, τ_PFS)**

**What is learned:**
- How much trials vary around the population mean
- Expected range of trial effects

**Impact on current trial:**
- Calibrates uncertainty about trial effects
- If τ_OS is small → current trial likely close to μ_OS
- If τ_OS is large → current trial could be far from μ_OS

**Example:**
```
If historical trials show τ_OS = 0.05 (low heterogeneity):
- Extreme results in current trial are downweighted
- Posterior is pulled toward population mean

If historical trials show τ_OS = 0.20 (high heterogeneity):
- Extreme results are more plausible
- Less shrinkage toward population mean
```

### 3. **Correlation Structure (ρ) - When Non-Zero**

**What is learned:**
- How much to leverage PFS to predict OS

**Impact on current trial:**
- With high ρ (0.7): Strong PFS strongly predicts good OS
- With low ρ (0.1): PFS provides little information about OS
- With ρ = 0: PFS provides NO cross-endpoint information

**Example with ρ = 0.7:**
```
Current trial: PFS = -0.60 (very strong)
Historical: μ_OS = -0.30, μ_PFS = -0.45, ρ = 0.7

Prediction: OS likely better than average
- Strong PFS suggests trial is above-average
- High correlation means OS likely above-average too
- Posterior OS might be -0.38 (better than μ_OS = -0.30)
```

**Example with ρ = 0.1:**
```
Same current trial: PFS = -0.60 (very strong)
Historical: μ_OS = -0.30, μ_PFS = -0.45, ρ = 0.1

Prediction: OS close to average
- Strong PFS suggests trial is above-average on PFS
- Low correlation means minimal info about OS
- Posterior OS might be -0.31 (close to μ_OS = -0.30)
```

---

## Information Borrowing Summary Table

| ρ Value | Information from Historical Data | Impact on Current Trial |
|---------|-----------------------------------|------------------------|
| **ρ = 0** | • Population means (μ_OS, μ_PFS)<br>• Heterogeneity (τ_OS, τ_PFS)<br>• Number of trials (shrinkage strength) | • Shrinkage toward μ_OS based on uncertainty<br>• NO cross-endpoint borrowing<br>• PFS doesn't inform OS |
| **ρ = 0.3** | Same as above PLUS:<br>• Weak cross-endpoint pattern | • Weak cross-endpoint borrowing<br>• Strong PFS → slightly better OS prediction |
| **ρ = 0.7** | Same as above PLUS:<br>• Strong cross-endpoint pattern | • Strong cross-endpoint borrowing<br>• Strong PFS → much better OS prediction |

---

## Quantitative Example: PoS with Different ρ

Consider a current trial with:
- Interim PFS: -0.50 (SE = 0.12)
- Interim OS: -0.35 (SE = 0.25)
- Target OS: -0.30
- Historical data: μ_OS = -0.30, μ_PFS = -0.45, τ_OS = 0.05, τ_PFS = 0.06

### Scenario 1: ρ = 0 (No correlation)

**Information borrowed:**
- OS pulled toward μ_OS = -0.30
- Uncertainty reduced by historical τ_OS = 0.05
- PFS data ignored for OS prediction

**Result:**
- Posterior OS ≈ -0.32 (slight improvement from shrinkage)
- PoS ≈ 55% (modest)

### Scenario 2: ρ = 0.7 (Strong correlation)

**Information borrowed:**
- OS pulled toward μ_OS = -0.30
- Uncertainty reduced by historical τ_OS = 0.05
- **Strong PFS (-0.50) suggests trial is above-average**
- **High ρ means OS likely above-average too**

**Result:**
- Posterior OS ≈ -0.37 (leverages strong PFS)
- PoS ≈ 78% (much higher!)

**Difference:**
- 23 percentage point increase in PoS
- Entirely due to leveraging PFS information via correlation

---

## Practical Implications

### When ρ is Low (e.g., 0.1-0.3)

**Good News:**
1. ✅ Still borrow population-level information (μ, τ)
2. ✅ Still reduce uncertainty via hierarchical shrinkage
3. ✅ Still benefit from multiple historical trials
4. ✅ Robust to endpoint-specific surprises

**Limitation:**
1. ❌ Cannot leverage strong PFS for OS predictions
2. ❌ PoS relies mainly on OS data itself
3. ❌ Need good OS data quality for reliable PoS

**When to expect low ρ:**
- Mature disease areas with varied patient populations
- Different post-progression treatments across trials
- Heterogeneous mechanisms of action
- Long follow-up with crossover/subsequent therapies

### When ρ is High (e.g., 0.6-0.8)

**Good News:**
1. ✅ All benefits of hierarchical model
2. ✅ **Plus** strong cross-endpoint borrowing
3. ✅ Early PFS data informs OS predictions
4. ✅ Higher PoS with strong surrogate endpoints

**Risk:**
1. ⚠️ Over-optimistic if correlation breaks down
2. ⚠️ Misleading if PFS not validated as surrogate

**When to expect high ρ:**
- Well-characterized disease with established PFS-OS relationship
- Similar patient populations across trials
- Short-term endpoints closely tied to long-term outcomes
- Minimal post-progression confounding

---

## Model Behavior Demonstration

### The Hierarchical Shrinkage Effect

Even with ρ = 0, historical data helps:

```
Historical: 27 trials inform μ_OS = -0.30, τ_OS = 0.05

Current trial (weak data): OS = -0.50 ± SE = 0.40
→ Posterior OS ≈ -0.32 (heavily shrunk toward -0.30)
→ Why? High uncertainty in current trial, low τ_OS in historical

Current trial (strong data): OS = -0.50 ± SE = 0.10  
→ Posterior OS ≈ -0.48 (minimal shrinkage)
→ Why? Low uncertainty in current trial dominates
```

### The Cross-Endpoint Borrowing Effect

Only active when ρ ≠ 0:

```
With ρ = 0.7 and strong PFS = -0.60:

If current OS = -0.20 (weak):
→ Posterior OS ≈ -0.28 (improved by leveraging PFS)

If current OS = -0.40 (strong):
→ Posterior OS ≈ -0.39 (confirmed by PFS agreement)
```

---

## Recommendations for Users

### 1. **Understand Your Context**
- Is there biological rationale for PFS-OS correlation?
- Do historical trials show consistent patterns?
- Are patient populations similar across trials?

### 2. **Use Appropriate Priors**
- If uncertain about ρ, use weakly informative prior (Uniform or LKJ with η=2)
- If strong evidence for correlation, use informative prior
- Sensitivity analysis: try different ρ values

### 3. **Interpret Results Carefully**
- With low ρ: PoS mainly driven by OS data, be cautious about PFS-based optimism
- With high ρ: Strong PFS can boost PoS, but validate the correlation assumption
- Check posterior ρ estimates to see what data supports

### 4. **Value Historical Data Regardless**
- Even with ρ = 0, historical data provides:
  - Calibrated expectations (μ)
  - Realistic variability (τ)
  - Proper uncertainty quantification
- This alone makes the hierarchical model valuable

---

## Summary

**Key Takeaway:** Between-trial correlation (ρ) controls **cross-endpoint information borrowing**, but even with ρ = 0, historical data provides substantial value through:

1. **Population-level information** (μ_OS, μ_PFS)
2. **Heterogeneity calibration** (τ_OS, τ_PFS)
3. **Hierarchical shrinkage** (reducing overfitting)
4. **Uncertainty quantification** (realistic credible intervals)

**Low ρ doesn't mean historical data is useless** - it just means we can't leverage PFS to predict OS. The hierarchical structure still provides robust statistical framework for borrowing strength across trials.

**The model is working correctly** when it estimates low ρ from data showing weak trial-level correlation - this is the model being appropriately conservative and data-driven.

---

## References and Further Reading

1. **Hierarchical Models:** Gelman & Hill (2006), "Data Analysis Using Regression and Multilevel/Hierarchical Models"
2. **Borrowing Strength:** Greenland (2000), "Principles of multilevel modelling"
3. **Surrogate Endpoints:** Buyse et al. (2000), "The validation of surrogate endpoints in meta-analyses of randomized experiments"
4. **Between-Study Heterogeneity:** Higgins & Thompson (2002), "Quantifying heterogeneity in a meta-analysis"

---

*Document created: 2026-02-12*
*Context: Bayesian PoS Simulation Application*
