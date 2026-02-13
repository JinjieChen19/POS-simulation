# Deployment Guide for shinyapps.io

## Overview

The Bayesian PoS Simulation app has been restructured into the standard Shiny deployment format with three separate files:

- **`global.R`** - Shared code (libraries, helper functions, defaults)
- **`ui.R`** - User interface definition
- **`server.R`** - Server logic and reactive programming

This structure follows Shiny best practices and is required for deployment to shinyapps.io.

---

## File Structure

```
POS-simulation/
├── global.R       # Shared code (211 lines)
├── ui.R          # User interface (176 lines)
├── server.R      # Server logic (280 lines)
├── app_simple.R  # Original single-file version (for reference)
└── app.R         # Full version with documentation tabs
```

---

## Deployment Methods

### Method 1: Using rsconnect Package (Recommended)

#### Step 1: Install rsconnect
```r
install.packages("rsconnect")
library(rsconnect)
```

#### Step 2: Set up shinyapps.io Account
1. Go to [shinyapps.io](https://www.shinyapps.io/) and create an account
2. Click on your name (top right) → Tokens
3. Click "Show Secret" to reveal your token

#### Step 3: Configure rsconnect
```r
rsconnect::setAccountInfo(
  name = "your-account-name",
  token = "your-token",
  secret = "your-secret"
)
```

#### Step 4: Deploy the App
```r
# Set working directory to project folder
setwd("/path/to/POS-simulation")

# Deploy app
rsconnect::deployApp(
  appFiles = c("global.R", "ui.R", "server.R"),
  appName = "bayesian-pos-simulation",
  appTitle = "Bayesian PoS Simulation",
  account = "your-account-name"
)
```

**Note:** The deployment will automatically detect and include any necessary data files.

---

### Method 2: Using RStudio (Easiest)

#### Step 1: Open Project in RStudio
1. Open RStudio
2. File → Open Project → Select POS-simulation folder
3. Or simply open `ui.R`, `server.R`, or `global.R`

#### Step 2: Click Publish Button
1. Look for "Publish" button in top-right corner of source pane
2. Click it (looks like a blue cloud icon)

#### Step 3: Follow Publishing Wizard
1. Select "Publish Application"
2. Choose "shinyapps.io" as destination
3. Sign in to shinyapps.io (if first time)
4. RStudio will automatically detect all 3 files
5. Verify files: global.R, ui.R, server.R are checked
6. Click "Publish"

RStudio handles everything automatically!

---

### Method 3: Manual Upload via Web Interface

#### Step 1: Prepare Files
```bash
# Create a zip file with the three files
cd /path/to/POS-simulation
zip app_deploy.zip global.R ui.R server.R
```

#### Step 2: Upload to shinyapps.io
1. Go to shinyapps.io dashboard
2. Click "New Application"
3. Upload the zip file
4. System will automatically detect the Shiny app structure
5. Click "Deploy"

---

## Testing Locally Before Deployment

Always test locally before deploying:

```r
# Set working directory
setwd("/path/to/POS-simulation")

# Run app (automatically detects ui.R, server.R, global.R)
shiny::runApp()
```

**Or** in RStudio:
1. Open any of the 3 files
2. Click "Run App" button
3. Test all functionality

---

## Required Packages

Ensure these packages are installed before deployment:

```r
install.packages(c(
  "shiny",
  "shinythemes",
  "tidyverse",
  "rstan",
  "bayesplot",
  "DT",
  "gridExtra",
  "MASS"
))
```

**Note:** shinyapps.io will automatically install these packages during deployment, but it's good to have them locally for testing.

---

## Deployment Configuration

### Basic Settings

After deployment, you can configure your app in the shinyapps.io dashboard:

- **Instance Size:** Start with Small (1 GB RAM), upgrade if needed
- **Worker Timeout:** 60 seconds (default)
- **Max Processes:** 3 (adjust based on plan)
- **Max Connections per Process:** 50 (adjust based on plan)

### Performance Tuning

For better performance with Stan models:

1. **Instance Size:** Consider Medium (2 GB) or Large (4 GB) for faster Stan compilation
2. **rstan Configuration:** Already optimized in `global.R`:
   ```r
   options(mc.cores = parallel::detectCores())
   rstan_options(auto_write = TRUE)
   ```

### Resource Limits

Be aware of shinyapps.io limits:
- **Free tier:** 25 active hours/month
- **Execution time:** Long Stan runs may timeout (increase worker timeout if needed)
- **Memory:** Stan models can be memory-intensive (monitor usage)

---

## Troubleshooting

### Common Issues

#### 1. "Application failed to start"
**Cause:** Missing package or dependency
**Solution:** Check deployment logs for missing packages, add them to global.R

#### 2. "Worker timeout"
**Cause:** Stan model takes too long
**Solution:** 
- Reduce MCMC iterations in UI
- Increase worker timeout in settings
- Upgrade to larger instance

#### 3. "Out of memory"
**Cause:** Stan model uses too much RAM
**Solution:**
- Reduce number of chains
- Upgrade to larger instance size
- Consider parallel chain limits

#### 4. "Cannot find file"
**Cause:** File path issues
**Solution:** 
- Use relative paths only
- Ensure all 3 files (global.R, ui.R, server.R) are in same directory
- Don't use `setwd()` in code

### Debugging Tips

1. **Check Logs:** 
   - In shinyapps.io dashboard → Your app → Logs
   - Look for error messages

2. **Test Locally First:**
   - Always run `shiny::runApp()` locally before deploying

3. **Simplify:**
   - If deployment fails, try with default values
   - Test with fewer MCMC iterations first

---

## Updating the App

To update your deployed app:

### Using rsconnect:
```r
rsconnect::deployApp(
  appFiles = c("global.R", "ui.R", "server.R"),
  appName = "bayesian-pos-simulation",
  account = "your-account-name",
  forceUpdate = TRUE
)
```

### Using RStudio:
1. Make your changes
2. Click "Publish" button
3. Select existing app
4. Click "Publish" to update

---

## Best Practices

### 1. Code Organization
- ✅ Keep helper functions in `global.R`
- ✅ Keep UI definition in `ui.R`
- ✅ Keep reactive logic in `server.R`
- ✅ Don't mix concerns across files

### 2. Performance
- ✅ Use reactive expressions wisely
- ✅ Cache expensive computations in global.R
- ✅ Limit MCMC iterations for online use
- ✅ Provide progress indicators

### 3. User Experience
- ✅ Set reasonable defaults
- ✅ Provide helpful text
- ✅ Show progress/status
- ✅ Handle errors gracefully

### 4. Security
- ✅ Don't hardcode secrets
- ✅ Use environment variables for sensitive data
- ✅ Validate user inputs
- ✅ Set appropriate app visibility (public/private)

---

## Monitoring and Maintenance

### Check App Health
- Monitor usage in shinyapps.io dashboard
- Check for errors in logs
- Monitor memory and CPU usage
- Watch for timeout issues

### Regular Updates
- Update packages periodically
- Test after R/Stan version updates
- Keep documentation current
- Archive old versions

---

## Additional Resources

### Official Documentation
- [Shiny Deployment Guide](https://shiny.posit.co/r/articles/share/shinyapps/)
- [shinyapps.io User Guide](https://docs.posit.co/shinyapps.io/)
- [rsconnect Package](https://github.com/rstudio/rsconnect)

### Support
- [Posit Community Forum](https://community.rstudio.com/)
- [shinyapps.io Support](https://support.posit.co/)

---

## Summary

Your app is now ready for deployment to shinyapps.io with:
- ✅ Proper file structure (global.R, ui.R, server.R)
- ✅ All functionality preserved
- ✅ Optimized for deployment
- ✅ Complete documentation

Choose your preferred deployment method above and deploy with confidence! 🚀
