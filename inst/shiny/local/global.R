# ============================================================================
# GLOBAL_LOCAL.R - Configuration for Local RStudio Server Deployment
# ============================================================================
# This version is optimized for:
# - Local RStudio Server on your laptop
# - Team access via network (username/password)
# - Single Stan model compilation (faster for multiple users)
# - Progress display during MCMC sampling
# ============================================================================
#
# NOTE: When running as part of POSsimulation package, all dependencies are
# already loaded via NAMESPACE. Library calls are removed to prevent conflicts.
# ============================================================================

cat("=== Bayesian PoS Simulation - Local Server Version ===\n")
cat("Starting up...\n\n")

# ===========================================================================
# LOCAL SERVER CONFIGURATION
# ===========================================================================
# Optimized for local RStudio Server with team access
# ===========================================================================

# Detect available cores for local server
total_cores <- parallel::detectCores()
# Use most cores but leave some for system
mc_cores <- max(1, total_cores - 1)

cat(sprintf("Local server detected: %d cores available\n", total_cores))
cat(sprintf("Using %d cores for Stan sampling\n", mc_cores))

# Set rstan options for local server
options(mc.cores = mc_cores)
Sys.setenv(STAN_NUM_THREADS = as.character(mc_cores))
Sys.setenv(OMP_NUM_THREADS = as.character(mc_cores))
rstan::rstan_options(auto_write = FALSE)  # Better for shared server

# ===========================================================================
# UNIVERSAL STAN MODEL - COMPILE ONCE AT STARTUP
# ===========================================================================
# This is the KEY optimization for local server:
# - Compile the universal model ONCE when server starts
# - All users share this compiled model
# - Prior changes passed as DATA (no recompilation needed!)
# - Eliminates 1-2 minute wait per user
# ===========================================================================

cat("\n")
cat("=== Compiling Universal Stan Model ===\n")
cat("This happens ONCE at server startup...\n")
cat("All users will share this compiled model.\n")
cat("Prior changes will NOT require recompilation.\n\n")

UNIVERSAL_STAN_MODEL <- NULL

# Check if stan file exists
stan_file_path <- "stan_universal_model_optimized.stan"

if (file.exists(stan_file_path)) {
  cat("Found Stan model file:", stan_file_path, "\n")
  cat("Compiling (this may take 1-2 minutes)...\n")
  
  compile_start <- Sys.time()
  
  tryCatch({
    UNIVERSAL_STAN_MODEL <- stan_model(
      file = stan_file_path,
      model_name = "bayesian_pos_universal",
      verbose = FALSE
    )
    
    compile_end <- Sys.time()
    compile_time <- as.numeric(difftime(compile_end, compile_start, units = "secs"))
    
    cat("\n")
    cat("✓ Universal Stan model compiled successfully!\n")
    cat(sprintf("  Compilation time: %.1f seconds\n", compile_time))
    cat("  This model will be reused for all sessions.\n")
    cat("  Prior changes will be passed as data (no recompilation).\n")
    
  }, error = function(e) {
    cat("\n")
    cat("✗ ERROR: Failed to compile Stan model!\n")
    cat("Error message:", e$message, "\n")
    cat("\nThe app will not function without the compiled model.\n")
    cat("Please check the stan_universal_model_optimized.stan file and try again.\n")
    stop("Stan model compilation failed")
  })
  
} else {
  cat("✗ ERROR: Stan model file not found:", stan_file_path, "\n")
  cat("Please ensure stan_universal_model_optimized.stan is in the working directory.\n")
  stop("Stan model file not found")
}

# ===========================================================================
# FISHER-Z PRIOR DEFAULTS
# ===========================================================================
# Default informative prior for oncology trials
# Target: rho 95% interval ~ [0.35, 0.80]
# ===========================================================================
rho_L <- 0.35
rho_U <- 0.80
mu_z_default <- (atanh(rho_L) + atanh(rho_U)) / 2  # 0.5365
sd_z_default <- (atanh(rho_U) - atanh(rho_L)) / (2 * 1.96)  # 0.2173

cat("\nDefault Fisher-z prior configured:\n")
cat(sprintf("  μ_z = %.4f, σ_z = %.4f\n", mu_z_default, sd_z_default))
cat(sprintf("  → ρ 95%% interval ≈ [%.2f, %.2f]\n", rho_L, rho_U))

# ===========================================================================
# DATA GENERATION FUNCTION
# ===========================================================================
# Generates historical trial data using hierarchical model
# Accepts parameters for customization
# ===========================================================================
prepare_historical_loghr_data <- function(seed = 20260212,
                                          mu_os = -0.30, mu_pfs = -0.45,
                                          tau_os = 0.15, tau_pfs = 0.15,
                                          rho_true = 0.65,
                                          se_os_min = 0.10, se_os_max = 0.13,
                                          se_pfs_min = 0.08, se_pfs_max = 0.11,
                                          rho_within_min = 0.55, rho_within_max = 0.75) {
  set.seed(seed)
  
  K <- 27  # Number of historical trials
  
  # True population parameters (logHR scale)
  mu_true  <- c(mu_os, mu_pfs)   # (OS, PFS)
  tau_true <- c(tau_os, tau_pfs)     # between-trial SDs
  
  R_true <- matrix(c(1, rho_true, rho_true, 1), 2, 2, byrow = TRUE)
  Sigma_true <- diag(tau_true) %*% R_true %*% diag(tau_true)
  
  # Trial-level true effects theta_k ~ MVN(mu_true, Sigma_true)
  theta <- MASS::mvrnorm(n = K, mu = mu_true, Sigma = Sigma_true)  # K x 2
  
  # Realistic SEs
  se_os  <- runif(K, se_os_min, se_os_max)
  se_pfs <- runif(K, se_pfs_min, se_pfs_max)
  
  # Within-trial correlation of estimated logHRs
  rho_within <- runif(K, rho_within_min, rho_within_max)
  
  # Observed summary estimates y_k ~ MVN(theta_k, W_k)
  y <- matrix(NA_real_, nrow = K, ncol = 2)  # columns: OS, PFS
  
  for (k in 1:K) {
    cov_k <- rho_within[k] * se_os[k] * se_pfs[k]
    W_k <- matrix(c(se_os[k]^2, cov_k,
                    cov_k,      se_pfs[k]^2),
                  2, 2, byrow = TRUE)
    y[k, ] <- MASS::mvrnorm(n = 1, mu = theta[k, ], Sigma = W_k)
  }
  
  # Return as tibble
  tibble(
    trial_id = paste0("ICB-HIST-", sprintf("%02d", 1:K)),
    cancer_type = rep(c("Melanoma", "NSCLC", "Renal", "HCC", "Bladder", "Gastric"), length.out = K),
    n_patients = sample(95:200, K, replace = TRUE),
    loghr_os = y[, 1],    # Observed OS logHR
    se_loghr_os = se_os,
    loghr_pfs = y[, 2],   # Observed PFS logHR
    se_loghr_pfs = se_pfs,
    corr_pfs_os = rho_within
  ) %>%
    mutate(cov_pfs_os = corr_pfs_os * se_loghr_pfs * se_loghr_os)
}

# ===========================================================================
# HELPER FUNCTION: Prepare Stan Data
# ===========================================================================
# Converts prior specifications and trial data into Stan data list
# This allows priors to be changed without recompilation!
# ===========================================================================
prepare_stan_data <- function(historical_data, current_trial_data, prior_specs, target_os = 0, target_pfs = 0) {
  K <- nrow(historical_data)
  
  # Historical trials
  y_hist <- lapply(1:K, function(i) {
    c(historical_data$loghr_os[i], historical_data$loghr_pfs[i])
  })
  
  W_hist <- lapply(1:K, function(i) {
    cov_val <- historical_data$cov_pfs_os[i]
    matrix(c(historical_data$se_loghr_os[i]^2, cov_val,
             cov_val, historical_data$se_loghr_pfs[i]^2), 2, 2)
  })
  
  # Current trial
  y_curr <- c(current_trial_data$loghr_os, current_trial_data$loghr_pfs)
  W_curr <- matrix(c(current_trial_data$se_loghr_os^2, 0,
                     0, current_trial_data$se_loghr_pfs^2), 2, 2)
  
  # Build complete data list
  stan_data <- list(
    K = K,
    y_hist = y_hist,
    W_hist = W_hist,
    y_curr = y_curr,
    W_curr = W_curr,
    
    # TARGET THRESHOLDS for PoS calculation
    target_os = target_os,
    target_pfs = target_pfs,
    
    # Prior parameters for mu
    prior_mu_os_mean = prior_specs$mu_os_mean,
    prior_mu_os_sd = prior_specs$mu_os_sd,
    prior_mu_pfs_mean = prior_specs$mu_pfs_mean,
    prior_mu_pfs_sd = prior_specs$mu_pfs_sd,
    
    # Prior parameters for tau
    prior_tau_type = prior_specs$tau_type,  # 1=exp, 2=half_normal, 3=uniform
    prior_tau_param_os = prior_specs$tau_param_os,
    prior_tau_param_pfs = prior_specs$tau_param_pfs,
    prior_tau_param2_os = prior_specs$tau_param2_os,
    prior_tau_param2_pfs = prior_specs$tau_param2_pfs,
    
    # Prior parameters for rho
    prior_rho_type = prior_specs$rho_type,  # 1=fisher_z, 2=uniform, 3=uniform_pos, 4=beta, 5=lkj
    prior_rho_param = prior_specs$rho_param,
    prior_rho_param2 = prior_specs$rho_param2,
    prior_rho_lower = prior_specs$rho_lower,
    prior_rho_upper = prior_specs$rho_upper
  )
  
  return(stan_data)
}

# ===========================================================================
# STARTUP COMPLETE
# ===========================================================================
cat("\n")
cat("=== Initialization Complete ===\n")
cat("Server is ready for team access.\n")
cat(sprintf("Share RStudio Server URL with your team.\n"))
cat("They can log in with their credentials and run the app.\n")
cat("\n")
cat("Note: The Stan model is already compiled.\n")
cat("Users can change priors without waiting for recompilation!\n")
cat(strrep("=", 70), "\n\n")
