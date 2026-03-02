# Online Deployment with Authentication - Complete Guide

## Overview

This guide explains **how to make your Bayesian PoS Simulation app accessible online with username/password protection**. We'll cover 4 deployment options, ranked from easiest to most customizable.

---

## Quick Comparison: Which Option to Choose?

| Option | Difficulty | Cost | Auth Type | Best For |
|--------|-----------|------|-----------|----------|
| **1. shinyapps.io** | ⭐ Easiest | Free-$299/mo | Built-in | Quick sharing, small teams |
| **2. Shiny Server + shinymanager** | ⭐⭐ Medium | Free-$20/mo | Code-based | Budget-conscious, moderate control |
| **3. Shiny Server Pro** | ⭐⭐⭐ Hard | $10k+/year | Advanced | Large organizations |
| **4. RStudio Connect** | ⭐⭐⭐ Hard | $15k+/year | Enterprise | Full IT infrastructure |

**Recommendation:** Start with **Option 1 (shinyapps.io)** for quick deployment, or **Option 2** if you need more control on a budget.

---

## Option 1: shinyapps.io with Built-in Authentication ⭐ RECOMMENDED

### Why Choose This?
- **Easiest setup:** 10-15 minutes total
- **Built-in authentication:** No coding required
- **Free tier available:** 5 apps, 25 active hours/month
- **Automatic HTTPS:** Secure by default
- **No server management:** Fully managed service

### Step-by-Step Instructions

#### 1. Create shinyapps.io Account
```
1. Go to https://www.shinyapps.io/
2. Sign up for free account
3. Choose a unique username (becomes part of your URL)
```

#### 2. Install rsconnect Package
```r
install.packages("rsconnect")
library(rsconnect)
```

#### 3. Configure Authentication Token
```r
# In shinyapps.io dashboard: Account → Tokens → Show → Copy

rsconnect::setAccountInfo(
  name = "your-username",
  token = "ABC123...",
  secret = "xyz789..."
)
```

#### 4. Deploy Your App
```r
# For the local server version (RECOMMENDED):
rsconnect::deployApp(
  appDir = getwd(),
  appFiles = c(
    "app_local.R",
    "global_local.R", 
    "server_local.R",
    "ui_local.R",
    "stan_universal_model.stan"
  ),
  appName = "bayesian-pos-simulation",
  forceUpdate = TRUE
)

# OR for the standard version:
rsconnect::deployApp(
  appDir = getwd(),
  appFiles = c("global.R", "ui.R", "server.R"),
  appName = "bayesian-pos-simulation"
)
```

#### 5. Enable Authentication
```
1. Go to https://www.shinyapps.io/admin/
2. Click on your app name
3. Go to "Users" tab
4. Click "Add User"
5. Enter email addresses of team members
6. Set access level (viewer/collaborator)
```

#### 6. Share with Team
```
Your app URL: https://your-username.shinyapps.io/bayesian-pos-simulation/

Team members will:
1. Receive email invitation
2. Create shinyapps.io account (if needed)
3. Access app with their credentials
```

### Pricing Tiers

**Free Tier:**
- 5 applications
- 25 active hours/month
- 1GB RAM per app
- Public URL
- **Good for:** Testing, small team demos

**Starter ($9/month):**
- 25 applications
- 250 active hours/month
- Password protection ✓
- Custom URLs ✓
- **Good for:** Small teams (5-10 users)

**Basic ($39/month):**
- Unlimited applications
- 2,000 active hours/month
- 2GB RAM per app
- **Good for:** Medium teams (10-25 users)

**Standard ($99/month):**
- 10,000 active hours/month
- Priority support
- **Good for:** Large teams or production use

### Pros & Cons

**Pros:**
- ✅ Fastest setup (15 minutes)
- ✅ No server maintenance
- ✅ Automatic scaling
- ✅ HTTPS included
- ✅ Built-in authentication
- ✅ Free tier available

**Cons:**
- ❌ Limited customization
- ❌ Can get expensive with heavy usage
- ❌ Subject to platform limits
- ❌ Data stored on RStudio servers

---

## Option 2: Shiny Server + shinymanager Package ⭐ BUDGET-FRIENDLY

### Why Choose This?
- **Low cost:** Can run on $5-10/month server
- **Full control:** Your own server
- **Flexible authentication:** Manage users in code
- **Custom domain:** Use your own URL

### Requirements
- Cloud server (DigitalOcean, AWS, Linode, etc.)
- Basic Linux knowledge
- 30-60 minutes setup time

### Step-by-Step Instructions

#### 1. Set Up Cloud Server

**DigitalOcean Example ($10/month):**
```bash
# Create droplet:
# - Ubuntu 22.04 LTS
# - 2GB RAM / 1 vCPU
# - Choose datacenter close to team
# - Add SSH key for security

# Note your server IP: xxx.xxx.xxx.xxx
```

#### 2. Install R and Shiny Server
```bash
# SSH into your server
ssh root@xxx.xxx.xxx.xxx

# Install R
sudo apt update
sudo apt install -y r-base r-base-dev

# Install Shiny Server
wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.20.1002-amd64.deb
sudo dpkg -i shiny-server-*.deb
sudo apt-get install -f

# Install required R packages
sudo su - -c "R -e \"install.packages(c('shiny', 'rstan', 'shinymanager', 'tidyverse', 'bayesplot', 'DT', 'gridExtra', 'MASS', 'digest'), repos='http://cran.rstudio.com/')\""
```

#### 3. Add Authentication with shinymanager

Create `app_authenticated.R` (example provided in repository):
```r
library(shiny)
library(shinymanager)

# Source your app components
source("global_local.R")
ui_original <- source("ui_local.R")$value
server_original <- source("server_local.R")$value

# Create credentials
credentials <- data.frame(
  user = c("admin", "analyst1", "analyst2"),
  password = c("secure_pass1", "secure_pass2", "secure_pass3"),
  admin = c(TRUE, FALSE, FALSE),
  stringsAsFactors = FALSE
)

# Wrap UI with authentication
ui <- secure_app(
  ui_original,
  choose_language = TRUE,
  fab_position = "bottom-right"
)

# Wrap server with authentication check
server <- function(input, output, session) {
  # Call authentication module
  res_auth <- secure_server(
    check_credentials = check_credentials(credentials)
  )
  
  # Original server logic (wrapped in observe)
  observe({
    server_original(input, output, session)
  })
}

# Run app
shinyApp(ui, server, options = list(host = "0.0.0.0", port = 3838))
```

#### 4. Deploy App Files
```bash
# On your server
sudo mkdir -p /srv/shiny-server/bayesian-pos
cd /srv/shiny-server/bayesian-pos

# Upload your files (from local machine)
scp app_authenticated.R global_local.R server_local.R ui_local.R stan_universal_model.stan root@xxx.xxx.xxx.xxx:/srv/shiny-server/bayesian-pos/

# Set permissions
sudo chown -R shiny:shiny /srv/shiny-server/bayesian-pos
```

#### 5. Configure Firewall
```bash
# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3838/tcp
sudo ufw enable
```

#### 6. Access Your App
```
http://xxx.xxx.xxx.xxx:3838/bayesian-pos/

Users will see login screen:
- Username: admin / analyst1 / analyst2
- Password: (as configured)
```

#### 7. (Optional) Add Custom Domain & HTTPS

**A. Point Domain to Server:**
```
In your domain registrar (GoDaddy, Namecheap, etc.):
Add A record: app.yourdomain.com → xxx.xxx.xxx.xxx
```

**B. Install SSL with Let's Encrypt:**
```bash
sudo apt install -y nginx certbot python3-certbot-nginx

# Configure nginx as reverse proxy
sudo nano /etc/nginx/sites-available/shiny

# Add configuration (example in repository)

sudo certbot --nginx -d app.yourdomain.com
```

Now access at: `https://app.yourdomain.com`

### Cost Breakdown
- **Server:** $5-20/month (DigitalOcean/Linode)
- **Domain:** $10-15/year (optional)
- **SSL:** Free (Let's Encrypt)
- **Total:** ~$5-20/month

### Pros & Cons

**Pros:**
- ✅ Very affordable ($5-20/mo)
- ✅ Full control over authentication
- ✅ Custom domains
- ✅ No data sharing with third parties
- ✅ Can customize everything

**Cons:**
- ❌ Requires server management
- ❌ You handle security updates
- ❌ No automatic scaling
- ❌ Need basic Linux knowledge

---

## Option 3: Shiny Server Pro ($10,000+/year)

### Why Choose This?
- **Enterprise features:** LDAP, PAM, proxy authentication
- **Performance:** Load balancing, SSL, admin dashboard
- **Support:** Professional support from RStudio
- **Compliance:** Meets corporate security requirements

### Features
- User/group management
- Multiple R versions
- Performance tuning
- Monitoring and metrics
- Priority support

### Not Detailed Here
This is an enterprise solution. Contact RStudio for pricing and setup.

**Website:** https://www.rstudio.com/products/shiny-server-pro/

---

## Option 4: RStudio Connect ($15,000+/year)

### Why Choose This?
- **All-in-one platform:** R Markdown, Plumber APIs, Python, etc.
- **Advanced auth:** LDAP, SAML, OAuth, Proxied Auth
- **Scheduling:** Automated reports
- **Email integration:** Automated distribution
- **Full audit trails:** Compliance ready

### Not Detailed Here
This is an enterprise solution. Contact RStudio for pricing and setup.

**Website:** https://www.rstudio.com/products/connect/

---

## Security Best Practices

Regardless of which option you choose:

### 1. Strong Passwords
```r
# Use strong, unique passwords
# Minimum 12 characters
# Mix of letters, numbers, symbols
# Example: "BayesPos@2024!Secure99"
```

### 2. HTTPS Always
```r
# Encrypt data in transit
# Use SSL/TLS certificates
# Free with Let's Encrypt or included in shinyapps.io
```

### 3. Regular Updates
```bash
# Update R packages monthly
update.packages(ask = FALSE)

# Update system packages (Linux)
sudo apt update && sudo apt upgrade
```

### 4. User Management
```r
# Remove inactive users
# Use unique credentials per person
# Never share passwords
# Rotate passwords quarterly
```

### 5. Audit Logs
```r
# Track who accessed the app when
# Review logs regularly
# Set up alerts for suspicious activity
```

### 6. Data Privacy
```r
# Don't store sensitive data in app
# Use environment variables for secrets
# Comply with data protection regulations
```

---

## Troubleshooting

### Problem: App won't deploy
**Solution:** Check that all files are included in `appFiles` parameter

### Problem: Authentication not working
**Solution:** Verify credentials are correct, check package versions

### Problem: Slow performance
**Solution:** Reduce MCMC iterations, add caching, upgrade server

### Problem: Users can't access
**Solution:** Check firewall rules, verify URL, check authentication setup

### Problem: Out of memory
**Solution:** Reduce concurrent users, add swap space, upgrade RAM

---

## Quick Decision Tree

```
Do you need it quickly (< 1 day)?
├─ YES → Use shinyapps.io (Option 1)
└─ NO → Continue

Is budget under $50/month?
├─ YES → Use Shiny Server + shinymanager (Option 2)
└─ NO → Continue

Need enterprise features (LDAP, SAML)?
├─ YES → Use Shiny Server Pro or Connect (Options 3/4)
└─ NO → Use Option 1 or 2
```

---

## Next Steps

### For shinyapps.io (Recommended):
1. ✅ Read Option 1 section above
2. ✅ Create account at shinyapps.io
3. ✅ Run deployment code
4. ✅ Add team members
5. ✅ Share URL!

### For Custom Server:
1. ✅ Read Option 2 section above
2. ✅ Set up cloud server
3. ✅ Install dependencies
4. ✅ Configure authentication
5. ✅ Deploy and test

---

## Support Resources

**shinyapps.io:**
- Documentation: https://docs.rstudio.com/shinyapps.io/
- Support: support@rstudio.com
- Community: https://community.rstudio.com/

**Shiny Server:**
- Admin Guide: https://docs.rstudio.com/shiny-server/
- GitHub: https://github.com/rstudio/shiny-server

**shinymanager Package:**
- Documentation: https://github.com/datastorm-open/shinymanager
- Examples: See `app_authenticated.R` in this repository

---

## Summary

**Fastest Option:** shinyapps.io (15 minutes setup)
**Cheapest Option:** Shiny Server + shinymanager ($5-10/month)
**Most Powerful:** RStudio Connect (enterprise)
**Best Balance:** shinyapps.io Starter plan ($9/month)

Choose based on your team size, budget, and technical comfort level. For most users, **start with shinyapps.io** and upgrade if needed!
