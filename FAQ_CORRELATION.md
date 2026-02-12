# FAQ: Between-Trial Correlation in Hierarchical Bayesian Models

## Quick Reference Guide

---

## Q1: Why is my estimated ρ (between-trial correlation) so low?

**A:** Low ρ is often **realistic and appropriate**! Here's why:

### Common Reasons for Low ρ:

1. **Different Patient Populations**
   - Trials recruit from different disease stages, prior treatments
   - Heterogeneous patient characteristics affect endpoints differently

2. **Post-Progression Treatments**
   - Patients may receive different subsequent therapies after progression
   - These affect OS but not PFS, breaking the correlation

3. **Biological Mechanisms**
   - PFS and OS may be driven by different mechanisms
   - Immunotherapy example: delayed OS benefit doesn't correlate with early PFS

4. **Trial Design Differences**
   - Different follow-up durations
   - Different endpoint measurement protocols
   - Different crossover rates

### Example:
```
Trial A: Good PFS (-0.50) + Good OS (-0.40) → Aligned
Trial B: Good PFS (-0.52) + Poor OS (-0.15) → Misaligned
Trial C: Poor PFS (-0.30) + Good OS (-0.38) → Misaligned

Result: Low correlation across trials (ρ ≈ 0.2)
Even though within each trial, PFS-OS correlation is high (0.7)
```

**Bottom Line:** Low ρ reflects reality, not a model failure!

---

## Q2: If ρ is low, what information can I still borrow from historical data?

**A:** **A LOT!** Even with ρ = 0, historical data provides substantial value:

### Information ALWAYS Borrowed (regardless of ρ):

#### 1. Population Mean Effects (μ_OS, μ_PFS)
- **What:** Average treatment effect across all historical trials
- **Value:** Provides baseline expectation for current trial
- **Impact:** Current trial estimate is shrunk toward population mean
- **Example:** 
  ```
  Historical: μ_OS = -0.30
  Current: OS = -0.50 ± 0.30 (uncertain)
  Posterior: OS ≈ -0.32 (shrunk toward -0.30)
  ```

#### 2. Between-Trial Heterogeneity (τ_OS, τ_PFS)
- **What:** How much trials vary around the population mean
- **Value:** Calibrates what's plausible vs extreme
- **Impact:** Controls amount of shrinkage
- **Example:**
  ```
  If τ_OS = 0.05 (low): Extreme results are downweighted
  If τ_OS = 0.20 (high): Extreme results are more plausible
  ```

#### 3. Hierarchical Shrinkage
- **What:** Partial pooling of information across trials
- **Value:** Prevents overfitting to noisy data
- **Impact:** More stable, realistic estimates
- **Example:**
  ```
  Without historical: OS = -0.35 ± 0.30 (wide, uncertain)
  With historical: OS = -0.32 ± 0.08 (narrower, more precise)
  ```

#### 4. Proper Uncertainty Quantification
- **What:** Realistic credible intervals
- **Value:** Accounts for both within-trial and between-trial uncertainty
- **Impact:** Better decision-making under uncertainty

### Information CONDITIONALLY Borrowed (only when ρ > 0):

#### 5. Cross-Endpoint Predictions
- **What:** Using PFS to predict OS
- **Value:** Strong PFS can boost OS predictions
- **Requires:** ρ > 0 (ideally ρ > 0.3 for meaningful borrowing)
- **Example:**
  ```
  With ρ = 0.0: Strong PFS (-0.60) → No impact on OS
  With ρ = 0.7: Strong PFS (-0.60) → Predicts better OS
  ```

---

## Q3: How much does ρ actually matter for PoS?

**A:** It matters for **cross-endpoint borrowing** but historical data helps regardless:

### Quantitative Example:

Setup:
- Historical: μ_OS = -0.30, τ_OS = 0.05
- Current trial: OS = -0.35 ± 0.25, PFS = -0.60 (strong!)
- Target: OS < -0.30

#### Scenario 1: ρ = 0 (No correlation)
```
Information borrowed:
  ✓ μ_OS = -0.30 (shrinkage target)
  ✓ τ_OS = 0.05 (calibrates uncertainty)
  ✓ Hierarchical structure
  ✗ PFS ignored for OS prediction

Result:
  Posterior OS: -0.32 ± 0.08
  PoS: 55%
  
Improvement over no historical data: +15 percentage points!
```

#### Scenario 2: ρ = 0.7 (Strong correlation)
```
Information borrowed:
  ✓ μ_OS = -0.30 (shrinkage target)
  ✓ τ_OS = 0.05 (calibrates uncertainty)
  ✓ Hierarchical structure
  ✓ PFS = -0.60 leveraged for OS

Result:
  Posterior OS: -0.37 ± 0.06
  PoS: 78%
  
Improvement over no historical data: +38 percentage points!
Additional benefit from ρ: +23 percentage points!
```

**Key Insight:** Even with ρ = 0, you get 15 points boost. With ρ = 0.7, you get an additional 23 points.

---

## Q4: When should I expect high vs low ρ?

**A:** Depends on your disease area and trial characteristics:

### Expect HIGH ρ (0.6-0.8):

✓ Well-characterized disease with validated surrogates
✓ Homogeneous patient populations across trials
✓ Similar trial designs and follow-up
✓ Short-term endpoints closely tied to long-term outcomes
✓ Minimal post-progression confounding

**Examples:** Solid tumor trials with established PFS-OS relationship, rare diseases with consistent populations

### Expect LOW ρ (0.1-0.3):

✓ Mature disease areas with varied populations
✓ Different post-progression treatments available
✓ Heterogeneous mechanisms of action
✓ Long follow-up with crossover
✓ Immuno-oncology (delayed effects)

**Examples:** NSCLC with multiple treatment lines, trials with different patient selection criteria

### Expect MODERATE ρ (0.3-0.6):

✓ Somewhat consistent patient populations
✓ Some but not complete treatment standardization
✓ Moderate biological correlation between endpoints

**Examples:** Most real-world scenarios fall here

---

## Q5: How do I interpret my results when ρ is low?

**A:** Focus on what you CAN rely on:

### With Low ρ (< 0.3):

✅ **Rely On:**
- Population mean (μ_OS) as strong prior
- Heterogeneity (τ_OS) for uncertainty calibration
- Hierarchical shrinkage for stability
- Direct OS evidence from current trial

❌ **Don't Rely On:**
- Using strong PFS to predict OS success
- Cross-endpoint optimism
- Surrogate endpoint substitution

### Practical Guidelines:

1. **PoS Calculation:**
   - Mainly driven by OS data itself
   - Historical μ_OS provides baseline
   - Need good OS data quality

2. **Sample Size:**
   - With low ρ, you need sufficient OS events
   - Cannot rely on early PFS for OS decisions
   - Plan for adequate OS maturity

3. **Interim Decisions:**
   - Strong PFS alone is insufficient for OS PoS
   - Need interim OS data or wait for maturity
   - Be conservative about cross-endpoint optimism

---

## Q6: Should I change my prior on ρ?

**A:** Depends on your knowledge and goals:

### Default Approach (Recommended):

```r
# Weakly informative prior
prior_rho_type = "uniform"  # Uniform(-0.95, 0.95)
```

**When:** You don't have strong prior beliefs about correlation
**Pro:** Let data determine ρ
**Con:** May need more data to estimate precisely

### Informative Approach:

```r
# If you have strong biological rationale
prior_rho_type = "lkj"
prior_rho_param = 2  # Mild regularization toward independence
```

**When:** You have prior evidence about correlation
**Pro:** More stable estimates with limited data
**Con:** May bias results if prior is wrong

### Sensitivity Analysis:

Always try different ρ priors and compare:
1. Uniform (flat)
2. LKJ with η = 1 (uniform over correlations)
3. LKJ with η = 2 (mild shrinkage toward 0)
4. LKJ with η = 4 (strong shrinkage toward 0)

If PoS conclusions are similar across priors → robust
If PoS changes dramatically → need more data or be cautious

---

## Q7: Can I increase ρ to get higher PoS?

**A:** **NO! This would be statistical malpractice.**

### Why Not:

❌ **Cherry-picking:** Choosing priors to get desired results
❌ **Bias:** Ignoring what the data actually shows
❌ **Misleading:** Overly optimistic PoS that doesn't reflect reality
❌ **Regulatory:** Unacceptable for submissions

### What You SHOULD Do:

✅ **Accept the data:** If ρ is low, that's what the data shows
✅ **Explain:** Document why low ρ makes scientific sense
✅ **Plan accordingly:** Need good OS data if ρ is low
✅ **Sensitivity:** Show PoS under different ρ assumptions as secondary

### Appropriate Use of Informative Priors:

✓ **OK:** Based on prior studies or meta-analyses
✓ **OK:** Biological mechanism justifies correlation
✓ **OK:** Sensitivity analysis to explore assumptions
✗ **NOT OK:** Tuning to achieve desired PoS
✗ **NOT OK:** Ignoring weak correlation in data

---

## Q8: Summary - Key Takeaways

### Main Points:

1. **Low ρ is often realistic** - not a model failure
2. **Historical data is valuable regardless of ρ** - provides μ, τ, shrinkage
3. **ρ controls cross-endpoint borrowing only** - one piece of information
4. **Even with ρ = 0, you get 15+ percentage points PoS boost** from hierarchical model
5. **Don't manipulate ρ** - let data determine it

### Decision Framework:

```
Is ρ < 0.3?
    ↓
   Yes → Low correlation scenario
    ├─ PoS driven mainly by OS data
    ├─ Still benefit from hierarchical structure
    ├─ Need adequate OS maturity
    └─ Be conservative about PFS-based optimism
    
   No (ρ ≥ 0.3) → Moderate/High correlation
    ├─ PoS benefits from cross-endpoint borrowing
    ├─ Strong PFS can boost OS predictions
    ├─ Earlier decisions may be possible
    └─ Validate correlation assumption
```

---

## Additional Resources:

📖 **[UNDERSTANDING_CORRELATION.md](UNDERSTANDING_CORRELATION.md)**
- Comprehensive technical explanation
- Mathematical details
- Multiple examples

🎨 **[VISUAL_GUIDE_CORRELATION.md](VISUAL_GUIDE_CORRELATION.md)**
- Diagrams and visualizations
- Step-by-step examples
- Decision trees

📊 **[FIX_SUMMARY.md](FIX_SUMMARY.md)**
- Historical context
- Data quality improvements
- Model validation

---

*Last updated: 2026-02-12*
