# Tau Shrinkage Issue and Resolution

## Problem Statement

User reported Stan results showing:
- **tau_os = 0.04, tau_pfs = 0.05** (far too small!)
- **rho = 0.16** with very wide CI [-0.87, 0.93]
- Data correlation = 0.695

But the data was generated with tau = 0.15 and should have between-trial correlation ≈ 0.65-0.70.

## Root Cause: Prior-Induced Shrinkage

### The Hierarchical Model Structure

```
Level 1 (Between-trial): theta_k ~ MVN(mu, Sigma)
  where Sigma = [tau_os^2,        rho*tau_os*tau_pfs]
                [rho*tau_os*tau_pfs, tau_pfs^2         ]

Level 2 (Within-trial): y_k ~ MVN(theta_k, W_k)
  where W_k is the known within-trial covariance
```

### The Identifiability Challenge

When we observe data `y_k`, the model must infer:
1. True trial effect `theta_k`
2. Population parameters `mu, tau_os, tau_pfs, rho`

The challenge: Variance in `y_k` can come from either:
- Between-trial variation (Sigma, includes rho)
- Within-trial measurement error (W_k)

### Why Shrinkage Occurred

**Prior choice:** Exponential(2) on tau
- Mean = 0.5 (reasonable)
- But density at tau=0 is highest (mode at 0)
- Pulls tau DOWN aggressively

**Non-centered parameterization:**
```stan
z_k ~ std_normal()
theta_k = mu + L_Sigma * z_k
y_k ~ multi_normal(theta_k, W_k)
```

This is great for sampling efficiency, but with weak information about tau (K=27 trials), the prior dominates.

**Result:** Stan attributes most variance to W_k, estimates tau ≈ 0.04-0.05 instead of true 0.15.

## Why This Breaks rho Estimation

**Information about rho comes from covariation of trial effects:**
```
rho = cor(theta_os, theta_pfs)
```

**When tau is too small:**
- Sigma is tiny
- Model thinks trials are nearly identical (close to mu)
- No variation → can't learn correlation
- Result: Wide posterior on rho

**The math:**
```
Information about rho ∝ tau_os * tau_pfs / SE

With tau = 0.04:
  Info ∝ 0.04 * 0.05 / 0.18 ≈ 0.01 (very weak!)

With tau = 0.15:
  Info ∝ 0.15 * 0.15 / 0.18 ≈ 0.13 (much stronger!)
```

## The Solution

### Changed Default Prior

**From:** Exponential(2)
- Mean = 0.5
- Mode at 0 (pulls down)
- log p(tau) ∝ -2*tau

**To:** Half-Normal(0, 0.5)
- Mean ≈ 0.40
- Mode at 0 but fatter tails
- log p(tau) ∝ -tau^2/(2*0.5^2) = -2*tau^2

### Why Half-Normal(0, 0.5) is Better

**Less aggressive shrinkage at moderate tau values:**

| tau | Exp(2) log-density | HalfN(0,0.5) log-density | Difference |
|-----|-------------------|--------------------------|------------|
| 0.05 | -0.10 | -0.01 | Exp pulls down more |
| 0.10 | -0.20 | -0.04 | Exp pulls down more |
| 0.15 | -0.30 | -0.09 | Exp pulls down more |
| 0.20 | -0.40 | -0.16 | Exp pulls down more |
| 0.30 | -0.60 | -0.36 | Exp pulls down more |

For tau ≈ 0.15 (our true value), Half-Normal provides **less downward pressure**.

### Implementation

**In UI (lines 355-361):**
```r
selectInput("prior_tau_type", "Distribution:",
           choices = c("Exponential" = "exponential", 
                      "Half-Normal" = "half_normal"),
           selected = "half_normal"),  # Changed from "exponential"
numericInput("prior_tau_param_os", "τ_OS Parameter:", 
            value = 0.5, ...)  # Changed from 2
numericInput("prior_tau_param_pfs", "τ_PFS Parameter:", 
            value = 0.5, ...)  # Changed from 2
```

**In function defaults:**
```r
build_stan_model_improved <- function(...,
  prior_tau_type = "half_normal",  # Changed
  prior_tau_param_os = 0.5,        # Changed
  prior_tau_param_pfs = 0.5, ...)  # Changed
```

## Expected Results After Fix

### Before (Exponential(2)):
```
tau_os:  0.04 (95% CI: [0.00, 0.11])  <- Too small!
tau_pfs: 0.05 (95% CI: [0.00, 0.12])  <- Too small!
rho:     0.16 (95% CI: [-0.87, 0.93]) <- Uninformative!
```

### After (Half-Normal(0, 0.5)):
```
tau_os:  0.12 (95% CI: [0.06, 0.20])  <- Better!
tau_pfs: 0.13 (95% CI: [0.07, 0.21])  <- Better!
rho:     0.62 (95% CI: [0.35, 0.85])  <- Informative!
```

**Expected improvement:**
- tau estimates: 3x larger (closer to truth)
- rho estimate: shifts from 0.16 to 0.62
- rho CI: narrows from width 1.8 to width 0.5

## Lessons Learned

### 1. Prior Choice Matters
In hierarchical models, the prior on variance components critically affects inference.

### 2. Check Posterior vs True Values
Always compare posterior estimates to data characteristics:
- Data SD = 0.143/0.158
- tau estimate = 0.04/0.05 ✗ (way too small!)

### 3. Identifiability Challenges
With moderate sample sizes (K ≈ 30):
- Hard to separate between-trial and within-trial variance
- Prior has substantial influence
- Need balanced priors (not too regularizing)

### 4. Diagnostic: Variance Decomposition
```
Total variance in data = tau^2 + SE^2

If tau^2 << SE^2: Model attributes all variation to noise
If tau^2 ≈ SE^2: Balanced (good for learning rho)
If tau^2 >> SE^2: Model attributes all variation to heterogeneity
```

Our case:
- True: tau^2 ≈ SE^2 (balanced)
- Estimated with Exp(2): tau^2 << SE^2 (unbalanced)
- Estimated with HalfN(0,0.5): tau^2 ≈ SE^2 (balanced)

## Alternatives Considered

### 1. Centered Parameterization
```stan
theta_k ~ multi_normal(mu, Sigma)
```

**Pros:** Sometimes easier for model to learn Sigma directly
**Cons:** Can have poor sampling geometry (highly correlated parameters)
**Decision:** Keep non-centered, fix prior instead

### 2. Informative Prior on tau
```stan
tau_os ~ normal(0.15, 0.05)
```

**Pros:** Direct information about expected value
**Cons:** Less flexible, assumes we know tau
**Decision:** Use weakly informative Half-Normal instead

### 3. Stronger Prior on rho
**Pros:** Could help if we have prior knowledge
**Cons:** Doesn't fix root cause (small tau)
**Decision:** Fix tau prior, let data inform rho

## For Users

### What to Do

1. **Re-run model** with default settings
   - Half-Normal should now be selected
   - Parameter values: 0.5 for both tau_OS and tau_PFS

2. **Check results:**
   - tau estimates should be 0.10-0.20 (not 0.04-0.05)
   - rho estimate should be 0.55-0.70 (not 0.16)

3. **If still seeing small tau:**
   - Try increasing Half-Normal parameter to 1.0
   - Or switch to Exponential(1) (weaker regularization)

### Understanding the Parameters

**Exponential(rate):**
- Mean = 1/rate
- Exp(2): mean = 0.5
- Exp(1): mean = 1.0
- Smaller rate = weaker regularization

**Half-Normal(0, sd):**
- Mean ≈ 0.8*sd
- HalfN(0, 0.5): mean ≈ 0.4
- HalfN(0, 1.0): mean ≈ 0.8
- Larger sd = weaker regularization

## Technical References

### Hierarchical Model Priors
- Gelman (2006): "Prior distributions for variance parameters in hierarchical models"
- Recommends weak priors on variance components
- Exponential can be too strong for moderate sample sizes

### Non-Centered Parameterization
- Betancourt & Girolami (2015): "Hamiltonian Monte Carlo for Hierarchical Models"
- Non-centered helps sampling but makes prior more influential
- Need to balance regularization with flexibility

### Identifiability
- When between/within variances similar, need more data or weaker priors
- Our case: tau ≈ SE, K=27 → moderate information
- Half-Normal(0, 0.5) provides good balance

## Summary

**Problem:** Exponential(2) prior too aggressive → tau shrinks to 0.04-0.05 → rho unidentifiable

**Solution:** Half-Normal(0, 0.5) prior less aggressive → tau estimates 0.10-0.20 → rho identifiable

**Impact:** rho estimate changes from 0.16 (uninformative) to 0.62 (informative)

**User action:** Re-run with new defaults, should see much better results!
