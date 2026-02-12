# Informative Priors for ρ (Between-Trial Correlation)

## Overview

This document explains the new **informative positive priors** for the between-trial correlation parameter ρ, added in response to the observation that the default Uniform(-0.95, 0.95) prior may be too wide when there is strong belief that OS and PFS are positively correlated.

---

## Why Informative Priors for ρ?

### The Issue with Uniform(-0.95, 0.95)

**Default prior:** ρ ~ Uniform(-0.95, 0.95)
- Allows both positive and negative correlations equally
- In oncology, OS and PFS are typically **positively correlated**
- Including negative values wastes prior probability mass
- Can lead to slower convergence and wider posteriors

### When to Use Informative Priors

Use informative positive priors when:
1. **Domain knowledge:** OS and PFS expected to be positively correlated
2. **Oncology trials:** Nearly always positive correlation
3. **Prior data:** Historical evidence shows ρ > 0
4. **Efficiency:** Want faster convergence and narrower credible intervals

---

## Available Prior Options

### 1. Uniform(-0.95, 0.95) - **Default (Uninformative)**

```r
ρ ~ Uniform(-0.95, 0.95)
```

**When to use:**
- No strong prior belief about correlation direction
- Want to "let the data speak"
- Exploratory analysis

**Properties:**
- Equal probability for all correlations in range
- Uninformative (flat prior)
- May lead to wider posteriors

---

### 2. Uniform(0, 0.95) - **Positive Only**

```r
ρ ~ Uniform(0, 0.95)
```

**When to use:**
- Confident that ρ > 0 (typical in oncology)
- Want simple flat prior over positive correlations
- No preference among positive values

**Properties:**
- Constrains ρ to be positive
- Flat (equal weight to all positive values)
- More efficient than two-sided uniform

**Stan implementation:**
```stan
real<lower=0, upper=0.95> rho;
rho ~ uniform(0, 0.95);
```

---

### 3. Beta(α, β) - **Flexible Positive Prior**

```r
ρ ~ Beta(α, β)
```

**When to use:**
- Want to encode strength of belief in high/low positive correlation
- Have specific prior information about likely ρ value
- Want to influence estimation based on experience

**Properties:**
- Constrained to [0, 1]
- Shape controlled by α and β parameters
- Flexible: can encode weak to strong beliefs

#### Common Parameter Choices:

**Beta(2, 1) - Weakly favors high positive correlation**
- Mean: 0.67
- Mode: 1.0 (concentrates near perfect correlation)
- Use when: Expect strong positive correlation but data should dominate

**Beta(5, 1) - Strongly favors high positive correlation**
- Mean: 0.83
- Mode: 1.0
- More concentrated than Beta(2, 1)
- Use when: Very confident in strong positive correlation

**Beta(2, 2) - Favors moderate positive correlation**
- Mean: 0.50
- Mode: 0.50 (concentrates around moderate correlation)
- Use when: Expect moderate positive correlation

**Beta(1, 1) - Uniform(0, 1)**
- Equivalent to Uniform(0, 1)
- Flat prior over positive correlations

#### Stan implementation:
```stan
real<lower=0, upper=1> rho;
rho ~ beta(alpha, beta);
```

---

### 4. LKJ(η) - **Symmetric Around Zero**

```r
ρ ~ LKJ(η)
```

**When to use:**
- Want regularization toward independence (ρ = 0)
- No strong belief in positive vs negative
- Standard choice in multilevel models

**Properties:**
- η = 1: Uniform(-1, 1)
- η = 2: Mild concentration toward ρ = 0
- η > 2: Stronger concentration toward ρ = 0
- Symmetric (allows negative ρ)

**Note:** LKJ does NOT enforce positive correlation.

---

## Comparison of Priors

### Prior Densities at Key Values

| Prior | At ρ=0 | At ρ=0.5 | At ρ=0.9 | Support |
|-------|--------|----------|----------|---------|
| Uniform(-0.95, 0.95) | 0.526 | 0.526 | 0.526 | [-0.95, 0.95] |
| Uniform(0, 0.95) | 1.053 | 1.053 | 1.053 | [0, 0.95] |
| Beta(2, 1) | 0 | 1.0 | 1.8 | [0, 1] |
| Beta(5, 1) | 0 | 2.5 | 4.5 | [0, 1] |
| Beta(2, 2) | 0 | 1.5 | 0.9 | [0, 1] |

### Prior Means and Modes

| Prior | Mean | Mode | SD |
|-------|------|------|-----|
| Uniform(-0.95, 0.95) | 0 | - | 0.548 |
| Uniform(0, 0.95) | 0.475 | - | 0.274 |
| Beta(2, 1) | 0.667 | 1.0 | 0.236 |
| Beta(5, 1) | 0.833 | 1.0 | 0.152 |
| Beta(2, 2) | 0.500 | 0.5 | 0.224 |

---

## How to Choose Prior Parameters

### Decision Tree:

**1. Is correlation definitely positive?**
- Yes → Use positive-only prior (Uniform(0, 0.95) or Beta)
- No → Use Uniform(-0.95, 0.95) or LKJ

**2. How strong is your belief?**
- Weak → Use Uniform(0, 0.95)
- Moderate → Use Beta(2, 1) or Beta(2, 2)
- Strong → Use Beta(5, 1) or stronger

**3. What correlation value do you expect?**
- High (0.7-0.9) → Beta(2, 1) or Beta(5, 1)
- Moderate (0.4-0.6) → Beta(2, 2)
- Uncertain → Uniform(0, 0.95)

---

## Examples in Oncology

### Scenario 1: Typical Oncology Trial

**Setting:** OS and PFS in cancer trial, typical positive correlation expected

**Recommendation:** 
```r
Prior: Uniform(0, 0.95) or Beta(2, 1)
Rationale: Positive correlation expected but magnitude uncertain
```

**Expected impact:**
- Faster convergence
- Narrower credible intervals for ρ
- Similar PoS estimates if data strongly informative

---

### Scenario 2: Strong Prior Evidence

**Setting:** Meta-analysis shows ρ ≈ 0.70 ± 0.15 across similar trials

**Recommendation:**
```r
Prior: Beta(5, 1) 
Rationale: Strong evidence for high positive correlation
```

**Expected impact:**
- Posterior shrinks toward prior mean (0.83)
- More concentrated estimates
- Higher PoS if prior favors optimistic correlation

---

### Scenario 3: Exploratory Analysis

**Setting:** New disease area, correlation unknown

**Recommendation:**
```r
Prior: Uniform(-0.95, 0.95)
Rationale: Let data dominate, no prior assumptions
```

**Expected impact:**
- Wider credible intervals
- Data fully determines estimate
- More conservative approach

---

## Impact on PoS Estimation

### How Prior Affects PoS:

**Direct effect:**
- Stronger positive prior → higher ρ estimate (typically)
- Higher ρ → more borrowing from PFS to OS
- More borrowing → potentially higher PoS (if PFS favorable)

**Magnitude depends on:**
1. **Data informativeness:** With 27 trials, data usually dominates
2. **Prior strength:** Beta(5,1) has more influence than Uniform(0, 0.95)
3. **Consistency:** If data supports positive ρ, prior just narrows interval

### Example Impact:

**Scenario:** Data shows ρ ≈ 0.60, with moderate PFS results

| Prior | ρ posterior | PoS change |
|-------|-------------|------------|
| Uniform(-0.95, 0.95) | 0.58 [0.30, 0.82] | Baseline |
| Uniform(0, 0.95) | 0.61 [0.35, 0.85] | +1-2 points |
| Beta(2, 1) | 0.63 [0.40, 0.82] | +2-3 points |
| Beta(5, 1) | 0.68 [0.48, 0.85] | +3-5 points |

**Note:** Impact is modest when data is informative!

---

## Implementation in App

### UI Controls:

1. **Select prior distribution:**
   - Uniform(-0.95, 0.95)
   - **Uniform(0, 0.95) - Positive Only**
   - **Beta(α, β) - Positive Only**
   - LKJ

2. **For Beta prior, specify:**
   - α (alpha) parameter
   - β (beta) parameter
   - Help text shows recommended values

### Example Usage:

```r
# In UI
selectInput("prior_rho_type", "Distribution:",
           choices = c("Uniform(-0.95, 0.95)" = "uniform", 
                      "Uniform(0, 0.95) - Positive Only" = "uniform_positive",
                      "Beta(α, β) - Positive Only" = "beta",
                      "LKJ" = "lkj"))

# For Beta
conditionalPanel(
  condition = "input.prior_rho_type == 'beta'",
  numericInput("prior_rho_param", "Beta α:", value = 2),
  numericInput("prior_rho_param2", "Beta β:", value = 1)
)
```

---

## Recommendations

### General Guidance:

1. **Default for oncology:** Use Uniform(0, 0.95)
   - Simple, interpretable
   - Appropriate for most cases
   - Let data determine magnitude

2. **When prior information available:** Use Beta
   - Beta(2, 1): Weak positive bias
   - Beta(5, 1): Strong positive bias
   - Beta(2, 2): Moderate correlation expected

3. **For sensitivity analysis:**
   - Run model with different priors
   - Compare PoS estimates
   - Report sensitivity to prior choice

4. **Transparent reporting:**
   - Always document chosen prior
   - Justify based on domain knowledge
   - Show sensitivity if PoS near decision boundary

---

## References

- Gelman, A., et al. (2013). *Bayesian Data Analysis*, 3rd ed. Chapter on correlation priors.
- Stan Development Team. LKJ correlation distribution documentation.
- Oncology examples: Typical OS-PFS correlations in meta-analyses range 0.5-0.8.

---

## Summary

**Key Points:**

1. ✅ **New options available:** Uniform(0, 0.95) and Beta(α, β) for positive ρ
2. ✅ **Use when appropriate:** Oncology trials typically have positive correlation
3. ✅ **Choose strength carefully:** Balance prior belief with data informativeness
4. ✅ **Check sensitivity:** Compare results across different prior choices
5. ✅ **Document clearly:** Report prior choice and justification

**Bottom line:** For typical oncology trials where OS and PFS are expected to be positively correlated, using Uniform(0, 0.95) or Beta(2, 1) is recommended over the default Uniform(-0.95, 0.95).
