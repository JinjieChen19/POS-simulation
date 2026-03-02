# Visual Mockup: Bayesian PoS Shiny Application UI

## Application Header
```
┌────────────────────────────────────────────────────────────────────────────┐
│ Bayesian PoS Simulation - Overall Survival                                 │
│ [Model Description] [Run Model] [Results] [Data] [Help]                    │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## Tab 1: Model Description

```
╔════════════════════════════════════════════════════════════════════════════╗
║                          Model Description                                  ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                             ║
║  Statistical Model Formulation                                              ║
║  ──────────────────────────────────────────────────────────────────────     ║
║                                                                             ║
║  Hierarchical Bayesian Model for OS and PFS                                 ║
║                                                                             ║
║  This application implements a full Bayesian model for Probability of       ║
║  Success (PoS) assessment using log-transformed hazard ratios...            ║
║                                                                             ║
║  Model Structure                                                            ║
║  ───────────────                                                            ║
║  y_k,j ~ N(θ_k,j, W_k,j)                                                    ║
║  θ_k ~ N(μ, Σ)                                                              ║
║                                                                             ║
║  Prior Specifications                                                       ║
║  ────────────────────                                                       ║
║  • Population means:                                                        ║
║    • μ_OS ~ N(-0.35, 1.0)                                                   ║
║    • μ_PFS ~ N(-0.45, 1.0)                                                  ║
║  • Between-trial heterogeneity:                                             ║
║    • τ_OS ~ Exp(2)                                                          ║
║    • τ_PFS ~ Exp(2)                                                         ║
║  • Correlation:                                                             ║
║    • ρ ~ Uniform(-0.95, 0.95)                                               ║
║                                                                             ║
║  Between-Trial Covariance Matrix                                            ║
║  ───────────────────────────────                                            ║
║  Σ = [τ²_OS           ρ·τ_OS·τ_PFS]                                         ║
║      [ρ·τ_OS·τ_PFS    τ²_PFS      ]                                         ║
║                                                                             ║
║  Non-Centered Parameterization                                              ║
║  ─────────────────────────────────                                          ║
║  θ_k = μ + L_Σ · z_k, where z_k ~ N(0, I)                                   ║
║                                                                             ║
╚════════════════════════════════════════════════════════════════════════════╝
```

---

## Tab 2: Run Model

```
╔════════════════════════════════════════════════════════════════════════════╗
║                              Run Model                                      ║
╠══════════════════════╦═════════════════════════════════════════════════════╣
║ Model Settings       ║  Model Execution                                    ║
║ ─────────────────    ║  ────────────────────────────────────────────────   ║
║                      ║                                                     ║
║ MCMC Iterations:     ║  ══════════════════════════════════════════════     ║
║ [4000        ]       ║  BAYESIAN PoS MODEL FOR OS USING LOG(HR)            ║
║                      ║  rstan with Non-Centered Parameterization           ║
║ Number of Chains:    ║  ══════════════════════════════════════════════     ║
║ [4           ]       ║                                                     ║
║ ────────────────     ║  Model settings:                                    ║
║                      ║    Iterations per chain: 4000                       ║
║ Current Trial Params ║    Warmup: 2000                                     ║
║ ─────────────────    ║    Sampling: 2000                                   ║
║                      ║    Chains: 4                                        ║
║ Interim log(HR) OS:  ║    Adapt delta: 0.99                                ║
║ [-0.35       ]       ║    Max treedepth: 12                                ║
║                      ║                                                     ║
║ SE log(HR) OS:       ║  Current trial parameters:                          ║
║ [0.25        ]       ║    OS log(HR): -0.35 ± SE: 0.25                     ║
║                      ║    PFS log(HR): -0.48 ± SE: 0.12                    ║
║ Interim log(HR) PFS: ║    Target log(HR): -0.30                            ║
║ [-0.48       ]       ║                                                     ║
║                      ║  MODEL EXECUTION COMPLETE                           ║
║ SE log(HR) PFS:      ║  Total posterior samples: 8000                      ║
║ [0.12        ]       ║  Navigate to 'Results' tab...                       ║
║                      ║                                                     ║
║ Target log(HR):      ║  ─────────────────────────────────────────────────  ║
║ [-0.30       ]       ║  MCMC Diagnostics                                   ║
║ ────────────────     ║  ─────────────────────────────────────────────────  ║
║                      ║                                                     ║
║ ┌──────────────────┐ ║  Inference for Stan model:                          ║
║ │  Run Stan Model  │ ║           mean   sd    2.5%   50%   97.5%  Rhat   ║
║ │      ▶ PLAY      │ ║  mu_os   -0.31  0.05  -0.41  -0.31  -0.22  1.00   ║
║ └──────────────────┘ ║  mu_pfs  -0.46  0.04  -0.54  -0.46  -0.38  1.00   ║
║                      ║  tau_os   0.08  0.03   0.04   0.08   0.15  1.00   ║
║ Note: Model execution║  tau_pfs  0.07  0.03   0.03   0.07   0.13  1.00   ║
║ may take several     ║  rho      0.71  0.09   0.51   0.72   0.86  1.00   ║
║ minutes...           ║  theta_os_post -0.34 0.23 -0.79 -0.34  0.11  1.00   ║
║                      ║                                                     ║
╚══════════════════════╩═════════════════════════════════════════════════════╝
```

---

## Tab 3: Results

```
╔════════════════════════════════════════════════════════════════════════════╗
║                            Posterior Results                                ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                             ║
║  ┌─────────────────────────────────┬─────────────────────────────────┐     ║
║  │ Posterior: OS log(HR)           │ Posterior: HR (Natural Scale)   │     ║
║  │                                 │                                 │     ║
║  │        ██████                   │           ████                  │     ║
║  │      ██████████                 │         ████████                │     ║
║  │    ██████████████               │       ██████████████            │     ║
║  │  ████████████████████           │     ██████████████████          │     ║
║  │ ████████████████████████        │   ████████████████████████      │     ║
║  │────|────────|────────|────      │─────|──────|──────|────         │     ║
║  │  -0.8    -0.4      0.0          │    0.5    1.0    1.5            │     ║
║  │       log(HR)                   │         HR                      │     ║
║  └─────────────────────────────────┴─────────────────────────────────┘     ║
║                                                                             ║
║  ┌─────────────────────────────────┬─────────────────────────────────┐     ║
║  │ Probability of Success          │ Population Parameters           │     ║
║  │                                 │                                 │     ║
║  │ PoS                    ████████ │ ρ         ███████               │     ║
║  │                        82.3%    │           0.71                  │     ║
║  │                                 │                                 │     ║
║  │ Very High (90%) ██████████      │ τ_PFS   ███                     │     ║
║  │                 90%             │         0.07                    │     ║
║  │                                 │                                 │     ║
║  │ High (70%)      ██████████      │ τ_OS    ████                    │     ║
║  │                 70%             │         0.08                    │     ║
║  │                                 │                                 │     ║
║  │ Moderate (50%)  ██████████      │ μ_PFS ███████████               │     ║
║  │                 50%             │       -0.46                     │     ║
║  │                                 │                                 │     ║
║  │                                 │ μ_OS  ████████                  │     ║
║  │                                 │       -0.31                     │     ║
║  └─────────────────────────────────┴─────────────────────────────────┘     ║
║                                                                             ║
║  Summary Statistics                                                         ║
║  ──────────────────────────────────────────────────────────────────────     ║
║  ════════════════════════════════════════════════════════════               ║
║  POSTERIOR SUMMARY                                                          ║
║  ════════════════════════════════════════════════════════════               ║
║                                                                             ║
║  POPULATION PARAMETERS:                                                     ║
║    μ_OS (mean log HR for OS):       -0.3089                                 ║
║    μ_PFS (mean log HR for PFS):     -0.4622                                 ║
║    τ_OS (between-trial SD):          0.0846                                 ║
║    τ_PFS (between-trial SD):         0.0712                                 ║
║    ρ (OS-PFS correlation):           0.7133                                 ║
║                                                                             ║
║  CURRENT TRIAL POSTERIOR:                                                   ║
║    E[θ_OS | data]:                  -0.3412                                 ║
║    95% Credible Interval:           [-0.7894, 0.1089]                       ║
║    Median (log HR):                 -0.3398                                 ║
║    HR scale - Mean:                  0.712                                  ║
║    HR scale - Median:                0.712                                  ║
║                                                                             ║
║  PROBABILITY OF SUCCESS:                                                    ║
║    Target log(HR):                  -0.3000                                 ║
║    Equivalent HR:                    0.741                                  ║
║    P(log(HR_OS) < target | data):    0.8234  (82.3%)                        ║
║                                                                             ║
║    PoS Assessment: ★★ HIGH - Trial likely to succeed                        ║
║                                                                             ║
║  ════════════════════════════════════════════════════════════               ║
║                                                                             ║
║  MCMC Trace Plots                                                           ║
║  ──────────────────────────────────────────────────────────────────────     ║
║  [Trace plots showing convergence across 4 chains for all parameters]       ║
║                                                                             ║
╚════════════════════════════════════════════════════════════════════════════╝
```

---

## Tab 4: Data

```
╔════════════════════════════════════════════════════════════════════════════╗
║                        Historical Trials Data                               ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                             ║
║  ┌──────────────────────────────────────────────────────────────────────┐  ║
║  │ trial_id      │ cancer_type │ n_patients │ loghr_os │ se_loghr_os  │  ║
║  ├───────────────┼─────────────┼────────────┼──────────┼──────────────┤  ║
║  │ ICB-HIST-01   │ Melanoma    │ 150        │ -0.280   │ 0.180        │  ║
║  │ ICB-HIST-02   │ NSCLC       │ 200        │ -0.240   │ 0.160        │  ║
║  │ ICB-HIST-03   │ Renal       │ 120        │ -0.350   │ 0.200        │  ║
║  │ ICB-HIST-04   │ HCC         │ 180        │ -0.260   │ 0.180        │  ║
║  │ ICB-HIST-05   │ Melanoma    │ 95         │ -0.380   │ 0.210        │  ║
║  │ ICB-HIST-06   │ NSCLC       │ 160        │ -0.320   │ 0.190        │  ║
║  │ ICB-HIST-07   │ Renal       │ 140        │ -0.360   │ 0.220        │  ║
║  │ ICB-HIST-08   │ HCC         │ 110        │ -0.200   │ 0.170        │  ║
║  │ ICB-HIST-09   │ Melanoma    │ 130        │ -0.310   │ 0.190        │  ║
║  │ ICB-HIST-10   │ NSCLC       │ 170        │ -0.290   │ 0.170        │  ║
║  └───────────────┴─────────────┴────────────┴──────────┴──────────────┘  ║
║                                                                             ║
║  Summary Statistics                                                         ║
║  ──────────────────────────────────────────────────────────────────────     ║
║  Historical Trials Summary                                                  ║
║  ════════════════════════════════════════════════════════════               ║
║                                                                             ║
║  Number of trials:  10                                                      ║
║  Cancer types:  Melanoma, NSCLC, Renal, HCC                                 ║
║                                                                             ║
║  OS log(HR) - Mean: -0.298  SD: 0.053                                       ║
║  PFS log(HR) - Mean: -0.453  SD: 0.062                                      ║
║  Correlation - Mean: 0.691                                                  ║
║                                                                             ║
╚════════════════════════════════════════════════════════════════════════════╝
```

---

## Tab 5: Help

```
╔════════════════════════════════════════════════════════════════════════════╗
║                             User Guide                                      ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                             ║
║  Getting Started                                                            ║
║  ───────────────                                                            ║
║  This Shiny application provides an interactive interface for running       ║
║  Bayesian Probability of Success (PoS) analysis for clinical trials...      ║
║                                                                             ║
║  How to Use                                                                 ║
║  ──────────                                                                 ║
║  1. Review the Model: Start with the 'Model Description' tab                ║
║  2. View Historical Data: Check the 'Data' tab                              ║
║  3. Set Parameters: Go to 'Run Model' and adjust settings                   ║
║  4. Execute Model: Click 'Run Stan Model'                                   ║
║  5. Review Results: Navigate to 'Results' for analysis                      ║
║                                                                             ║
║  Key Features                                                               ║
║  ────────────                                                               ║
║  • Non-centered parameterization: Improves MCMC convergence                 ║
║  • Adaptive MCMC: Uses adapt_delta = 0.99                                   ║
║  • Parallel processing: Auto-detects CPU cores                              ║
║  • Real-time diagnostics: R-hat and ESS monitoring                          ║
║                                                                             ║
║  Interpreting Results                                                       ║
║  ────────────────────                                                       ║
║  • PoS ≥ 0.90: ★★★ VERY HIGH - Trial very likely to succeed                ║
║  • PoS ≥ 0.70: ★★ HIGH - Trial likely to succeed                            ║
║  • PoS ≥ 0.50: ★ MODERATE - Trial may succeed                               ║
║  • PoS < 0.50: ✗ LOW - Trial unlikely to succeed                            ║
║                                                                             ║
║  Technical Notes                                                            ║
║  ───────────────                                                            ║
║  • Default: 4000 iterations (2000 warmup + 2000 sampling) × 4 chains        ║
║  • R-hat should be < 1.01 for convergence                                   ║
║  • ESS should be > 100 per chain                                            ║
║                                                                             ║
╚════════════════════════════════════════════════════════════════════════════╝
```

---

## Key UI Features Summary

1. **Navigation**: Clean tab-based navigation with 5 main sections
2. **Color Scheme**: Professional Flatly theme with traffic-light PoS indicators
3. **Interactive Inputs**: Numeric controls with sensible defaults and validation
4. **Real-time Feedback**: Progress bars and status messages during execution
5. **Rich Visualizations**: ggplot2-based plots with proper labeling
6. **Data Tables**: Interactive DT tables with pagination and sorting
7. **Comprehensive Help**: Built-in documentation and user guide
8. **Responsive Layout**: Adapts to different screen sizes
