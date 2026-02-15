# ============================================================================
# APP_LOCAL.R - Main Application File for Local RStudio Server
# ============================================================================
# This file combines all components for the local server version
# Optimized for team access on your laptop via RStudio Server
# 
# Key Features:
# - Compiles Stan model ONCE at startup (not on every prior change)
# - Prior changes passed as data (no recompilation needed)
# - Shows real-time sampling progress to users
# - Multi-user support on local network
# 
# To run:
#   shiny::runApp("app_local.R", host = "0.0.0.0", port = 3838)
# 
# For team access via RStudio Server:
#   1. Install RStudio Server on your laptop
#   2. Share URL: http://YOUR_LAPTOP_IP:8787
#   3. Team members log in and run this file
# 
# See LOCAL_SERVER_GUIDE.md for complete setup instructions
# ============================================================================

cat("\n")
cat(strrep("=", 70), "\n")
cat("  BAYESIAN PoS SIMULATION - LOCAL SERVER VERSION\n")
cat(strrep("=", 70), "\n")
cat("\n")

# ===========================================================================
# STEP 1: LOAD GLOBAL CONFIGURATION AND COMPILE STAN MODEL
# ===========================================================================
# This happens ONCE when the app starts
# The compiled model is shared across all user sessions
# ===========================================================================

cat("Loading global configuration...\n")
source("global_local.R")

# After sourcing global_local.R, you should see:
# - Stan model compilation messages
# - "✓ Universal Stan model compiled successfully!"
# - This means the model is ready for all users

# ===========================================================================
# STEP 2: LOAD UI AND SERVER
# ===========================================================================

cat("Loading UI and server components...\n")
ui <- source("ui_local.R")$value
server <- source("server_local.R")$value

cat("\n")
cat("All components loaded successfully!\n")
cat("\n")

# ===========================================================================
# STEP 3: CREATE AND RUN SHINY APP
# ===========================================================================

cat(strrep("=", 70), "\n")
cat("Starting Shiny application...\n")
cat("\n")
cat("FOR LOCAL ACCESS:\n")
cat("  URL: http://localhost:3838\n")
cat("\n")
cat("FOR TEAM ACCESS (share this with your team):\n")
cat("  1. Find your laptop's IP address:\n")
cat("     - Windows: ipconfig\n")
cat("     - Mac/Linux: ifconfig or ip addr show\n")
cat("  2. Share: http://YOUR_LAPTOP_IP:3838\n")
cat("  3. Team members access via browser\n")
cat("\n")
cat("IMPORTANT: Run with host='0.0.0.0' for network access:\n")
cat("  shiny::runApp('app_local.R', host='0.0.0.0', port=3838)\n")
cat("\n")
cat(strrep("=", 70), "\n")
cat("\n")

# Run the application
shinyApp(ui = ui, server = server)
