# POSsimulation

## Bayesian Probability of Success Simulation for Oncology Trials

An interactive R Shiny application package for simulating and calculating Bayesian Probability of Success (PoS) for oncology clinical trials.

## 🚀 Quick Start for Coworkers

### Installation (One Time)

```r
# Install devtools if needed
install.packages("devtools")

# Install POSsimulation package
devtools::install_github("JinjieChen19/POS-simulation")
```

**First installation takes 5-10 minutes** (compiling Stan models).

### Running the App

```r
library(POSsimulation)

# Launch the app (opens in browser)
run_pos_app()
```

That's it! 🎉

## Features

- 📊 Bayesian hierarchical modeling with Stan
- 🎯 PoS calculation with customizable target thresholds
- 📈 Integration of 27 historical oncology trials
- 🔧 Flexible prior specifications (Fisher-z, uniform, beta, etc.)
- 📉 Real-time MCMC diagnostics
- ⚡ Optimized Stan models (2-6x faster sampling)
- 👥 Multi-user support for team access

## App Versions

```r
# Standard version (with help documentation)
run_pos_app()

# Local server version (optimized for team access)
run_pos_app_local()

# Authenticated version (requires login)
run_pos_app_authenticated()
```

## System Requirements

- R >= 4.0.0
- C++ compiler (for Stan):
  - **Windows**: Rtools
  - **Mac**: Xcode Command Line Tools
  - **Linux**: gcc/g++

## Troubleshooting

### C++ Compiler Not Found

**Windows**:
```r
install.packages("installr")
installr::install.Rtools()
```

**Mac**:
```bash
xcode-select --install
```

### Update Package

```r
devtools::install_github("JinjieChen19/POS-simulation")
```

## Documentation

- In-app help available in each version
- Function documentation: `?run_pos_app`
- Detailed installation guide: See `PACKAGE_INSTALLATION_GUIDE.md`

## License

MIT License

## Author

Jinjie Chen

---

**GitHub**: https://github.com/JinjieChen19/POS-simulation
