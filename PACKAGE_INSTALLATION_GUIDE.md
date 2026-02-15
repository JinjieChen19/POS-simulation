# R Package Installation Guide for Coworkers

## What You're Getting

The POSsimulation R package - a complete Bayesian PoS simulation app that you can install with one command and run anywhere.

## Prerequisites

### 1. Install R and RStudio

**R** (required):
- Download from: https://cran.r-project.org/
- Choose your operating system
- Install latest version (4.0.0 or higher)

**RStudio** (recommended):
- Download from: https://posit.co/download/rstudio-desktop/
- Makes R easier to use
- Free desktop version

### 2. Install C++ Compiler (for Stan models)

**Windows**:
```r
# In R console, run:
install.packages("installr")
installr::install.Rtools()
```

Or download manually from: https://cran.r-project.org/bin/windows/Rtools/

**Mac**:
```bash
# In Terminal, run:
xcode-select --install
```

**Linux (Ubuntu/Debian)**:
```bash
sudo apt-get install build-essential
```

### 3. Verify C++ Compiler

```r
# In R console
install.packages("pkgbuild")
pkgbuild::check_build_tools(debug = TRUE)
```

Should say: "Your system is ready to build packages!"

## Installation

### Step 1: Install devtools

```r
install.packages("devtools")
```

### Step 2: Install POSsimulation Package

```r
devtools::install_github("JinjieChen19/POS-simulation")
```

**This takes 5-10 minutes** because it:
- Downloads the package
- Installs all dependencies
- Compiles Stan models

You'll see lots of messages - this is normal!

### Step 3: Test Installation

```r
library(POSsimulation)
run_pos_app()
```

The app should open in your web browser! 🎉

## Usage

### Basic

```r
# Always start with
library(POSsimulation)

# Then run the app
run_pos_app()
```

### Advanced

```r
# Local server version (for team access)
run_pos_app_local()

# Authenticated version (with login)
run_pos_app_authenticated()
```

## Troubleshooting

### Problem: "Could not find function 'run_pos_app'"

**Solution**: Load the library first
```r
library(POSsimulation)
run_pos_app()
```

### Problem: Stan compilation errors

**Solution 1**: Install rstan separately
```r
install.packages("rstan", repos = "https://cloud.r-project.org/", dependencies = TRUE)
```

**Solution 2**: Check C++ compiler
```r
pkgbuild::check_build_tools(debug = TRUE)
```

**Solution 3**: Restart R and try again
```r
# In RStudio: Session → Restart R
devtools::install_github("JinjieChen19/POS-simulation")
```

### Problem: Package installation fails

**Solution**: Install dependencies manually
```r
install.packages(c("shiny", "rstan", "tidyverse", "bayesplot", "DT", "MASS"))
devtools::install_github("JinjieChen19/POS-simulation")
```

### Problem: App doesn't open in browser

**Solution**: Get the URL manually
```r
library(POSsimulation)
run_pos_app(launch.browser = FALSE)
# Copy the URL shown and paste in browser
```

## Updating

To get the latest version:

```r
devtools::install_github("JinjieChen19/POS-simulation")
```

## Uninstalling

If you need to remove the package:

```r
remove.packages("POSsimulation")
```

## Getting Help

### Within R

```r
# Function help
?run_pos_app

# Package help
help(package = "POSsimulation")
```

### Contact

- GitHub Issues: https://github.com/JinjieChen19/POS-simulation/issues
- Email the package maintainer (see DESCRIPTION file)

## What Next?

Once installed, you can:

1. **Run the app anytime** with `run_pos_app()`
2. **Share with others** - they install the same way
3. **No need to reinstall** - package stays on your computer
4. **Update occasionally** - use `devtools::install_github()` again

## Summary

```r
# ONE-TIME SETUP
install.packages("devtools")
devtools::install_github("JinjieChen19/POS-simulation")

# EVERY TIME YOU WANT TO USE IT
library(POSsimulation)
run_pos_app()
```

Simple! 🚀
