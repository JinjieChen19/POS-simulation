# Bayesian PoS Shiny Application - UI Components Documentation

## Application Structure

The R Shiny application consists of 5 main tabs accessible via a navigation bar:

### 1. Model Description Tab
**Purpose**: Display comprehensive statistical model documentation

**Components**:
- Statistical model formulation with mathematical notation (using MathJax)
- Hierarchical structure explanation:
  - Data level: y_{k,j} ~ N(θ_{k,j}, W_{k,j})
  - Population level: θ_k ~ N(μ, Σ)
- Prior specifications clearly listed:
  - μ_OS ~ N(-0.35, 1.0)
  - μ_PFS ~ N(-0.45, 1.0)
  - τ_OS ~ Exp(2)
  - τ_PFS ~ Exp(2)
  - ρ ~ Uniform(-0.95, 0.95)
- Between-trial covariance matrix formula
- Non-centered parameterization explanation
- Likelihood structure for historical and current trials
- Probability of Success (PoS) definition

### 2. Run Model Tab
**Purpose**: Interactive model execution interface

**Layout**: Sidebar + Main Panel

**Sidebar Panel Inputs**:
- MCMC Iterations (numeric input, default: 4000, range: 1000-10000)
- Number of Chains (numeric input, default: 4, range: 1-8)
- Current Trial Parameters section:
  - Interim log(HR) for OS (numeric input, default: -0.35)
  - SE of log(HR) for OS (numeric input, default: 0.25)
  - Interim log(HR) for PFS (numeric input, default: -0.48)
  - SE of log(HR) for PFS (numeric input, default: 0.12)
  - Target log(HR) for Success (numeric input, default: -0.30)
- "Run Stan Model" button (large, primary blue, with play icon)
- Note about execution time

**Main Panel Outputs**:
- Model Execution section:
  - Text output showing compilation and execution progress
  - Displays settings, parameters, and completion status
- MCMC Diagnostics section:
  - Detailed Stan summary with R-hat, ESS, and parameter estimates
  - Shows key parameters: mu_os, mu_pfs, tau_os, tau_pfs, rho, theta_os_post

### 3. Results Tab
**Purpose**: Comprehensive visualization of posterior results

**Layout**: Grid of plots and text outputs

**Visualizations** (2x2 grid):
1. **Top Left**: Posterior Distribution: OS log(HR)
   - Histogram with density overlay
   - Blue color scheme (#4682B4)
   - Vertical dashed lines for posterior mean and target
   
2. **Top Right**: Posterior Distribution: HR (Natural Scale)
   - Histogram with density overlay
   - Green color scheme (#3CB371)
   - Vertical lines for HR=1 (no effect) and target
   
3. **Bottom Left**: Probability of Success
   - Horizontal bar chart
   - Color-coded by PoS level:
     - Green (#00AA00): PoS ≥ 90%
     - Yellow-green (#88CC00): PoS ≥ 70%
     - Orange (#FFAA00): PoS ≥ 50%
     - Red (#FF4444): PoS < 50%
   - Shows current PoS vs. reference levels
   
4. **Bottom Right**: Population Parameters
   - Bar chart of μ_OS, μ_PFS, τ_OS, τ_PFS, ρ
   - Color-coded by parameter type

**Additional Sections**:
- Summary Statistics (text output):
  - Population parameters with 4 decimal places
  - Current trial posterior (mean, median, 95% CI)
  - PoS calculation with assessment (★★★, ★★, ★, or ✗)
  
- MCMC Trace Plots:
  - Multi-panel trace plots for all key parameters
  - Shows convergence across chains
  - 600px height for detailed viewing

### 4. Data Tab
**Purpose**: View and explore historical trials data

**Components**:
- Interactive DataTable showing historical trials:
  - trial_id
  - cancer_type
  - n_patients
  - loghr_os, se_loghr_os
  - loghr_pfs, se_loghr_pfs
  - corr_pfs_os
  - Pagination (10 rows per page)
  - Horizontal scrolling enabled
  
- Summary Statistics (text output):
  - Number of trials
  - Cancer types represented
  - Mean and SD for OS log(HR)
  - Mean and SD for PFS log(HR)
  - Mean correlation

### 5. Help Tab
**Purpose**: User guide and documentation

**Content Sections**:
1. **Getting Started**: Overview of the application
2. **How to Use**: Step-by-step workflow (5 steps)
3. **Key Features**: 
   - Non-centered parameterization
   - Adaptive MCMC settings
   - Parallel processing
   - Real-time diagnostics
4. **Interpreting Results**:
   - PoS levels and their meanings
5. **Technical Notes**:
   - Implementation details
   - Convergence criteria
   - Expected sample sizes

## Theme and Styling

**Theme**: Flatly (from shinythemes)
- Clean, modern Bootstrap-based theme
- Professional appearance
- Good readability

**Color Palette**:
- Primary plots: Blues (#4682B4, #00008B)
- HR plots: Greens (#3CB371, #228B22)
- PoS indicators: Traffic light system (green/yellow/red)
- Population parameters: Brewer palette "Set2"

**Font Sizes**:
- Base size: 14pt for plots
- Headers: H2, H3, H4 hierarchy
- Labels: Bold for emphasis

## User Interaction Flow

```
Start
  ↓
1. [Model Description] - Review statistical framework
  ↓
2. [Data] - Examine historical trials
  ↓
3. [Run Model] - Set parameters and execute
  ↓
  [Progress bar and status updates]
  ↓
4. [Results] - View posterior distributions and diagnostics
  ↓
  [Interpret PoS assessment]
  ↓
5. [Help] - Reference documentation as needed
```

## Technical Implementation

**Reactive Programming**:
- `observeEvent(input$run_model)`: Triggers model execution
- `reactiveValues(results)`: Stores fit, posterior samples, and summary
- `req()`: Ensures data availability before rendering
- Progress indicators with `withProgress()`

**Data Flow**:
1. Historical data loaded on startup
2. User inputs → prepare_stan_data()
3. Stan model compiled and executed
4. Posterior samples extracted
5. Results stored in reactive values
6. Plots and tables render automatically when results available

**Error Handling**:
- `req()` prevents rendering without data
- Progress messages inform user of status
- Informative error messages if compilation fails

## Accessibility Features

- Clear labels for all inputs
- Help text for complex controls
- Visual indicators (★ symbols) for PoS levels
- High-contrast color schemes
- Responsive layout adapts to screen size
