# Quick Guide: Choosing ρ Prior in the App

## TL;DR

**For typical oncology trials:** Use **Uniform(0, 0.95)** or **Beta(2, 1)**  
**For exploratory:** Use **Uniform(-0.95, 0.95)**

---

## Step-by-Step

### 1. Go to "Run Model" Tab

### 2. Find "Correlation" Section

### 3. Select Prior Distribution

#### Option A: Uniform(0, 0.95) - **RECOMMENDED for most cases**
- **When:** Confident ρ > 0 but uncertain about exact value
- **Why:** Simple, lets data determine magnitude
- **No extra parameters needed**

#### Option B: Beta(α, β) - **For specific prior beliefs**
- **When:** Want to encode strength of belief about ρ
- **Requires:** Two parameters (α and β)

**Quick parameter choices:**
```
Beta(2, 1): Weak bias toward high positive ρ (mean=0.67)
Beta(5, 1): Strong bias toward high positive ρ (mean=0.83)
Beta(2, 2): Bias toward moderate positive ρ (mean=0.50)
```

#### Option C: Uniform(-0.95, 0.95) - **Default**
- **When:** No assumptions, exploratory analysis
- **Why:** Completely uninformative

#### Option D: LKJ(η) - **Symmetric**
- **When:** Want regularization toward ρ=0
- **Note:** Allows negative ρ

---

## Decision Chart

```
Do you expect OS and PFS to be positively correlated?
│
├─ YES (typical in oncology)
│  │
│  ├─ How strong is your belief?
│  │  ├─ Weak → Uniform(0, 0.95)
│  │  ├─ Moderate → Beta(2, 1)
│  │  └─ Strong → Beta(5, 1)
│  │
│  └─ What ρ value do you expect?
│     ├─ High (0.7-0.9) → Beta(2, 1) or Beta(5, 1)
│     ├─ Moderate (0.4-0.6) → Beta(2, 2)
│     └─ Uncertain → Uniform(0, 0.95)
│
└─ NO or UNCERTAIN
   └─ Use Uniform(-0.95, 0.95)
```

---

## Examples

### Example 1: Lung Cancer Trial
**Context:** OS and PFS typically positively correlated in NSCLC  
**Choice:** Uniform(0, 0.95)  
**Why:** Positive expected, but let data determine strength

### Example 2: Novel Mechanism
**Context:** New drug, unclear if traditional correlation holds  
**Choice:** Uniform(-0.95, 0.95)  
**Why:** No assumptions, exploratory

### Example 3: Strong Meta-Analysis Evidence
**Context:** 10 prior trials show ρ ≈ 0.75 ± 0.10  
**Choice:** Beta(5, 1)  
**Why:** Strong evidence for high positive correlation

---

## What to Expect

### Impact on Results:

**With informative positive priors:**
- ρ estimates constrained to [0, 1] or [0, 0.95]
- Narrower credible intervals
- Slightly higher ρ if Beta with high α/β
- Faster MCMC convergence

**Change in PoS:**
- Typically **1-5 percentage points** when data informative
- Could be **5-15 points** with weak data or strong prior

**Example:**
```
Data suggests ρ ≈ 0.60

Prior: Uniform(-0.95, 0.95)  → ρ = 0.58 [0.30, 0.82]  → PoS = 72%
Prior: Uniform(0, 0.95)      → ρ = 0.61 [0.35, 0.85]  → PoS = 74%
Prior: Beta(2, 1)            → ρ = 0.63 [0.40, 0.82]  → PoS = 75%
Prior: Beta(5, 1)            → ρ = 0.68 [0.48, 0.85]  → PoS = 77%
```

---

## Common Mistakes

❌ **Using Beta(5,1) for exploratory analysis**
- Too strong, imposes prior belief without justification

❌ **Using Uniform(-0.95, 0.95) when ρ clearly positive**
- Wastes probability mass on negative values

❌ **Choosing Beta parameters randomly**
- Understand what they mean (see INFORMATIVE_RHO_PRIORS.md)

✅ **Do:** Start with Uniform(0, 0.95) for oncology, check sensitivity

---

## Sensitivity Analysis

**Always check sensitivity when PoS is near decision boundary:**

1. Run with Uniform(-0.95, 0.95)
2. Run with Uniform(0, 0.95)
3. Run with Beta(2, 1) if appropriate
4. Compare PoS estimates
5. Report range: "PoS = 72-77% across priors"

---

## In the App

**Location:** Run Model tab → Prior Specifications → Correlation section

**What you'll see:**
```
Distribution: [Dropdown menu]
  - Uniform(-0.95, 0.95)
  - Uniform(0, 0.95) - Positive Only  ← CHOOSE THIS for oncology
  - Beta(α, β) - Positive Only
  - LKJ

[If Beta selected:]
  Beta α Parameter: [input box]  ← Try 2 or 5
  Beta β Parameter: [input box]  ← Try 1 or 2
  
  Help text: Beta(2,1): weakly favors high positive correlation...
```

---

## Need More Detail?

📖 **Full Guide:** [INFORMATIVE_RHO_PRIORS.md](INFORMATIVE_RHO_PRIORS.md)
- Complete mathematical details
- All prior comparisons
- Extensive examples
- Impact analysis

---

## Summary Table

| Prior | Best For | ρ Support | Complexity |
|-------|----------|-----------|------------|
| Uniform(-0.95, 0.95) | Exploratory | [-0.95, 0.95] | Simple |
| **Uniform(0, 0.95)** | **Typical oncology** | **[0, 0.95]** | **Simple** |
| Beta(2, 1) | Weak positive belief | [0, 1] | Medium |
| Beta(5, 1) | Strong positive belief | [0, 1] | Medium |
| Beta(2, 2) | Moderate ρ expected | [0, 1] | Medium |
| LKJ(2) | Regularization to 0 | [-1, 1] | Simple |

**Recommendation for most users:** Uniform(0, 0.95) ✅
