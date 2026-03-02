# Quick Start Guide

## Getting Started with the Bayesian PoS Shiny App

### Prerequisites

1. **Install R** (version 4.0.0 or higher)
   - Download from: https://www.r-project.org/

2. **Install RStudio** (recommended but optional)
   - Download from: https://posit.co/download/rstudio-desktop/

### Installation

#### Step 1: Install Required Packages

Open R or RStudio and run:

```r
# Install packages from CRAN
install.packages(c(
  "shiny",
  "shinythemes",
  "tidyverse",
  "DT",
  "gridExtra",
  "bayesplot"
))

# Install rstan (may take 15-30 minutes)
install.packages("rstan", dependencies = TRUE)
```

#### Step 2: Verify Installation

```r
# Check that packages load correctly
library(shiny)
library(rstan)
library(tidyverse)
```

### Running the App

#### Option 1: From RStudio (Easiest)

1. Open `app.R` in RStudio
2. Click the "Run App" button at the top of the editor
3. The app will open in a new window or browser tab

#### Option 2: From R Console

```r
library(shiny)
runApp("app.R")
```

#### Option 3: From Command Line

```bash
R -e "shiny::runApp('app.R')"
```

### First Steps in the App

#### 1. Explore the Model (2 minutes)
- Click **"Model Description"** tab
- Review the statistical framework
- Understand the priors and model structure
- **NEW:** Note the customizable features

#### 2. View Historical Data (1 minute)
- Click **"Data"** tab
- Examine the **27 historical trials** (expanded from 10)
- Note the **6 cancer types** and effect sizes

#### 3. Run the Model (5-10 minutes)
- Click **"Run Model"** tab
- **NEW Features - MCMC Settings:**
  - Iterations: 4000 (adjustable)
  - Chains: 4 (adjustable)
  - Adapt delta: 0.99 (adjustable)
  - Max treedepth: 12 (adjustable)
- **NEW Features - Prior Settings:**
  - Population means: Default N(-0.35, 1.0) and N(-0.45, 1.0)
  - Heterogeneity: Choose Exponential or Half-Normal
  - Correlation: Choose Uniform or LKJ
- **Current Trial Parameters:**
  - Current trial OS log(HR): -0.35 ± 0.25
  - Current trial PFS log(HR): -0.48 ± 0.12
  - Target: -0.30
- Click **"Run Stan Model"**
- Wait 2-5 minutes for model to complete

#### 4. View Results (5 minutes)
- Click **"Results"** tab after model completes
- Examine:
  - Posterior distributions
  - Probability of Success (PoS)
  - Population parameters
  - MCMC diagnostics

#### 5. Get Help (as needed)
- Click **"Help"** tab for detailed guidance

### Exploring New Features

#### Adjusting MCMC Settings
Try increasing `adapt_delta` to 0.995 or 0.999 if you see divergent transition warnings.
Try increasing `max_treedepth` to 14 or 15 for complex posteriors.

#### Customizing Priors
1. **Population Means:** Adjust based on expected treatment effect
   - Example: Set μ_OS to -0.40 for more optimistic prior
2. **Heterogeneity:** 
   - Use Exponential for lighter tails
   - Use Half-Normal for more regularization
3. **Correlation:**
   - Use Uniform for non-informative prior
   - Use LKJ with η=2 for mild regularization toward independence

### Example Workflow

```
┌─────────────────────────────────────────────────┐
│ 1. Set Parameters                               │
│    - MCMC: 4000 iterations, 4 chains            │
│    - Trial: OS = -0.35 ± 0.25                   │
│    - Target: -0.30                              │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ 2. Run Model (Click "Run Stan Model")          │
│    - Progress: Compiling → Sampling → Done     │
│    - Wait: ~3-5 minutes                         │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ 3. Review Results                               │
│    - PoS: e.g., 82.3% (★★ HIGH)                │
│    - Posterior: θ_OS = -0.34 [-0.79, 0.11]     │
│    - Population: μ_OS = -0.31, ρ = 0.71        │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ 4. Interpret & Decide                           │
│    - PoS ≥ 70%? Trial likely to succeed        │
│    - Check diagnostics: R-hat < 1.01? ✓        │
│    - Make go/no-go decision                     │
└─────────────────────────────────────────────────┘
```

### Troubleshooting

#### Problem: rstan installation fails
**Solution:**
1. Ensure you have a C++ compiler installed
   - Windows: Install Rtools (https://cran.r-project.org/bin/windows/Rtools/)
   - Mac: Install Xcode command line tools
   - Linux: Install build-essential
2. Follow detailed rstan installation guide: https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started

#### Problem: Model takes too long
**Solution:**
1. Reduce iterations to 2000
2. Reduce chains to 2
3. Ensure parallel processing is working (check CPU usage)

#### Problem: Divergent transitions warning
**Solution:**
- This is already addressed with adapt_delta = 0.99
- If still occurs, increase iterations

#### Problem: Low effective sample size (ESS)
**Solution:**
- Increase iterations (e.g., to 6000)
- Results are usually still reliable if ESS > 100

### Tips for Best Results

1. **First Run**: Use default settings to understand the workflow
2. **Parameter Tuning**: Adjust current trial parameters to test different scenarios
3. **Convergence**: Always check R-hat < 1.01 in diagnostics
4. **Multiple Runs**: Run model multiple times with different parameters to explore sensitivity
5. **Documentation**: Refer to Help tab for detailed explanations

### Expected Performance

| Setting          | Value     |
|------------------|-----------|
| Compilation time | 10-30 sec |
| Sampling time    | 2-5 min   |
| Total time       | 3-6 min   |
| Memory usage     | ~500 MB   |

*Times vary based on computer speed and number of cores*

### Next Steps

After successfully running the default case:

1. **Experiment**: Try different current trial parameters
2. **Scenarios**: Test optimistic (-0.50) and pessimistic (-0.20) scenarios
3. **Targets**: Adjust target log(HR) to see impact on PoS
4. **Documentation**: Read full README.md for advanced features

### Support

For issues or questions:
- Review the **Help** tab in the app
- Check **README.md** for detailed documentation
- See **UI_DOCUMENTATION.md** for technical details

### Quick Reference Card

```
╔══════════════════════════════════════════════════╗
║         BAYESIAN PoS APP QUICK REFERENCE         ║
╠══════════════════════════════════════════════════╣
║ Default Settings:                                ║
║   • Iterations: 4000                             ║
║   • Chains: 4                                    ║
║   • Runtime: ~3-5 minutes                        ║
║                                                  ║
║ PoS Interpretation:                              ║
║   • ≥90%: ★★★ Very High (likely success)        ║
║   • ≥70%: ★★  High                               ║
║   • ≥50%: ★   Moderate                           ║
║   • <50%: ✗   Low (unlikely success)             ║
║                                                  ║
║ Convergence Check:                               ║
║   • R-hat should be < 1.01                       ║
║   • ESS should be > 100                          ║
║                                                  ║
║ Model Priors:                                    ║
║   • μ_OS  ~ N(-0.35, 1.0)                        ║
║   • μ_PFS ~ N(-0.45, 1.0)                        ║
║   • τ_OS, τ_PFS ~ Exp(2)                         ║
║   • ρ ~ Uniform(-0.95, 0.95)                     ║
╚══════════════════════════════════════════════════╝
```

---

**Ready to start? Open `app.R` and click "Run App"!** 🚀
