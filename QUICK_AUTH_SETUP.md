# Quick Authentication Setup Guide

## 🚀 Fastest Way to Get Online with Authentication (15 minutes)

### Option A: shinyapps.io (RECOMMENDED - Easiest)

**Time:** 15 minutes | **Cost:** Free tier available | **Difficulty:** ⭐ Easy

#### Steps:

1. **Create Account**
   ```
   Go to: https://www.shinyapps.io/
   Sign up (free)
   ```

2. **Install & Configure rsconnect**
   ```r
   install.packages("rsconnect")
   library(rsconnect)
   
   # Get token from shinyapps.io: Account → Tokens → Show
   rsconnect::setAccountInfo(
     name = "your-username",
     token = "your-token",
     secret = "your-secret"
   )
   ```

3. **Deploy**
   ```r
   # Navigate to your project directory
   setwd("/path/to/POS-simulation")
   
   # Deploy the local server version (faster startup)
   rsconnect::deployApp(
     appFiles = c(
       "app_local.R",
       "global_local.R",
       "server_local.R", 
       "ui_local.R",
       "stan_universal_model.stan"
     ),
     appName = "bayesian-pos"
   )
   ```

4. **Add Users**
   ```
   1. Go to: https://www.shinyapps.io/admin/
   2. Click your app → Users tab
   3. Click "Add User"
   4. Enter team member emails
   5. They'll get invitation emails
   ```

5. **Share URL**
   ```
   Your app: https://your-username.shinyapps.io/bayesian-pos/
   ```

**Done! ✅** Your team can now access with their credentials.

---

### Option B: DIY Server with Authentication (Budget-Friendly)

**Time:** 1-2 hours | **Cost:** $5-10/month | **Difficulty:** ⭐⭐ Medium

#### Steps:

1. **Get a Server**
   ```
   DigitalOcean Droplet: $10/month
   - Ubuntu 22.04
   - 2GB RAM / 1 vCPU
   ```

2. **Install Dependencies**
   ```bash
   ssh root@YOUR_SERVER_IP
   
   # Install R and Shiny Server
   sudo apt update
   sudo apt install -y r-base
   
   # Install Shiny Server
   wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.20.1002-amd64.deb
   sudo dpkg -i shiny-server-*.deb
   
   # Install R packages
   sudo su - -c "R -e \"install.packages(c('shiny', 'shinymanager', 'rstan', 'tidyverse', 'bayesplot', 'DT', 'gridExtra', 'MASS', 'digest'), repos='http://cran.rstudio.com/')\""
   ```

3. **Upload App Files**
   ```bash
   # From your local machine
   scp app_authenticated.R global_local.R server_local.R ui_local.R stan_universal_model.stan root@YOUR_SERVER_IP:/srv/shiny-server/bayesian-pos/
   ```

4. **Configure Firewall**
   ```bash
   sudo ufw allow 3838/tcp
   sudo ufw enable
   ```

5. **Edit Credentials**
   ```r
   # On server, edit app_authenticated.R
   # Change the passwords in the credentials section
   ```

6. **Access App**
   ```
   http://YOUR_SERVER_IP:3838/bayesian-pos/
   
   Default login (CHANGE THIS!):
   - admin / Change_This_Password_123!
   ```

**Done! ✅** Your team can access with usernames/passwords you set.

---

## Comparison

| Feature | shinyapps.io | DIY Server |
|---------|--------------|------------|
| Setup Time | 15 min | 1-2 hours |
| Cost | Free-$99/mo | $5-20/mo |
| Difficulty | Easy ⭐ | Medium ⭐⭐ |
| Maintenance | None | Monthly updates |
| Custom Domain | Paid plans | Yes (free) |
| Control | Limited | Full |

---

## Which Should I Choose?

**Choose shinyapps.io if:**
- ✅ You want it running TODAY
- ✅ You don't want to manage servers
- ✅ Small team (< 10 people)
- ✅ Don't need custom domain

**Choose DIY Server if:**
- ✅ You have time to set up (1-2 hours)
- ✅ Want to save money long-term
- ✅ Need full control
- ✅ Want custom domain
- ✅ Comfortable with basic Linux

---

## Need Help?

**For shinyapps.io:**
- Full guide: See `ONLINE_DEPLOYMENT_AUTH.md` → Option 1
- Support: https://docs.rstudio.com/shinyapps.io/

**For DIY Server:**
- Full guide: See `ONLINE_DEPLOYMENT_AUTH.md` → Option 2
- Authentication example: See `app_authenticated.R`

---

## Next Steps After Deployment

1. **Test the app** yourself first
2. **Change default passwords** (if using DIY)
3. **Add your team members**
4. **Share the URL** with instructions
5. **Monitor usage** and adjust as needed

---

## Security Reminders

- 🔒 Use **strong passwords** (12+ characters, mix of types)
- 🔒 Enable **HTTPS** (included in shinyapps.io, add to DIY)
- 🔒 **Change default passwords** immediately
- 🔒 Remove users when they leave team
- 🔒 **Update packages** regularly

---

**You're ready to deploy! Choose your option above and follow the steps.** 🚀
