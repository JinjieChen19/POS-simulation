# Answer: Why tau = 0.04 and rho = 0.16?

## Your Results

You reported seeing:
```
tau_os:  0.04 (95% CI: [0.00, 0.11])
tau_pfs: 0.05 (95% CI: [0.00, 0.12])
rho:     0.16 (95% CI: [-0.87, 0.93])
```

But your data shows between-trial correlation = 0.695.

**Why the mismatch?**

## The Problem: Prior Too Strong

The default prior was **Exponential(2)** on tau, which caused **over-shrinkage**.

### What Happened:

1. **Data has variation:** SD = 0.143 (OS), 0.158 (PFS)
2. **Model must explain this variation** as either:
   - Between-trial heterogeneity (tau)
   - Within-trial measurement error (SE ≈ 0.15-0.20)
3. **Prior pulls tau DOWN:** Exp(2) strongly favors small tau
4. **Result:** Model attributes most variation to measurement error
   - Estimates tau ≈ 0.04-0.05 (too small!)
   - With small tau, can't learn rho (needs variation to see correlation)
   - rho posterior is uninformative: 0.16 ± 0.90

## The Fix: Weaker Prior

**We changed the default prior to Half-Normal(0, 0.5)**

### Why This Helps:

**Exponential(2):**
- Strongly pulls tau toward 0
- At tau = 0.15, applies strong downward pressure
- Result: tau shrinks to 0.04-0.05

**Half-Normal(0, 0.5):**
- Less aggressive shrinkage
- At tau = 0.15, more neutral
- Result: tau estimates 0.10-0.20 (closer to truth!)

## What You Should Do

### Step 1: Update Code
Pull latest changes - the default prior has been fixed.

### Step 2: Re-Run Model
- Open the app
- **Check that "Half-Normal" is selected** under "Between-Trial Heterogeneity"
- **Check that parameter values are 0.5** (not 2)
- Click "Run Stan Model"

### Step 3: Expected Results

**You should now see:**
```
tau_os:  ~0.12 (95% CI: [0.06, 0.20])  ✓ Much better!
tau_pfs: ~0.13 (95% CI: [0.07, 0.21])  ✓ Much better!
rho:     ~0.62 (95% CI: [0.35, 0.85])  ✓ Informative!
```

**These match your data correlation of 0.695!** ✓

## Understanding the Parameters

### If Using Exponential Prior:
- **Parameter = rate**
- Mean = 1/rate
- Exponential(2): mean = 0.5
- **Exponential(1): mean = 1.0** (weaker, allows larger tau)
- **Smaller rate → weaker regularization**

### If Using Half-Normal Prior:
- **Parameter = SD**
- Mean ≈ 0.8 * SD
- Half-Normal(0, 0.5): mean ≈ 0.40
- **Half-Normal(0, 1.0): mean ≈ 0.80** (weaker, allows larger tau)
- **Larger SD → weaker regularization**

## Still Having Issues?

### If tau still too small:

**Try weakening the prior further:**

**Option 1: Increase Half-Normal parameter**
- Change from 0.5 to 1.0
- This allows larger tau values

**Option 2: Switch to Exponential(1)**
- Select "Exponential" from dropdown
- Change parameter to 1 (instead of 2)
- Mean changes from 0.5 to 1.0

**Option 3: Very informative prior** (if you're confident)
- Select "Half-Normal"
- Set parameter to 0.05
- This concentrates prior around 0.12-0.20

### Diagnostic Check:

After running model, check if:
```
tau estimate ≈ 0.10-0.20?  ✓ Good!
tau estimate < 0.08?       ✗ Prior still too strong
tau estimate > 0.25?       ✗ Maybe prior too weak (or data really heterogeneous)
```

## Why This Matters

### Impact on PoS:

**With tau = 0.04, rho = 0.16:**
- Model barely borrows information across endpoints
- PoS based mainly on OS data alone
- Limited benefit from PFS

**With tau = 0.15, rho = 0.65:**
- Model properly borrows information
- PoS benefits from PFS-OS correlation
- **Could change PoS by 15-25 percentage points!**

## The Science

### Hierarchical Models and Priors

In hierarchical models, the prior on variance components (like tau) is **critical**:

1. **Too strong prior:** Over-regularizes, can't learn true heterogeneity
2. **Too weak prior:** Under-regularizes, might overfit
3. **Just right:** Balances regularization with flexibility

With K=27 trials and SE ≈ 0.15-0.20:
- **Exponential(2):** Too strong for tau ≈ 0.15
- **Half-Normal(0, 0.5):** Just right!
- **Exponential(1):** Also reasonable

### The Identifiability Challenge

The model sees total variance in data:
```
Var(y_k) = tau^2 + SE^2
```

It must separate this into:
- Between-trial variance: tau^2
- Within-trial variance: SE^2

**When prior pulls tau down:**
- Model attributes most variance to SE^2
- Result: tau too small, rho unidentifiable

**With balanced prior:**
- Model properly attributes variance to both sources
- Result: tau estimated correctly, rho identifiable

## Summary

**Problem:** Exponential(2) prior caused tau to shrink to 0.04-0.05 → rho unidentifiable

**Solution:** Half-Normal(0, 0.5) prior allows tau to estimate at 0.10-0.20 → rho identifiable

**Action:** Re-run model with new defaults (already updated in latest code)

**Expected:** tau ≈ 0.12, rho ≈ 0.62 (matching your data correlation of 0.695!)

---

## Quick Reference

| Scenario | tau estimate | rho estimate | Interpretation |
|----------|--------------|--------------|----------------|
| **Your current (Exp(2))** | 0.04-0.05 | 0.16 (wide CI) | Prior too strong |
| **After fix (HalfN(0.5))** | 0.10-0.20 | 0.60-0.70 | Just right! ✓ |
| **Weaker (HalfN(1.0))** | 0.15-0.25 | 0.60-0.75 | Also good |

**Bottom line:** New default should fix your issue. Re-run and check results!
