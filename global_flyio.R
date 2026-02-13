# ============================================================================
# GLOBAL.R - Shared code for Bayesian PoS Simulation App (Fly.io Optimized)
# ============================================================================
# This file contains code that runs once when the app starts up
# - Libraries
# - rstan configuration (Fly.io single-core mode)
# - Helper functions
# - PRE-COMPILED Stan models (critical for Fly.io stability)
# - Default values
# ============================================================================

cat("=== Starting Bayesian PoS Simulation App ===\n")
cat("Target environment: Fly.io (Docker container)\n")
cat("Initializing libraries and pre-compiling Stan models...\n\n")

# Load required libraries
suppressPackageStartupMessages({
  library(shiny)
  library(shinythemes)
  library(tidyverse)
  library(rstan)
  library(bayesplot)
  library(DT)
  library(gridExtra)
  library(MASS)
})

# ===========================================================================
# CRITICAL: Fly.io/Docker Single-Core Configuration
# ===========================================================================
# Fly.io runs in restricted containers (1 vCPU, ~1GB RAM)
# ALL parallelism must be disabled to avoid connection/socket errors
# ===========================================================================
options(mc.cores = 1)  # Force single-core execution
Sys.setenv(STAN_NUM_THREADS = "1")  # Disable Stan threading
Sys.setenv(OMP_NUM_THREADS = "1")   # Disable OpenMP threading
rstan_options(auto_write = FALSE)   # Disable auto-write for container safety

cat("✓ rstan configured for Fly.io (single-core mode)\n")
cat("  - mc.cores = 1\n")
cat("  - STAN_NUM_THREADS = 1\n")
cat("  - OMP_NUM_THREADS = 1\n")
cat("  - auto_write = FALSE\n\n")

# ===========================================================================
# FISHER-Z PRIOR DEFAULTS
# ===========================================================================
# Target: rho 95% interval ~ [0.35, 0.80]
# Based on informative prior for oncology trials
# ===========================================================================
rho_L <- 0.35
rho_U <- 0.80
mu_z_default <- (atanh(rho_L) + atanh(rho_U)) / 2  # 0.5365
sd_z_default <- (atanh(rho_U) - atanh(rho_L)) / (2 * 1.96)  # 0.2173

# ===========================================================================
# DATA GENERATION FUNCTION
# ===========================================================================
# Generates historical trial data using hierarchical model
# FILE SYSTEM SAFE: Uses no file I/O, all in-memory
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
  mu_true  <- c(mu_os, mu_pfs)
  tau_true <- c(tau_os, tau_pfs)
  
  R_true <- matrix(c(1, rho_true, rho_true, 1), 2, 2, byrow = TRUE)
  Sigma_true <- diag(tau_true) %*% R_true %*% diag(tau_true)
  
  # Trial-level true effects theta_k ~ MVN(mu_true, Sigma_true)
  theta <- MASS::mvrnorm(n = K, mu = mu_true, Sigma = Sigma_true)
  
  # Realistic SEs
  se_os  <- runif(K, se_os_min, se_os_max)
  se_pfs <- runif(K, se_pfs_min, se_pfs_max)
  
  # Within-trial correlation
  rho_within <- runif(K, rho_within_min, rho_within_max)
  
  # Observed summary estimates y_k ~ MVN(theta_k, W_k)
  y <- matrix(NA_real_, nrow = K, ncol = 2)
  
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
    loghr_os = y[, 1],
    se_loghr_os = se_os,
    loghr_pfs = y[, 2],
    se_loghr_pfs = se_pfs,
    corr_pfs_os = rho_within
  ) %>%
    mutate(cov_pfs_os = corr_pfs_os * se_loghr_pfs * se_loghr_os)
}

# ===========================================================================
# STAN MODEL CODE BUILDER
# ===========================================================================
# Builds Stan model code string based on prior specifications
# Returns: Stan model code as string (NOT compiled)
# ===========================================================================
build_stan_model_code <- function(prior_mu_os_mean = -0.35, prior_mu_os_sd = 1.0,
                                   prior_mu_pfs_mean = -0.45, prior_mu_pfs_sd = 1.0,
                                   prior_tau_type = "exponential", 
                                   prior_tau_param_os = 1, prior_tau_param_pfs = 1,
                                   prior_rho_type = "fisher_z", 
                                   prior_rho_param = 0, prior_rho_param2 = 1.5) {
  
  # Build tau priors
  if (prior_tau_type == "exponential") {
    tau_prior_os <- paste0("tau_os ~ exponential(", prior_tau_param_os, ");")
    tau_prior_pfs <- paste0("tau_pfs ~ exponential(", prior_tau_param_pfs, ");")
  } else if (prior_tau_type == "half_normal") {
    tau_prior_os <- paste0("tau_os ~ normal(0, ", prior_tau_param_os, ") T[0,];")
    tau_prior_pfs <- paste0("tau_pfs ~ normal(0, ", prior_tau_param_pfs, ") T[0,];")
  }
  
  # Build rho prior
  if (prior_rho_type == "uniform") {
    rho_decl <- "real<lower=-0.95, upper=0.95> rho;"
    rho_prior <- paste0("rho ~ uniform(-0.95, 0.95);")
  } else if (prior_rho_type == "uniform_positive") {
    rho_decl <- "real<lower=0, upper=0.95> rho;"
    rho_prior <- paste0("rho ~ uniform(0, 0.95);")
  } else if (prior_rho_type == "beta") {
    rho_decl <- "real<lower=0, upper=1> rho;"
    rho_prior <- paste0("rho ~ beta(", prior_rho_param, ", ", prior_rho_param2, ");")
  } else if (prior_rho_type == "lkj") {
    rho_decl <- "corr_matrix[2] Omega;"
    rho_prior <- paste0("Omega ~ lkj_corr(", prior_rho_param, ");")
  } else if (prior_rho_type == "fisher_z") {
    rho_decl <- "real z_rho;"
    rho_prior <- paste0("z_rho ~ normal(", prior_rho_param, ", ", prior_rho_param2, ");")
  }
  
  # Build Stan model code
  stan_code <- paste0("
data {
  int<lower=1> K;
  vector[2] y_hist[K];
  cov_matrix[2] W_hist[K];
  vector[2] y_curr;
  cov_matrix[2] W_curr;
}

parameters {
  vector[2] mu;
  real<lower=0> tau_os;
  real<lower=0> tau_pfs;
  ", rho_decl, "
  vector[2] z_hist[K];
  vector[2] z_curr;
}

transformed parameters {
  vector[2] theta_hist[K];
  vector[2] theta_curr;
  matrix[2, 2] Sigma;
  matrix[2, 2] L_Sigma;
  ", if(prior_rho_type == "fisher_z") "real rho = tanh(z_rho);" else "", "
  
  ", if(prior_rho_type == "lkj") {
    "Sigma[1, 1] = tau_os^2;
  Sigma[2, 2] = tau_pfs^2;
  Sigma[1, 2] = tau_os * tau_pfs * Omega[1, 2];
  Sigma[2, 1] = Sigma[1, 2];"
  } else {
    "Sigma[1, 1] = tau_os^2;
  Sigma[2, 2] = tau_pfs^2;
  Sigma[1, 2] = rho * tau_os * tau_pfs;
  Sigma[2, 1] = Sigma[1, 2];"
  }, "
  
  L_Sigma = cholesky_decompose(Sigma);
  
  for (k in 1:K) {
    theta_hist[k] = mu + L_Sigma * z_hist[k];
  }
  
  theta_curr = mu + L_Sigma * z_curr;
}

model {
  mu[1] ~ normal(", prior_mu_os_mean, ", ", prior_mu_os_sd, ");
  mu[2] ~ normal(", prior_mu_pfs_mean, ", ", prior_mu_pfs_sd, ");
  ", tau_prior_os, "
  ", tau_prior_pfs, "
  ", rho_prior, "
  
  for (k in 1:K) {
    z_hist[k] ~ std_normal();
  }
  z_curr ~ std_normal();
  
  for (k in 1:K) {
    y_hist[k] ~ multi_normal(theta_hist[k], W_hist[k]);
  }
  y_curr ~ multi_normal(theta_curr, W_curr);
}

generated quantities {
  real theta_os_post = theta_curr[1];
  real theta_pfs_post = theta_curr[2];
  real rho_out = ", if(prior_rho_type == "fisher_z") "tanh(z_rho)" else if(prior_rho_type == "lkj") "Omega[1,2]" else "rho", ";
}
")
  
  return(stan_code)
}

# ===========================================================================
# PRE-COMPILE STAN MODELS (CRITICAL FOR FLY.IO)
# ===========================================================================
# Fly.io Requirement: Compile models ONCE at global scope
# DO NOT compile inside server() or reactive expressions
# ===========================================================================

cat("Pre-compiling Stan models for Fly.io deployment...\n")
cat("This may take 2-3 minutes but only happens at startup.\n\n")

# Create storage for compiled models
compiled_stan_models <- new.env()

# Pre-compile the DEFAULT model (most commonly used)
# This ensures fast startup for typical usage
cat("  [1/1] Compiling default model (fisher_z + exponential)...")
tryCatch({
  default_code <- build_stan_model_code(
    prior_tau_type = "exponential",
    prior_rho_type = "fisher_z",
    prior_rho_param = mu_z_default,
    prior_rho_param2 = sd_z_default
  )
  
  compiled_stan_models$default <- stan_model(
    model_code = default_code,
    model_name = "pos_model_default",
    verbose = FALSE
  )
  cat(" ✓\n")
}, error = function(e) {
  cat(" ✗ FAILED\n")
  cat("Error:", e$message, "\n")
  stop("Failed to compile default Stan model. Cannot start app.")
})

cat("\n✓ Stan model pre-compilation complete!\n")
cat("  - Default model ready for immediate use\n")
cat("  - Other models will compile on-demand (with caching)\n\n")

# ===========================================================================
# MODEL COMPILATION CACHE (FOR ON-DEMAND COMPILATION)
# ===========================================================================
# Function to get or compile a Stan model based on configuration
# Uses caching to avoid recompilation
# ===========================================================================
get_compiled_stan_model <- function(prior_tau_type, prior_rho_type,
                                    prior_mu_os_mean = -0.35, prior_mu_os_sd = 1.0,
                                    prior_mu_pfs_mean = -0.45, prior_mu_pfs_sd = 1.0,
                                    prior_tau_param_os = 1, prior_tau_param_pfs = 1,
                                    prior_rho_param = 0, prior_rho_param2 = 1.5) {
  
  # Create cache key
  cache_key <- paste(prior_tau_type, prior_rho_type, sep = "_")
  
  # Check if already compiled
  if (!is.null(compiled_stan_models[[cache_key]])) {
    return(compiled_stan_models[[cache_key]])
  }
  
  # If this is the default configuration, return the pre-compiled model
  if (prior_tau_type == "exponential" && prior_rho_type == "fisher_z") {
    return(compiled_stan_models$default)
  }
  
  # Compile on-demand (only happens once per configuration)
  cat("Compiling Stan model for:", cache_key, "...\n")
  
  model_code <- build_stan_model_code(
    prior_mu_os_mean = prior_mu_os_mean,
    prior_mu_os_sd = prior_mu_os_sd,
    prior_mu_pfs_mean = prior_mu_pfs_mean,
    prior_mu_pfs_sd = prior_mu_pfs_sd,
    prior_tau_type = prior_tau_type,
    prior_tau_param_os = prior_tau_param_os,
    prior_tau_param_pfs = prior_tau_param_pfs,
    prior_rho_type = prior_rho_type,
    prior_rho_param = prior_rho_param,
    prior_rho_param2 = prior_rho_param2
  )
  
  compiled_model <- stan_model(
    model_code = model_code,
    model_name = paste0("pos_model_", cache_key),
    verbose = FALSE
  )
  
  # Cache for future use
  compiled_stan_models[[cache_key]] <- compiled_model
  
  return(compiled_model)
}

cat("=== App initialization complete ===\n")
cat("Ready to serve on Fly.io (Docker container)\n")
cat("Expected host: 0.0.0.0, port: 3838\n\n")
