# Simplified App Guide (app_simple.R)

## Overview

`app_simple.R` is a streamlined version of the Bayesian PoS Simulation application with **Help** and **Model Description** tabs removed for a cleaner, more focused user experience.

## What's Different?

### Removed Tabs:
- ❌ **Model Description** - Technical formulation and mathematical details
- ❌ **Help** - User guide and documentation

### Retained Tabs:
- ✅ **Run Model** - All controls and settings
- ✅ **Results** - MCMC diagnostics and posterior distributions
- ✅ **Scatter Plot** - Visual exploration of trials
- ✅ **Data** - Historical trials table

## Why Use the Simplified Version?

### Advantages:
1. **Cleaner Interface** - Less scrolling, easier navigation
2. **Faster Loading** - 20% fewer lines of code
3. **Production Ready** - Focused on execution, not explanation
4. **Experienced Users** - For those who know the model already
5. **Demos** - Cleaner for presentations

### When to Use Full Version (`app.R`):
1. **New Users** - Need model documentation
2. **Learning** - Want to understand the statistical framework
3. **Educational** - Teaching Bayesian methods
4. **Reference** - Need detailed prior specifications
5. **Troubleshooting** - Want explanations of features

## Features Preserved

### 100% Functionality Retained:

#### Data Generation Controls:
- Random seed
- Population parameters (μ_OS, μ_PFS, τ_OS, τ_PFS, ρ_true)
- SE ranges (OS and PFS)
- Within-trial correlation range

#### Prior Specifications:
- Population means (Normal priors with adjustable parameters)
- Between-trial heterogeneity (Exponential or Half-Normal)
- Correlation:
  - **Fisher-z** (RECOMMENDED) - Informative prior ρ 95% ~ [0.35, 0.80]
  - Uniform(-0.95, 0.95)
  - Uniform(0, 0.95) - Positive only
  - Beta(α, β) - Positive only
  - LKJ(η)

#### MCMC Settings:
- Iterations
- Chains
- adapt_delta
- max_treedepth

#### Current Trial Parameters:
- Interim log(HR) for OS and PFS
- Standard errors
- Target log(HR) for success

#### Results:
- MCMC diagnostics (R-hat, n_eff, divergences)
- Posterior distributions
- PoS calculation
- Trace plots
- Density plots

#### Visualizations:
- Scatter plot of 27 historical + 1 current trial
- Data table with all trial characteristics

## Quick Start

### Running the App:

```r
# Option 1: Direct
shiny::runApp("app_simple.R")

# Option 2: From source
source("app_simple.R")
# App launches automatically

# Option 3: Specify port
shiny::runApp("app_simple.R", port = 3838)
```

### Basic Workflow:

1. **Set Data Generation** (optional - defaults are realistic)
   - Adjust seed, population parameters if needed
   
2. **Configure Priors** (optional - defaults recommended)
   - Fisher-z is pre-set with informative prior
   
3. **Set Current Trial Data**
   - Enter interim log(HR) for OS and PFS
   - Enter standard errors
   - Set target log(HR)
   
4. **Run Model**
   - Click "Run Stan Model"
   - Wait for completion (2-5 minutes)
   
5. **Review Results**
   - Check MCMC diagnostics
   - View posterior distributions
   - See PoS calculation
   
6. **Explore Visualizations**
   - Scatter plot shows all trials
   - Data table provides details

## File Structure

### Components:

```
Libraries (15 lines)
  └── shiny, tidyverse, rstan, bayesplot, DT, MASS

Helper Functions (255 lines)
  ├── Fisher-z prior calculation
  ├── prepare_historical_loghr_data()
  └── build_stan_model_improved()

UI Definition (227 lines)
  ├── Tab: Run Model (118 lines)
  ├── Tab: Results (43 lines)
  ├── Tab: Scatter Plot (25 lines)
  └── Tab: Data (14 lines)

Server Logic (399 lines)
  ├── Reactive data generation
  ├── Stan model execution
  ├── Results processing
  ├── Plot rendering
  └── Table output

Total: 884 lines (vs 1,111 in full version)
```

## Comparison: Simple vs Full

| Feature | app_simple.R | app.R |
|---------|--------------|-------|
| Lines of Code | 884 | 1,111 |
| Number of Tabs | 4 | 6 |
| Model Description | ❌ | ✅ |
| Help Documentation | ❌ | ✅ |
| Run Model | ✅ | ✅ |
| Results | ✅ | ✅ |
| Scatter Plot | ✅ | ✅ |
| Data Table | ✅ | ✅ |
| All Functionality | ✅ | ✅ |
| Code Reduction | 20% | 0% |
| Best For | Experienced users | New users |

## Documentation Access

### For Model Information:

While the simplified app doesn't include documentation tabs, all information is available in the repository:

- **Model Description:** See `README.md` and documentation files
- **Fisher-z Prior:** See `FISHER_Z_TRANSFORMATION.md`
- **Correlation Estimation:** See `HOW_RHO_IS_ESTIMATED.md`
- **Data Generation:** See `CUSTOMIZABLE_DATA_GENERATION.md`
- **Troubleshooting:** See `TROUBLESHOOTING_RHO.md`

### Quick Reference:

**Fisher-z Default (RECOMMENDED):**
- μ_z = 0.5365, σ_z = 0.2173
- Equivalent to ρ 95% ~ [0.35, 0.80]
- Informative prior for typical oncology trials

**Population Parameters:**
- μ_OS = -0.30 (favorable OS effect)
- μ_PFS = -0.45 (favorable PFS effect)
- τ_OS = τ_PFS = 0.15 (moderate heterogeneity)
- ρ_true = 0.65 (strong positive correlation)

**MCMC Defaults:**
- Iterations: 4,000
- Chains: 4
- adapt_delta: 0.99 (high for complex model)
- max_treedepth: 12 (sufficient for most cases)

## Tips for Efficient Use

### 1. Use Defaults First
- Start with default settings to verify functionality
- Adjust only if needed for specific scenarios

### 2. Check Diagnostics
- Always review R-hat (should be < 1.01)
- Check n_eff (should be > 1,000)
- Monitor divergent transitions (should be 0)

### 3. Data Generation
- Use default seed (20260212) for reproducibility
- Adjust only for sensitivity analysis or specific studies

### 4. Prior Selection
- **Fisher-z is recommended** for most use cases
- Provides informative prior based on oncology literature
- Better estimation than uninformative priors

### 5. Scatter Plot Exploration
- Use to understand trial distribution
- Check for outliers
- Visualize correlation structure

## Common Use Cases

### 1. Quick PoS Assessment
```
Workflow:
1. Enter current trial data
2. Use default priors (Fisher-z)
3. Run model
4. Check PoS value
Time: 5-10 minutes
```

### 2. Sensitivity Analysis
```
Workflow:
1. Run with different prior settings
2. Compare PoS across scenarios
3. Use scatter plot to understand data
Time: 15-30 minutes
```

### 3. Multiple Scenarios
```
Workflow:
1. Change data generation seed
2. Run multiple times
3. Compare results distribution
Time: 30-60 minutes
```

### 4. Custom Data
```
Workflow:
1. Adjust population parameters
2. Set realistic SE ranges
3. Generate and analyze
4. Compare to defaults
Time: 20-40 minutes
```

## Troubleshooting

### App Doesn't Load:
- Check all packages are installed
- Verify R version >= 4.0
- Check for syntax errors in console

### Model Takes Too Long:
- Reduce iterations (try 2,000)
- Reduce chains (try 2)
- Check adapt_delta (try 0.95)

### High Divergent Transitions:
- Increase adapt_delta to 0.999
- Increase max_treedepth to 13-15
- Check for extreme prior settings

### Low R-hat Issues:
- Increase iterations
- Check for label switching
- Review trace plots

### Need Documentation:
- Use full version (`app.R`)
- Check repository markdown files
- Review `README.md`

## Support

### Getting Help:
1. Check repository documentation files
2. Review full app (`app.R`) Help tab
3. Consult `TROUBLESHOOTING_RHO.md`
4. Open GitHub issue

### Reporting Bugs:
- Specify using `app_simple.R`
- Include R version and package versions
- Provide reproducible example
- Share error messages

## Future Updates

Both `app.R` and `app_simple.R` will be maintained in parallel:
- Bug fixes applied to both
- New features added to both
- Documentation only in full version
- Simplified version stays streamlined

## Conclusion

`app_simple.R` provides a **production-ready, streamlined interface** for Bayesian PoS simulation while maintaining **100% of the core functionality**. Perfect for experienced users who prefer a cleaner, more focused experience.

For new users or educational purposes, the full version (`app.R`) provides comprehensive documentation and help.
