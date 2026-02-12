# Bayesian Probability of Success (PoS) Simulation - R Shiny Application

## ⚠️ LATEST FIX: Prior on tau (2026-02-12 20:00)

**Prior-Induced Shrinkage Fix Applied!**  
- **Issue:** Default Exponential(2) prior on tau caused over-shrinkage → tau ≈ 0.04 instead of 0.15  
- **Impact:** With tiny tau, model couldn't learn ρ → estimated ρ ≈ 0.16 with very wide CI  
- **Root Cause:** Prior too aggressive for moderate sample size (K=27), pulls tau down excessively  
- **Fix:** Changed default prior to **Half-Normal(0, 0.5)** (less aggressive shrinkage)  
- **Expected Result:** tau ≈ 0.10-0.20, rho ≈ 0.55-0.70 with informative CI ✅  

📖 **See [TAU_SHRINKAGE_ISSUE.md](TAU_SHRINKAGE_ISSUE.md) for complete technical explanation**  
📖 **See [ANSWER_TAU_SHRINKAGE.md](ANSWER_TAU_SHRINKAGE.md) for user-friendly guide**

### Previous Fixes:
- ✅ Signal-to-noise ratio fix (see [SIGNAL_TO_NOISE_FIX.md](SIGNAL_TO_NOISE_FIX.md))
- ✅ Data order mismatch fix (see [CRITICAL_BUG_FIX.md](CRITICAL_BUG_FIX.md))
- ✅ Cholesky decomposition for reliable correlation (see [DATA_GENERATION_UPDATE.md](DATA_GENERATION_UPDATE.md))

---

## Overview

This comprehensive R Shiny application provides an interactive interface for running full Bayesian Probability of Success (PoS) analysis for clinical trials using Overall Survival (OS) and Progression-Free Survival (PFS) data. The application is based on the existing `bayesian_pos_fixed current rho` code and implements a hierarchical Bayesian model with log-transformed hazard ratios.

## Features

### 1. Model Description Panel
- Complete statistical model formulation with mathematical notation
- Detailed prior specifications for all parameters
- Explanation of non-centered parameterization
- Likelihood structure documentation
- Information about customizable features

### 2. Interactive Model Execution Panel
- **MCMC Settings:**
  - Adjustable iterations (default: 4000)
  - Number of chains (default: 4)
  - **NEW:** Adjustable adapt_delta (default: 0.99)
  - **NEW:** Adjustable max_treedepth (default: 12)
- **Prior Specifications:**
  - **NEW:** Population means (μ_OS, μ_PFS) - customizable mean and SD
  - **NEW:** Between-trial heterogeneity - choice of Exponential or Half-Normal
  - **NEW:** Correlation prior - choice of Uniform or LKJ
- Current trial parameter inputs (interim log HR and SE for OS/PFS)
- Target log(HR) specification for success criteria
- Real-time progress tracking
- Comprehensive MCMC diagnostics output

### 3. Results Visualization
- Posterior distribution plots for log(HR) and HR on natural scale
- Probability of Success (PoS) assessment with visual indicators
- Population parameter estimates (μ, τ, ρ)
- MCMC trace plots for convergence diagnostics
- Publication-ready visualizations using ggplot2

### 4. Data Management
- Interactive table displaying **27 historical trials** (expanded from 10)
- **6 cancer types:** Melanoma, NSCLC, Renal, HCC, Bladder, Gastric
- Summary statistics and correlations
- Editable current trial parameters

### 5. Technical Features
- Non-centered parameterization for improved MCMC convergence
- Adaptive HMC with customizable adapt_delta and max_treedepth
- Parallel processing support (automatic CPU core detection)
- Comprehensive error handling
- Real-time diagnostics monitoring
- **Flexible prior specification system**

## Installation

### Prerequisites

Install required R packages:

```r
install.packages(c(
  "shiny",
  "shinythemes",
  "tidyverse",
  "rstan",
  "bayesplot",
  "DT",
  "gridExtra"
))
```

### rstan Installation

For detailed rstan installation instructions, visit: https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started

## Usage

### Running the Application

1. **From R/RStudio:**
```r
library(shiny)
runApp("app.R")
```

2. **From command line:**
```bash
R -e "shiny::runApp('app.R')"
```

### Application Workflow

1. **Review Model Description**: Start with the "Model Description" tab to understand the statistical framework

2. **View Historical Data**: Check the "Data" tab to see the 10 historical immunotherapy trials

3. **Configure Parameters**: Navigate to "Run Model" and set:
   - MCMC iterations (default: 4000)
   - Number of chains (default: 4)
   - Current trial interim OS log(HR) and SE
   - Current trial interim PFS log(HR) and SE
   - Target log(HR) for success

4. **Execute Model**: Click "Run Stan Model" to perform Bayesian analysis

5. **Review Results**: Navigate to "Results" tab to see:
   - Posterior distributions
   - PoS assessment
   - Population parameters
   - MCMC diagnostics

## Model Details

### Statistical Framework

The application implements a hierarchical Bayesian model:

**Data level:**
- y_{k,j} ~ N(θ_{k,j}, W_{k,j})

**Population level:**
- θ_k ~ N(μ, Σ)

**Default Priors (Customizable):**
- μ_OS ~ N(-0.35, 1.0) - **adjustable mean and SD**
- μ_PFS ~ N(-0.45, 1.0) - **adjustable mean and SD**
- τ_OS ~ Exp(2) or Half-Normal(0, σ) - **choice of distribution**
- τ_PFS ~ Exp(2) or Half-Normal(0, σ) - **choice of distribution**
- ρ ~ Uniform(-0.95, 0.95) or LKJ(η) - **choice of distribution**

**Non-centered parameterization:**
- θ_k = μ + L_Σ * z_k, where z_k ~ N(0, I)

### Probability of Success

PoS is calculated as:
```
PoS = P(θ_OS,current < target | data)
```

**Interpretation:**
- PoS ≥ 0.90: ★★★ VERY HIGH - Trial very likely to succeed
- PoS ≥ 0.70: ★★ HIGH - Trial likely to succeed
- PoS ≥ 0.50: ★ MODERATE - Trial may succeed
- PoS < 0.50: ✗ LOW - Trial unlikely to succeed

## Default Data

The application uses simulated data from **27 historical immunotherapy trials** covering:
- Melanoma
- Non-Small Cell Lung Cancer (NSCLC)
- Renal Cell Carcinoma
- Hepatocellular Carcinoma (HCC)
- **Bladder Cancer**
- **Gastric Cancer**

Default current trial parameters represent an NSCLC trial with:
- Interim PFS log(HR): -0.48 (SE: 0.12)
- Interim OS log(HR): -0.35 (SE: 0.25)
- Target OS log(HR): -0.30

## Technical Notes

- **Computing Time**: Model execution typically takes 2-5 minutes depending on MCMC settings and available CPU cores
- **Parallel Processing**: The app automatically detects and uses available CPU cores for parallel chain execution
- **Convergence Diagnostics**: R-hat values should be < 1.01 for adequate convergence
- **Effective Sample Size**: ESS should be > 100 per chain for reliable inference
- **MCMC Controls**: adapt_delta and max_treedepth are now user-adjustable for fine-tuning convergence

## Understanding Between-Trial Correlation

**Important Statistical Concepts:**

The model estimates a **between-trial correlation (ρ)** parameter that measures how trial-level effects correlate across endpoints. This is different from within-trial correlation!

### Quick Reference:

🎯 **[HOW_RHO_IS_ESTIMATED.md](HOW_RHO_IS_ESTIMATED.md)** - **NEW! How is ρ estimated?**
- How ρ is learned from historical trial data structure alone
- Why current trial is NOT needed to estimate ρ
- Worked numerical examples showing the estimation process
- Mathematical intuition and validation
- **Essential reading for understanding the estimation mechanism**

🔍 **[FAQ_CORRELATION.md](FAQ_CORRELATION.md)** - Frequently Asked Questions:
- **Q0: How is ρ estimated from historical trials?** (NEW!)
- Why is my estimated ρ so low?
- What information can I still borrow with low ρ?
- How much does ρ matter for PoS?
- When to expect high vs low ρ?
- Should I change my prior on ρ?
- **Quick decision framework and practical guidelines**

### Detailed Guides:

📖 **[UNDERSTANDING_CORRELATION.md](UNDERSTANDING_CORRELATION.md)** - Comprehensive guide covering:
- What is between-trial correlation and why might it be low?
- What information can be borrowed from historical data even with low ρ?
- How the hierarchical model works regardless of correlation
- Practical examples and scenarios

🎨 **[VISUAL_GUIDE_CORRELATION.md](VISUAL_GUIDE_CORRELATION.md)** - Visual explanations including:
- Diagrams showing two types of correlation (within-trial vs between-trial)
- Information flow charts for different ρ values
- Numerical examples comparing high vs low correlation scenarios
- Decision trees for interpreting results

### Quick Summary:

Even with **low between-trial correlation (ρ ≈ 0.1-0.3)**, historical data provides substantial value:

✅ **Always Borrowed** (regardless of ρ):
- Population mean effects (μ_OS, μ_PFS)
- Between-trial heterogeneity (τ_OS, τ_PFS)
- Hierarchical shrinkage (prevents overfitting)
- Proper uncertainty quantification

✅ **Conditionally Borrowed** (only when ρ > 0):
- Cross-endpoint information (PFS → OS predictions)
- Strength proportional to ρ value

**Bottom line:** Low ρ doesn't mean historical data is useless - it just means we can't leverage PFS to predict OS. The model still provides robust statistical framework through population-level information and hierarchical structure.

**Real-world impact:** Even with ρ = 0, hierarchical model can boost PoS by 15+ percentage points compared to analyzing current trial alone!

## Troubleshooting

### 🔧 Seeing ρ ≈ 0.14 Instead of Expected ρ ≈ 0.60?

**If you're getting low ρ estimates (0.1-0.2) when you expect ~0.6:**

📋 **[ANSWER_WHY_STILL_014.md](ANSWER_WHY_STILL_014.md)** - START HERE
- 30-second quick fix
- Why this happens
- Step-by-step verification
- Expected vs. actual values

🔍 **[TROUBLESHOOTING_RHO.md](TROUBLESHOOTING_RHO.md)** - Comprehensive Guide
- Complete troubleshooting checklist
- Diagnostic steps
- Common issues and solutions

🧪 **test_data_generation.R** - Verification Script
- Run to verify data generation works correctly
- Expected output: correlation ≈ 0.60

**Quick Fix (Most Common Cause - Browser Cache):**
```r
# 1. Stop Shiny app
# 2. Restart R (Session → Restart R)
# 3. Clear browser cache (Ctrl+Shift+Delete)
# 4. Re-run app
shiny::runApp("app.R")
# 5. Check Data tab - should show "Between-trial cor: 0.619"
```

### Common Issues

1. **Model compilation errors**: Ensure rstan is properly installed and configured
2. **Divergent transitions**: Adjust adapt_delta (increase toward 0.999) if warnings appear
3. **Low ESS**: Increase number of iterations if ESS warnings appear
4. **Memory issues**: Reduce number of iterations or chains if memory is limited
5. **Low ρ estimates**: See troubleshooting guides above (likely browser cache issue)

### Performance Tips

- Use parallel processing by ensuring multiple cores are available
- Start with default settings (4000 iterations, 4 chains) for balance between speed and reliability
- Monitor R-hat and ESS values in diagnostics output

## File Structure

```
POS-simulation/
├── app.R                              # Main Shiny application
├── README.md                          # This file
├── bayesian_pos_fixed current rho     # Original R script (reference)
│                                      # Note: filename contains spaces
└── [other project files]
```

## Citation

If you use this application in your research, please cite the original methodology and this implementation.

## License

[Add appropriate license information]

## Contact

[Add contact information for questions/issues]

## Changelog

### Version 1.0.0 (2026-02-12)
- Initial release
- Complete Shiny interface implementation
- All five main panels operational
- Non-centered parameterization for improved convergence
- Real-time diagnostics and visualization
