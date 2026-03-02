# Visual Guide: Between-Trial Correlation and Information Borrowing

## Conceptual Diagrams

### Diagram 1: Two Types of Correlation

```
┌─────────────────────────────────────────────────────────────────────┐
│                    WITHIN-TRIAL CORRELATION                         │
│                                                                     │
│   Within a single trial, patient outcomes for OS and PFS          │
│   are correlated (typically 0.60-0.75)                            │
│                                                                     │
│   Trial A patients:                                                │
│   ┌─────────┐        ┌─────────┐                                 │
│   │ PFS ──────────────► OS     │                                 │
│   │ Good    │  0.70  │ Good    │                                 │
│   └─────────┘        └─────────┘                                 │
│                                                                     │
│   This goes in W_k (within-trial covariance matrix)               │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                   BETWEEN-TRIAL CORRELATION (ρ)                      │
│                                                                     │
│   Across trials, do trial-level effects correlate?                 │
│                                                                     │
│   Trial A: PFS effect = -0.50 (good) → OS effect = ?               │
│   Trial B: PFS effect = -0.30 (poor) → OS effect = ?               │
│                                                                     │
│   High ρ (0.7):                    Low ρ (0.1):                    │
│   ┌──────────┐                     ┌──────────┐                   │
│   │ Trial A  │ PFS good            │ Trial A  │ PFS good          │
│   │ Effect   │ ──► OS good         │ Effect   │ ──X OS ???        │
│   └──────────┘                     └──────────┘                   │
│                                                                     │
│   ┌──────────┐                     ┌──────────┐                   │
│   │ Trial B  │ PFS poor            │ Trial B  │ PFS poor          │
│   │ Effect   │ ──► OS poor         │ Effect   │ ──X OS ???        │
│   └──────────┘                     └──────────┘                   │
│                                                                     │
│   This is ρ in Σ (between-trial covariance matrix)                │
└─────────────────────────────────────────────────────────────────────┘
```

---

### Diagram 2: Hierarchical Model Structure

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        HIERARCHICAL MODEL                                │
│                                                                          │
│  Level 1: POPULATION PARAMETERS (what we learn from ALL historical)     │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │  μ_OS = -0.30    μ_PFS = -0.45    (population means)              │ │
│  │  τ_OS = 0.05     τ_PFS = 0.06     (heterogeneity)                 │ │
│  │  ρ = 0.65                          (between-trial correlation)    │ │
│  │                                                                    │ │
│  │  These are learned from 27 historical trials                      │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                              ↓                                           │
│  Level 2: TRIAL-SPECIFIC EFFECTS (each trial has its own θ)             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │
│  │  Trial 1     │  │  Trial 2     │  │  Current     │                  │
│  │  θ_OS = -0.28│  │  θ_OS = -0.35│  │  θ_OS = ???  │                  │
│  │  θ_PFS= -0.42│  │  θ_PFS= -0.51│  │  θ_PFS= -0.50│                  │
│  └──────────────┘  └──────────────┘  └──────────────┘                  │
│         ↓                  ↓                  ↓                          │
│  Level 3: OBSERVED DATA (what we actually measure)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │
│  │  y_OS ± SE   │  │  y_OS ± SE   │  │  y_OS ± SE   │                  │
│  │  y_PFS ± SE  │  │  y_PFS ± SE  │  │  y_PFS ± SE  │                  │
│  └──────────────┘  └──────────────┘  └──────────────┘                  │
└──────────────────────────────────────────────────────────────────────────┘
```

---

### Diagram 3: Information Flow with Different ρ Values

#### Scenario A: High Correlation (ρ = 0.7)

```
Historical Data (27 trials)
    ↓
┌─────────────────────────────────────────┐
│  Learn Population Parameters:           │
│  • μ_OS = -0.30                         │
│  • μ_PFS = -0.45                        │
│  • τ_OS = 0.05, τ_PFS = 0.06           │
│  • ρ = 0.7  ←── STRONG CORRELATION     │
└─────────────────────────────────────────┘
            ↓
┌─────────────────────────────────────────┐
│  Current Trial:                         │
│  • PFS = -0.60 (very strong!)          │
│  • OS = -0.35 ± 0.25 (uncertain)       │
└─────────────────────────────────────────┘
            ↓
┌─────────────────────────────────────────────────────┐
│  Information Borrowing:                             │
│                                                     │
│  1. Direct shrinkage:                               │
│     OS → toward μ_OS = -0.30                       │
│     ✓ Reduces uncertainty                          │
│                                                     │
│  2. Cross-endpoint borrowing:                       │
│     PFS = -0.60 is much better than μ_PFS = -0.45 │
│     High ρ = 0.7 means OS likely better too        │
│     ✓ OS prediction boosted                        │
│                                                     │
│  Combined Effect:                                   │
│  Posterior OS ≈ -0.38                              │
│  (Better than both -0.35 and -0.30!)              │
│                                                     │
│  PoS ≈ 75% ★★ HIGH                                 │
└─────────────────────────────────────────────────────┘
```

#### Scenario B: Low Correlation (ρ = 0.1)

```
Historical Data (27 trials)
    ↓
┌─────────────────────────────────────────┐
│  Learn Population Parameters:           │
│  • μ_OS = -0.30                         │
│  • μ_PFS = -0.45                        │
│  • τ_OS = 0.05, τ_PFS = 0.06           │
│  • ρ = 0.1  ←── WEAK CORRELATION       │
└─────────────────────────────────────────┘
            ↓
┌─────────────────────────────────────────┐
│  Current Trial:                         │
│  • PFS = -0.60 (very strong!)          │
│  • OS = -0.35 ± 0.25 (uncertain)       │
└─────────────────────────────────────────┘
            ↓
┌─────────────────────────────────────────────────────┐
│  Information Borrowing:                             │
│                                                     │
│  1. Direct shrinkage:                               │
│     OS → toward μ_OS = -0.30                       │
│     ✓ Reduces uncertainty                          │
│                                                     │
│  2. Cross-endpoint borrowing:                       │
│     PFS = -0.60 is much better than μ_PFS = -0.45 │
│     Low ρ = 0.1 means OS info is minimal           │
│     ✗ OS prediction barely affected                │
│                                                     │
│  Combined Effect:                                   │
│  Posterior OS ≈ -0.32                              │
│  (Mainly shrunk toward μ_OS = -0.30)              │
│                                                     │
│  PoS ≈ 58% ★ MODERATE                              │
└─────────────────────────────────────────────────────┘
```

**Key Difference:** 17 percentage points in PoS, entirely due to ρ!

---

### Diagram 4: What Gets Borrowed (Always vs. Conditionally)

```
╔══════════════════════════════════════════════════════════════════╗
║             INFORMATION BORROWED FROM HISTORICAL DATA            ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  ALWAYS BORROWED (regardless of ρ):                             ║
║  ════════════════════════════════════════                        ║
║                                                                  ║
║  ✓ Population Mean (μ_OS)                                       ║
║    ├─► Provides baseline expectation                            ║
║    ├─► Current trial shrunk toward this                         ║
║    └─► Stronger shrinkage with uncertain current data           ║
║                                                                  ║
║  ✓ Between-Trial Heterogeneity (τ_OS)                           ║
║    ├─► Shows how much trials vary                               ║
║    ├─► Calibrates plausibility of extreme results               ║
║    └─► Affects amount of shrinkage                              ║
║                                                                  ║
║  ✓ Number of Historical Trials (N = 27)                         ║
║    ├─► More trials = more precise μ_OS estimate                 ║
║    ├─► More trials = stronger shrinkage                         ║
║    └─► Reduces posterior uncertainty                            ║
║                                                                  ║
║  ✓ Hierarchical Structure                                       ║
║    ├─► Partial pooling (borrows strength)                       ║
║    ├─► Prevents overfitting                                     ║
║    └─► Realistic uncertainty quantification                     ║
║                                                                  ║
║  CONDITIONALLY BORROWED (depends on ρ):                          ║
║  ════════════════════════════════════════                        ║
║                                                                  ║
║  ✓ Cross-Endpoint Information (PFS → OS)                        ║
║    ├─► Only active when ρ ≠ 0                                   ║
║    ├─► Strength proportional to |ρ|                             ║
║    └─► Allows PFS to inform OS predictions                      ║
║                                                                  ║
║  Examples:                                                       ║
║  • ρ = 0.0: PFS provides ZERO info about OS                     ║
║  • ρ = 0.3: PFS provides WEAK info about OS                     ║
║  • ρ = 0.7: PFS provides STRONG info about OS                   ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

### Diagram 5: Shrinkage Effect (Visual)

```
Without Historical Data:
─────────────────────────
Current Trial Estimate: -0.35 ± 0.25

  -0.8        -0.6        -0.4        -0.2         0.0
    |           |           |           |           |
    |           |     ████████████      |           |
    |           |  ████████████████████ |           |
    |           |████████████████████████           |
    |           |     ████████████      |           |
    |           |           ↑           |           |
    |           |         -0.35         |           |

Very wide, uncertain distribution


With Historical Data (ρ = 0):
─────────────────────────────
Posterior: -0.32 (shrunk toward μ_OS = -0.30)

  -0.8        -0.6        -0.4        -0.2         0.0
    |           |           |           |           |
    |           |           |  ████     |           |
    |           |           | ██████    |           |
    |           |           | ███████   |           |
    |           |           |  ████     |           |
    |           |           |   ↑       |           |
    |           |           | -0.32     |           |
                                ↑
                          (near μ_OS=-0.30)

Narrower, more precise - even with ρ = 0!


With Historical Data (ρ = 0.7) + Strong PFS:
─────────────────────────────────────────────
Posterior: -0.38 (leverages PFS info)

  -0.8        -0.6        -0.4        -0.2         0.0
    |           |           |           |           |
    |           |           |  ████     |           |
    |           |           |██████     |           |
    |           |           |███████    |           |
    |           |           |  ████     |           |
    |           |           |     ↑     |           |
    |           |           |   -0.38   |           |
                                   ↑
                          (boosted by strong PFS)

Even narrower, shifted favorably!
```

---

### Diagram 6: Decision Tree for Interpreting ρ

```
                    Estimate ρ from Model
                            │
                            ↓
                ┌───────────┴───────────┐
                │                       │
            ρ < 0.3                ρ ≥ 0.3
         (Low/Weak)              (Moderate/Strong)
                │                       │
                ↓                       ↓
        ┌───────────────┐       ┌───────────────┐
        │ Interpretation│       │ Interpretation│
        ├───────────────┤       ├───────────────┤
        │ • Trials show │       │ • Trials show │
        │   independent │       │   correlated  │
        │   effects     │       │   effects     │
        │               │       │               │
        │ • PFS doesn't │       │ • PFS informs │
        │   predict OS  │       │   OS outcomes │
        │               │       │               │
        │ • Still borrow│       │ • Strong info │
        │   μ, τ info   │       │   borrowing   │
        └───────────────┘       └───────────────┘
                │                       │
                ↓                       ↓
        ┌───────────────┐       ┌───────────────┐
        │ Implications  │       │ Implications  │
        ├───────────────┤       ├───────────────┤
        │ PoS relies on:│       │ PoS benefits  │
        │ • Direct OS   │       │   from:       │
        │   evidence    │       │ • OS evidence │
        │ • Population  │       │ • PFS evidence│
        │   μ_OS        │       │ • Population  │
        │               │       │   parameters  │
        │ • Limited PFS │       │               │
        │   leverage    │       │ Higher PoS if │
        └───────────────┘       │ PFS is strong │
                                └───────────────┘
```

---

## Numerical Examples

### Example 1: Impact of ρ on Posterior Predictions

```
Setup:
  Historical: μ_OS = -0.30, μ_PFS = -0.45, τ_OS = 0.05, τ_PFS = 0.06
  Current:    PFS = -0.60 (strong!), OS = -0.25 ± 0.30 (weak)

┌────────┬──────────────────┬──────────────────┬──────────────────┐
│   ρ    │  Posterior OS    │  Posterior SD    │       PoS        │
├────────┼──────────────────┼──────────────────┼──────────────────┤
│  0.0   │     -0.28        │      0.08        │       48%        │
│  0.3   │     -0.31        │      0.07        │       62%        │
│  0.5   │     -0.34        │      0.07        │       74%        │
│  0.7   │     -0.37        │      0.06        │       85%        │
└────────┴──────────────────┴──────────────────┴──────────────────┘

Notice:
  • As ρ increases, posterior OS gets more negative (better)
  • Strong PFS is leveraged more with higher ρ
  • PoS increases from 48% to 85% as ρ goes from 0 to 0.7
  • Even at ρ=0, we get shrinkage benefit (SD reduced from 0.30 to 0.08)
```

### Example 2: What Happens Without Historical Data

```
Without Hierarchical Model (no historical data):
  Posterior OS = Current OS = -0.25 ± 0.30
  PoS ≈ 40%
  
With Historical Data (ρ = 0):
  Posterior OS = -0.28 ± 0.08 (shrunk toward μ_OS)
  PoS ≈ 48%
  Improvement: 8 percentage points from hierarchical model alone!

With Historical Data (ρ = 0.7):
  Posterior OS = -0.37 ± 0.06 (shrunk + PFS leverage)
  PoS ≈ 85%
  Improvement: 45 percentage points from hierarchical + correlation!
```

---

## Key Takeaways (Visual Summary)

```
┌──────────────────────────────────────────────────────────────────┐
│                      MAIN INSIGHTS                               │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. ρ controls CROSS-ENDPOINT borrowing only                    │
│     • High ρ → use PFS to predict OS                            │
│     • Low ρ → PFS doesn't help predict OS                       │
│                                                                  │
│  2. Historical data ALWAYS provides value via:                  │
│     • Population means (μ)                                      │
│     • Heterogeneity calibration (τ)                             │
│     • Hierarchical shrinkage (partial pooling)                  │
│                                                                  │
│  3. Low ρ is NOT a failure - it's reality!                      │
│     • Model correctly learns from data                          │
│     • Conservative about cross-endpoint predictions             │
│     • Still borrows substantial information                     │
│                                                                  │
│  4. Value of historical data is cumulative:                     │
│     • 27 trials >> 10 trials (more precise μ, τ)               │
│     • More data → stronger shrinkage → better PoS              │
│     • Works regardless of ρ value                               │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

*Visual Guide created: 2026-02-12*
*Companion to: UNDERSTANDING_CORRELATION.md*
