# app_authenticated.R
# Bayesian PoS Simulation with shinymanager Authentication
# 
# This version adds username/password protection using the shinymanager package
# Perfect for deploying on your own server with controlled team access
#
# NOTE: When running as part of POSsimulation package, all dependencies are
# already loaded via NAMESPACE. Library calls are removed to prevent conflicts.
#
# Requirements:
# - shinymanager package must be installed
# - Listed in DESCRIPTION file Imports

# =============================================================================
# AUTHENTICATION SETUP
# =============================================================================

# Method 1: Hard-coded credentials (simple, for small teams)
# WARNING: In production, use Method 2 or Method 3 instead

credentials <- data.frame(
  user = c("admin", "analyst1", "analyst2", "viewer1"),
  password = c(
    "Change_This_Password_123!",  # Admin password
    "Analyst_Pass_456!",           # Analyst 1 password
    "Analyst_Pass_789!",           # Analyst 2 password
    "Viewer_Pass_012!"             # Viewer password
  ),
  admin = c(TRUE, FALSE, FALSE, FALSE),  # Admin rights
  stringsAsFactors = FALSE
)

# Method 2: Load from secure file (recommended for production)
# Uncomment to use:
# credentials <- readRDS("credentials.rds")  # Created separately, not in git
# 
# To create credentials.rds:
# credentials <- data.frame(...)
# saveRDS(credentials, "credentials.rds")
# # Add credentials.rds to .gitignore!

# Method 3: Load from environment variables (most secure)
# Uncomment to use:
# credentials <- data.frame(
#   user = c(Sys.getenv("APP_USER1"), Sys.getenv("APP_USER2")),
#   password = c(Sys.getenv("APP_PASS1"), Sys.getenv("APP_PASS2")),
#   admin = c(TRUE, FALSE),
#   stringsAsFactors = FALSE
# )

# =============================================================================
# LOAD APP COMPONENTS
# =============================================================================

cat("Loading Bayesian PoS Simulation components...\n")

# Load global configuration and Stan model compilation
source("global_local.R")

cat("✓ Global configuration loaded\n")

# Load UI and server
ui_original <- source("ui_local.R")$value
server_original <- source("server_local.R")$value

cat("✓ UI and server loaded\n")

# =============================================================================
# WRAP WITH AUTHENTICATION
# =============================================================================

# Secure the UI with login page
ui <- secure_app(
  ui_original,
  
  # Customization options:
  theme = "flatly",                     # Bootstrap theme
  language = "en",                      # Language: "en", "fr", "es", etc.
  choose_language = FALSE,              # Allow language selection
  
  # Login page customization:
  tags_top = tags$div(
    tags$h3("Bayesian PoS Simulation", style = "text-align:center;"),
    tags$p("Team Access - Please log in", style = "text-align:center; color:#777;")
  ),
  
  # Footer
  tags_bottom = tags$div(
    tags$p(
      "Contact your administrator for access credentials.",
      style = "text-align:center; color:#777; font-size:12px;"
    )
  ),
  
  # Fab button (floating action button for logout)
  fab_position = "bottom-right"
)

# Secure the server with authentication check
server <- function(input, output, session) {
  
  # Check credentials
  res_auth <- secure_server(
    check_credentials = check_credentials(credentials)
  )
  
  # Get user info (available after login)
  output$user_info <- renderText({
    paste("Logged in as:", res_auth$user, 
          if(res_auth$admin) "(Admin)" else "(User)")
  })
  
  # Call original server logic
  # The observe() wrapper ensures it runs after authentication
  observe({
    server_original(input, output, session)
  })
}

# =============================================================================
# RUN APPLICATION
# =============================================================================

cat("\n=== Starting Authenticated Bayesian PoS Simulation ===\n")
cat("Authentication: ENABLED (shinymanager)\n")
cat("Users configured:", nrow(credentials), "\n")
cat("\nDefault credentials (CHANGE THESE!):\n")
cat("  admin / Change_This_Password_123!\n")
cat("  analyst1 / Analyst_Pass_456!\n")
cat("\nReady to accept connections...\n\n")

shinyApp(ui = ui, server = server)
